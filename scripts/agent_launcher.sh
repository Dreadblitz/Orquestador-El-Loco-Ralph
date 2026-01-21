#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# RALPH ORCHESTRATOR - Agent Launcher
# Lanza agentes de Claude Code con prompts específicos
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

#───────────────────────────────────────────────────────────────────────────────
# FUNCIONES PRINCIPALES
#───────────────────────────────────────────────────────────────────────────────

launch_agent() {
    local agent_type=$1      # explorer, planner, coder, reviewer, etc.
    local agent_prompt=$2    # Path al archivo .md con el prompt
    local spec_path=$3       # Path al spec del proyecto
    local output_file=$4     # Archivo donde guardar output
    local extra_context=$5   # Contexto adicional (opcional)

    log_debug "Lanzando agente: $agent_type"
    log_debug "Prompt: $agent_prompt"
    log_debug "Output: $output_file"

    # Verificar que el prompt existe
    if [[ ! -f "$agent_prompt" ]]; then
        log_error "Prompt no encontrado: $agent_prompt"
        return 1
    fi

    # Leer el prompt
    local prompt_content=$(cat "$agent_prompt")

    # Construir el prompt completo
    local full_prompt="
## Contexto del Proyecto
Spec path: ${spec_path}

## Tu Tarea
${prompt_content}

## Contexto Adicional
${extra_context:-Ninguno}

## Output
Guarda tu output en: ${output_file}
"

    # Ejecutar Claude Code
    log_info "Ejecutando agente ${agent_type}..."

    claude ${CLAUDE_FLAGS} "${full_prompt}" 2>&1

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_info "Agente ${agent_type} completado exitosamente"
    else
        log_error "Agente ${agent_type} falló con código: ${exit_code}"
    fi

    return $exit_code
}

launch_explorer_agent() {
    local explorer_type=$1   # classifier, task, domain, constraints, codebase, stack
    local spec_path=$2
    local project_path=$3

    local agent_prompt="${SCRIPT_DIR}/../agents/explorer_${explorer_type}.md"
    local output_file=""
    local extra_context=""

    ensure_dir "${spec_path}/context"

    # Determinar output file y contexto según tipo de explorer
    case "$explorer_type" in
        classifier)
            output_file="${spec_path}/context/classification.json"
            extra_context="
Proyecto a analizar: ${project_path}
Input del usuario: ${spec_path}/input.md

IMPORTANTE: Este es un análisis RÁPIDO de clasificación.
Solo necesitas determinar el tipo de contexto y tarea.
Output JSON en: ${output_file}
"
            ;;
        task)
            output_file="${spec_path}/context/task_analysis.md"
            extra_context="
Input del usuario: ${spec_path}/input.md
Clasificación: ${spec_path}/context/classification.json

Analiza profundamente la tarea solicitada.
Output en: ${output_file}
"
            ;;
        domain)
            output_file="${spec_path}/context/domain_analysis.md"
            extra_context="
Input del usuario: ${spec_path}/input.md
Proyecto: ${project_path}

Analiza el dominio del problema.
Output en: ${output_file}
"
            ;;
        constraints)
            output_file="${spec_path}/context/constraints.md"
            extra_context="
Input del usuario: ${spec_path}/input.md
Proyecto: ${project_path}
Clasificación: ${spec_path}/context/classification.json

Identifica todas las limitaciones y requisitos no funcionales.
Output en: ${output_file}
"
            ;;
        codebase)
            output_file="${spec_path}/context/codebase_analysis.md"
            extra_context="
Proyecto a analizar: ${project_path}

Analiza la estructura, arquitectura y patrones del código existente.
Output en: ${output_file}
"
            ;;
        stack)
            output_file="${spec_path}/context/stack_analysis.md"
            extra_context="
Proyecto a analizar: ${project_path}

Analiza tecnologías, dependencias y configuraciones.
Output en: ${output_file}
"
            ;;
        *)
            # Fallback para explorers legacy o futuros
            output_file="${spec_path}/context/${explorer_type}.md"
            extra_context="
Proyecto a explorar: ${project_path}
Tipo de exploración: ${explorer_type}
"
            ;;
    esac

    launch_agent "explorer_${explorer_type}" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_planner_agent() {
    local planner_type=$1    # architecture, api, database, frontend, testing, consolidator
    local spec_path=$2

    local agent_prompt="${SCRIPT_DIR}/../agents/planner_${planner_type}.md"
    local output_file="${spec_path}/plan/${planner_type}.md"

    ensure_dir "$(dirname "$output_file")"

    # Incluir contexto de exploración
    local context_files=$(ls "${spec_path}/context/"*.md 2>/dev/null | head -5)
    local extra_context="
Contexto disponible en: ${spec_path}/context/
"

    launch_agent "planner_${planner_type}" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_executor_agent() {
    local task_id=$1
    local spec_path=$2
    local task_spec=$3       # JSON con spec de la tarea
    local task_type=$4       # Tipo de tarea (code, documentation, etc.)
    local feedback=$5        # Feedback de iteración anterior (opcional)

    local agent_prompt="${SCRIPT_DIR}/../agents/executor.md"
    local output_file="${spec_path}/communication/executor_${task_id}_output.json"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Tarea a Ejecutar
Task ID: ${task_id}
Task Type: ${task_type}
Spec: ${task_spec}

## Feedback Previo
${feedback:-Ninguno (primera iteración)}

## Instrucciones Especiales
- Ejecuta SOLO esta tarea
- Adapta tu comportamiento según el tipo: ${task_type}
- Reporta resultado en: ${output_file}
"

    launch_agent "executor" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_validator_agent() {
    local task_id=$1
    local spec_path=$2
    local executor_output=$3  # Output del executor
    local task_type=$4        # Tipo de tarea para criterios de validación

    local agent_prompt="${SCRIPT_DIR}/../agents/validator.md"
    local output_file="${spec_path}/communication/validator_${task_id}_feedback.json"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Resultado a Validar
Task ID: ${task_id}
Task Type: ${task_type}
Executor output: ${executor_output}

## Tu Rol
Validar el resultado según criterios de tipo: ${task_type}
Generar feedback estructurado
Output: ${output_file}
"

    launch_agent "validator" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_final_reviewer() {
    local review_type=$1     # security, tests, architecture
    local spec_path=$2

    local agent_prompt="${SCRIPT_DIR}/../agents/${review_type}_reviewer.md"
    local output_file="${spec_path}/reports/${review_type}_review.json"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Revisión Final: ${review_type}

### Contexto Disponible
- **Input original**: ${spec_path}/input.md
- **Exploración (Fase 2)**: ${spec_path}/context/
  - classification.json (tipo de tarea)
  - task_analysis.md, domain_analysis.md, constraints.md
  - codebase_analysis.md, stack_analysis.md (si aplica)
- **Planificación (Fase 3)**: ${spec_path}/plan/
  - IMPLEMENTATION_PLAN.md (plan consolidado)
  - architecture.md, api_contracts.md, etc. (si existen)
- **Ejecución (Fase 4)**: ${spec_path}/communication/
  - executor_*_output.json (resultados de tareas)
  - validator_*_feedback.json (feedback de validación)
- **PRD**: ${spec_path}/prd.json (estado de waves y tareas)

### Tu Tarea
Revisar TODO el proyecto desde la perspectiva de **${review_type}**.
Consulta los archivos de contexto para entender qué se implementó.

### Output Requerido
Genera reporte JSON estructurado en: ${output_file}

IMPORTANTE: El output DEBE ser un JSON válido con la estructura definida en tu prompt.
NO generar Markdown, solo JSON.
"

    launch_agent "${review_type}_reviewer" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_browser_tester() {
    local spec_path=$1
    local test_cases=$2      # JSON con casos de prueba

    local agent_prompt="${SCRIPT_DIR}/../agents/browser_tester.md"
    local output_file="${spec_path}/reports/browser_tests.md"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Tests E2E con Browser
Usa el skill agent-browser para ejecutar los tests

Test cases: ${test_cases}
Output: ${output_file}
"

    launch_agent "browser_tester" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

#───────────────────────────────────────────────────────────────────────────────
# EJECUCIÓN EN PARALELO
#───────────────────────────────────────────────────────────────────────────────

launch_agents_parallel() {
    local agents=("$@")
    local pids=()
    local max_parallel=${MAX_PARALLEL_AGENTS:-6}
    local running=0

    for agent_cmd in "${agents[@]}"; do
        # Esperar si ya hay demasiados procesos
        while [[ $running -ge $max_parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[$i]'
                    running=$((running - 1))
                fi
            done
            sleep 1
        done

        # Lanzar el agente
        eval "$agent_cmd" &
        pids+=($!)
        running=$((running + 1))

        log_debug "Lanzado proceso $! (running: $running)"
    done

    # Esperar todos los procesos
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    return $failed
}

#───────────────────────────────────────────────────────────────────────────────
# CLI
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    echo "Usage: agent_launcher.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  explorer <type> <spec_path> <project_path>           - Launch explorer agent"
    echo "  planner <type> <spec_path>                           - Launch planner agent"
    echo "  executor <task_id> <spec_path> <task_spec> <type>    - Launch executor agent"
    echo "  validator <task_id> <spec_path> <output> <type>      - Launch validator agent"
    echo "  final <type> <spec_path>                             - Launch final reviewer"
    echo "  browser <spec_path> <test_cases>                     - Launch browser tester"
    echo ""
    echo "Explorer types: classifier, task, domain, constraints, codebase, stack"
    echo "Planner types: architecture, api, database, frontend, testing, consolidator"
    echo "Task types: code, documentation, configuration, research, testing, refactoring, general"
    echo "Final review types: security, tests, architecture"
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        explorer)
            launch_explorer_agent "$2" "$3" "$4"
            ;;
        planner)
            launch_planner_agent "$2" "$3"
            ;;
        executor)
            launch_executor_agent "$2" "$3" "$4" "$5" "$6"
            ;;
        validator)
            launch_validator_agent "$2" "$3" "$4" "$5"
            ;;
        final)
            launch_final_reviewer "$2" "$3"
            ;;
        browser)
            launch_browser_tester "$2" "$3"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
fi
