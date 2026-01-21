#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# RALPH ORCHESTRATOR - Entry Point Principal
#
# Sistema de orquestación multi-agente para desarrollo autónomo
#
# Uso: ./orchestrator.sh "Descripción de la tarea"
#═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/utils.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN
#───────────────────────────────────────────────────────────────────────────────

TASK_PROMPT=""
EXECUTION_ID=""
SPEC_PATH=""
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"

#───────────────────────────────────────────────────────────────────────────────
# FASE 1: SETUP
#───────────────────────────────────────────────────────────────────────────────

setup_execution() {
    log_phase "FASE 1: SETUP"

    # Generar ID de ejecución
    EXECUTION_ID=$(generate_execution_id)
    SPEC_PATH="${SCRIPT_DIR}/spec/${EXECUTION_ID}"

    log_info "Execution ID: $EXECUTION_ID"
    log_info "Spec Path: $SPEC_PATH"

    # Crear estructura de directorios
    ensure_dir "$SPEC_PATH"
    ensure_dir "${SPEC_PATH}/context"
    ensure_dir "${SPEC_PATH}/plan"
    ensure_dir "${SPEC_PATH}/communication"
    ensure_dir "${SPEC_PATH}/logs"
    ensure_dir "${SPEC_PATH}/reports"

    # Guardar prompt original
    echo "$TASK_PROMPT" > "${SPEC_PATH}/input.md"
    log_info "Prompt guardado en: ${SPEC_PATH}/input.md"

    # Crear metadata
    cat > "${SPEC_PATH}/metadata.json" << EOF
{
  "execution_id": "${EXECUTION_ID}",
  "created_at": "$(date -Iseconds)",
  "status": "started",
  "project_path": "${PROJECT_PATH}",
  "config": {
    "max_parallel_agents": ${MAX_PARALLEL_AGENTS:-6},
    "max_coder_iterations": ${MAX_CODER_ITERATIONS:-3},
    "autonomy": "full",
    "review_perspectives": ["security", "tests", "architecture"]
  }
}
EOF

    log_info "Setup completado"
}

#───────────────────────────────────────────────────────────────────────────────
# FASE 2: EXPLORACIÓN TRANSVERSAL (2 Etapas)
#───────────────────────────────────────────────────────────────────────────────

run_exploration_phase() {
    log_phase "FASE 2: EXPLORACIÓN TRANSVERSAL"

    #───────────────────────────────────────────────────────────────────────────
    # ETAPA 1: Clasificación (secuencial - necesitamos el resultado)
    #───────────────────────────────────────────────────────────────────────────
    log_info "Etapa 1: Clasificación del contexto"
    "${SCRIPT_DIR}/scripts/agent_launcher.sh" explorer "classifier" "$SPEC_PATH" "$PROJECT_PATH"

    # Leer resultado de clasificación
    local has_code="false"
    local classification_file="${SPEC_PATH}/context/classification.json"

    if [[ -f "$classification_file" ]]; then
        has_code=$(jq -r '.has_code // false' "$classification_file" 2>/dev/null || echo "false")
        local context_type=$(jq -r '.context_type // "unknown"' "$classification_file" 2>/dev/null || echo "unknown")
        log_info "Contexto detectado: $context_type (has_code: $has_code)"
    else
        log_warn "No se pudo leer classification.json, asumiendo proyecto con código"
        has_code="true"
    fi

    #───────────────────────────────────────────────────────────────────────────
    # ETAPA 2: Exploración Adaptativa (paralelo)
    #───────────────────────────────────────────────────────────────────────────
    log_info "Etapa 2: Exploración adaptativa"

    local pids=()

    # Explorers que SIEMPRE se ejecutan (transversales)
    local core_explorers=("task" "domain" "constraints")

    for explorer_type in "${core_explorers[@]}"; do
        log_info "Lanzando Explorer: $explorer_type"
        "${SCRIPT_DIR}/scripts/agent_launcher.sh" explorer "$explorer_type" "$SPEC_PATH" "$PROJECT_PATH" &
        pids+=($!)
    done

    # Explorers que solo se ejecutan SI HAY CÓDIGO
    if [[ "$has_code" == "true" ]]; then
        local code_explorers=("codebase" "stack")

        for explorer_type in "${code_explorers[@]}"; do
            log_info "Lanzando Explorer (código): $explorer_type"
            "${SCRIPT_DIR}/scripts/agent_launcher.sh" explorer "$explorer_type" "$SPEC_PATH" "$PROJECT_PATH" &
            pids+=($!)
        done
    else
        log_info "Sin código existente - saltando explorers de codebase/stack"
    fi

    # Esperar todos los explorers
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed explorers fallaron"
    fi

    log_info "Exploración completada"
    log_info "Contexto en: ${SPEC_PATH}/context/"
}

#───────────────────────────────────────────────────────────────────────────────
# FASE 3: PLANIFICACIÓN ADAPTATIVA
#───────────────────────────────────────────────────────────────────────────────

run_planning_phase() {
    log_phase "FASE 3: PLANIFICACIÓN ADAPTATIVA"

    #───────────────────────────────────────────────────────────────────────────
    # Leer classification.json para determinar planners necesarios
    #───────────────────────────────────────────────────────────────────────────
    local classification_file="${SPEC_PATH}/context/classification.json"
    local planners_to_run=()

    if [[ -f "$classification_file" ]]; then
        local task_type=$(jq -r '.task_type // "feature"' "$classification_file" 2>/dev/null || echo "feature")
        log_info "Task type detectado: $task_type"

        # Leer planners requeridos
        local required_planners=$(jq -r '.recommended_planners.required // [] | .[]' "$classification_file" 2>/dev/null)
        for planner in $required_planners; do
            planners_to_run+=("$planner")
            log_info "Planner requerido: $planner"
        done

        # Leer planners condicionales (solo si son true)
        local conditional_planners=("architecture" "api" "database" "frontend" "testing")
        for planner in "${conditional_planners[@]}"; do
            local is_enabled=$(jq -r ".recommended_planners.conditional.${planner} // false" "$classification_file" 2>/dev/null || echo "false")
            if [[ "$is_enabled" == "true" ]] && [[ ! " ${planners_to_run[*]} " =~ " ${planner} " ]]; then
                planners_to_run+=("$planner")
                log_info "Planner condicional habilitado: $planner"
            fi
        done
    else
        # Fallback: si no hay classification.json, ejecutar todos (comportamiento legacy)
        log_warn "No se encontró classification.json, ejecutando todos los planners"
        planners_to_run=("architecture" "api" "database" "frontend" "testing")
    fi

    #───────────────────────────────────────────────────────────────────────────
    # Ejecutar planners seleccionados en paralelo
    #───────────────────────────────────────────────────────────────────────────
    local pids=()

    if [[ ${#planners_to_run[@]} -gt 0 ]]; then
        log_info "Ejecutando ${#planners_to_run[@]} planners en paralelo"

        for planner_type in "${planners_to_run[@]}"; do
            log_info "Lanzando Planner: $planner_type"
            "${SCRIPT_DIR}/scripts/agent_launcher.sh" planner "$planner_type" "$SPEC_PATH" &
            pids+=($!)
        done

        # Esperar todos los planners
        local failed=0
        for pid in "${pids[@]}"; do
            if ! wait "$pid"; then
                failed=$((failed + 1))
            fi
        done

        if [[ $failed -gt 0 ]]; then
            log_warn "$failed planners fallaron"
        fi
    else
        log_info "No hay planners específicos para este tipo de tarea"
    fi

    #───────────────────────────────────────────────────────────────────────────
    # Ejecutar consolidator (SIEMPRE, secuencial)
    #───────────────────────────────────────────────────────────────────────────
    log_info "Lanzando Planner Consolidator..."
    "${SCRIPT_DIR}/scripts/agent_launcher.sh" planner "consolidator" "$SPEC_PATH"

    log_info "Planificación completada"
    log_info "Plan en: ${SPEC_PATH}/plan/"
}

#───────────────────────────────────────────────────────────────────────────────
# FASE 4: GENERACIÓN DE PRD
#───────────────────────────────────────────────────────────────────────────────

generate_prd() {
    log_phase "FASE 4: GENERACIÓN DE PRD"

    # Lanzar agente para generar PRD con waves
    log_info "Generando PRD.json con waves..."

    # Usar Claude Code para generar el PRD basado en el plan
    claude ${CLAUDE_FLAGS:-"--dangerously-skip-permissions --print"} "
## Tu Tarea

Lee el plan de implementación en ${SPEC_PATH}/plan/IMPLEMENTATION_PLAN.md (o los archivos individuales en ${SPEC_PATH}/plan/) y genera un PRD.json estructurado.

## Estructura del PRD

El PRD debe tener la siguiente estructura:

\`\`\`json
{
  \"project\": {
    \"name\": \"[nombre del proyecto]\",
    \"spec_path\": \"${SPEC_PATH}\",
    \"created\": \"$(date -Iseconds)\"
  },
  \"config\": {
    \"max_parallel_agents\": 6,
    \"max_coder_iterations\": 3,
    \"autonomy\": \"full\",
    \"review_perspectives\": [\"security\", \"tests\", \"architecture\"]
  },
  \"waves\": [
    {
      \"id\": 1,
      \"name\": \"Wave name\",
      \"status\": \"pending\",
      \"depends_on\": [],
      \"tasks\": [
        {
          \"id\": \"W1T1\",
          \"title\": \"Task title\",
          \"description\": \"Detailed description\",
          \"type\": \"code\",
          \"file_paths\": [\"expected/files/to/modify.py\"],
          \"verification\": \"command or criteria to verify\",
          \"passes\": false
        }
      ]
    }
  ],
  \"final_review\": {
    \"status\": \"pending\",
    \"perspectives\": {
      \"security\": {\"passed\": false},
      \"tests\": {\"passed\": false},
      \"architecture\": {\"passed\": false}
    }
  }
}
\`\`\`

## Reglas para Waves

1. Agrupa tareas que NO tienen dependencias entre sí en la misma wave
2. Máximo 6 tareas por wave (para paralelismo)
3. Las waves deben ejecutarse en orden de sus IDs
4. depends_on contiene IDs de waves que deben completarse antes

## Task Types (campo type)

Cada tarea DEBE tener un campo 'type' que determina cómo el Executor la procesará.

| Valor | Uso |
|-------|-----|
| code | Implementación de código (models, services, endpoints, components) |
| testing | Creación de tests (unit, integration, E2E) |
| documentation | Documentación (README, API docs, docstrings) |
| configuration | Configuración (.env, .yaml, .json, pyproject.toml) |
| research | Investigación (spikes, análisis, POC) - NO hace commit |
| refactoring | Refactorización (cleanup, optimización) |
| general | Tareas que no encajan en otras categorías |

**Reglas de inferencia si Type no está explícito en el plan:**
- Archivos .py, .ts, .tsx, .js → code
- Archivos en tests/ → testing
- Archivos .md, .txt, .rst → documentation
- Archivos .json, .yaml, .env, .toml → configuration
- Título contiene 'refactor' o 'cleanup' → refactoring
- Título contiene 'research', 'spike', 'investigate' → research

## Output

Guarda el PRD en: ${SPEC_PATH}/prd.json

Responde SOLO con el JSON, sin explicaciones.
"

    # Verificar que se generó el PRD
    if [[ -f "${SPEC_PATH}/prd.json" ]]; then
        log_info "PRD generado: ${SPEC_PATH}/prd.json"

        # Validar JSON
        if jq '.' "${SPEC_PATH}/prd.json" > /dev/null 2>&1; then
            log_info "PRD válido"
        else
            log_error "PRD generado no es JSON válido"
            return 1
        fi
    else
        log_error "PRD no fue generado"
        return 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# FASE 5: EJECUCIÓN (RALPH LOOP)
#───────────────────────────────────────────────────────────────────────────────

run_execution_phase() {
    log_phase "FASE 5: EJECUCIÓN (RALPH LOOP)"

    # Ejecutar ralph.sh con el PRD generado
    "${SCRIPT_DIR}/scripts/ralph.sh" "${SPEC_PATH}/prd.json"
}

#───────────────────────────────────────────────────────────────────────────────
# CLI
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              RALPH ORCHESTRATOR                               ║"
    echo "║   Sistema de orquestación multi-agente para desarrollo        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Uso: ./orchestrator.sh \"<descripción de la tarea>\" [opciones]"
    echo ""
    echo "Argumentos:"
    echo "  <prompt>              Descripción de la tarea a implementar"
    echo ""
    echo "Opciones:"
    echo "  --project-path PATH   Path del proyecto (default: pwd)"
    echo "  --skip-explore        Saltar fase de exploración"
    echo "  --skip-plan           Saltar fase de planificación"
    echo "  --prd FILE            Usar PRD existente (salta explore+plan)"
    echo "  --debug               Habilitar logging de debug"
    echo "  -h, --help            Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./orchestrator.sh \"Implementar sistema de autenticación JWT\""
    echo "  ./orchestrator.sh \"Agregar endpoint CRUD para usuarios\" --project-path /my/project"
    echo "  ./orchestrator.sh --prd spec/existing/prd.json"
    echo ""
    echo "Variables de entorno:"
    echo "  MAX_PARALLEL_AGENTS   Máximo agentes en paralelo (default: 6)"
    echo "  MAX_CODER_ITERATIONS  Máximo intentos por tarea (default: 3)"
    echo "  DEBUG                 Habilitar debug (1/0)"
}

show_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   ██████╗  █████╗ ██╗     ██████╗ ██╗  ██╗                   ║"
    echo "║   ██╔══██╗██╔══██╗██║     ██╔══██╗██║  ██║                   ║"
    echo "║   ██████╔╝███████║██║     ██████╔╝███████║                   ║"
    echo "║   ██╔══██╗██╔══██║██║     ██╔═══╝ ██╔══██║                   ║"
    echo "║   ██║  ██║██║  ██║███████╗██║     ██║  ██║                   ║"
    echo "║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝                   ║"
    echo "║                                                               ║"
    echo "║              ORCHESTRATOR v1.0.0                              ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Main
main() {
    local skip_explore=0
    local skip_plan=0
    local existing_prd=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                PROJECT_PATH=$2
                shift 2
                ;;
            --skip-explore)
                skip_explore=1
                shift
                ;;
            --skip-plan)
                skip_plan=1
                shift
                ;;
            --prd)
                existing_prd=$2
                shift 2
                ;;
            --debug)
                export DEBUG=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$TASK_PROMPT" ]] && [[ ! "$1" =~ ^- ]]; then
                    TASK_PROMPT=$1
                fi
                shift
                ;;
        esac
    done

    # Mostrar banner
    show_banner

    # Verificar dependencias
    check_claude_installed || exit 1
    check_jq_installed || exit 1

    # Modo: usar PRD existente
    if [[ -n "$existing_prd" ]]; then
        log_info "Usando PRD existente: $existing_prd"
        SPEC_PATH=$(dirname "$existing_prd")
        run_execution_phase
        exit $?
    fi

    # Validar prompt
    if [[ -z "$TASK_PROMPT" ]]; then
        log_error "Se requiere descripción de la tarea"
        echo ""
        show_help
        exit 1
    fi

    log_info "Tarea: $TASK_PROMPT"
    log_info "Proyecto: $PROJECT_PATH"

    # Ejecutar fases
    local start_time=$(date +%s)

    setup_execution

    if [[ $skip_explore -eq 0 ]]; then
        run_exploration_phase
    else
        log_info "Fase de exploración saltada"
    fi

    if [[ $skip_plan -eq 0 ]]; then
        run_planning_phase
    else
        log_info "Fase de planificación saltada"
    fi

    generate_prd

    run_execution_phase

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    log_phase "EJECUCIÓN COMPLETADA"
    log_info "Duración total: ${duration}s"
    log_info "Spec path: $SPEC_PATH"
    log_info "Reporte final: ${SPEC_PATH}/reports/FINAL_REPORT.md"
}

# Ejecutar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
