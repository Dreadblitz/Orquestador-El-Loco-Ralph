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
# FASE 2: EXPLORACIÓN
#───────────────────────────────────────────────────────────────────────────────

run_exploration_phase() {
    log_phase "FASE 2: EXPLORACIÓN"

    local pids=()

    # Lanzar explorers en paralelo
    local explorer_types=("structure" "tech" "patterns" "tests" "deps")

    for explorer_type in "${explorer_types[@]}"; do
        log_info "Lanzando Explorer: $explorer_type"
        "${SCRIPT_DIR}/scripts/agent_launcher.sh" explorer "$explorer_type" "$SPEC_PATH" "$PROJECT_PATH" &
        pids+=($!)
    done

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
# FASE 3: PLANIFICACIÓN
#───────────────────────────────────────────────────────────────────────────────

run_planning_phase() {
    log_phase "FASE 3: PLANIFICACIÓN"

    local pids=()

    # Lanzar planners en paralelo (excepto consolidator)
    local planner_types=("architecture" "api" "database" "frontend" "testing")

    for planner_type in "${planner_types[@]}"; do
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

    # Ejecutar consolidator (secuencial, necesita output de otros)
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
