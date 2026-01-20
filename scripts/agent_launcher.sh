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
    local explorer_type=$1   # structure, tech, patterns, tests, deps
    local spec_path=$2
    local project_path=$3

    local agent_prompt="${SCRIPT_DIR}/../agents/explorer_${explorer_type}.md"
    local output_file="${spec_path}/context/${explorer_type}.md"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
Proyecto a explorar: ${project_path}
Tipo de exploración: ${explorer_type}
"

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

launch_coder_agent() {
    local task_id=$1
    local spec_path=$2
    local task_spec=$3       # JSON con spec de la tarea
    local feedback=$4        # Feedback de iteración anterior (opcional)

    local agent_prompt="${SCRIPT_DIR}/../agents/coder.md"
    local output_file="${spec_path}/communication/coder_${task_id}_output.json"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Tarea a Implementar
Task ID: ${task_id}
Spec: ${task_spec}

## Feedback Previo
${feedback:-Ninguno (primera iteración)}

## Instrucciones Especiales
- Implementa SOLO esta tarea
- Haz commit atómico
- Reporta resultado en: ${output_file}
"

    launch_agent "coder" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_reviewer_agent() {
    local task_id=$1
    local spec_path=$2
    local coder_output=$3    # Output del coder

    local agent_prompt="${SCRIPT_DIR}/../agents/reviewer.md"
    local output_file="${spec_path}/communication/reviewer_${task_id}_feedback.json"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Código a Revisar
Task ID: ${task_id}
Coder output: ${coder_output}

## Tu Rol
Revisar el código y generar feedback estructurado
Output: ${output_file}
"

    launch_agent "reviewer" "$agent_prompt" "$spec_path" "$output_file" "$extra_context"
}

launch_final_reviewer() {
    local review_type=$1     # security, tests, architecture
    local spec_path=$2

    local agent_prompt="${SCRIPT_DIR}/../agents/${review_type}_reviewer.md"
    local output_file="${spec_path}/reports/${review_type}_review.md"

    ensure_dir "$(dirname "$output_file")"

    local extra_context="
## Revisión Final: ${review_type}
Revisar todo el proyecto desde la perspectiva de ${review_type}
Output: ${output_file}
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
    echo "  explorer <type> <spec_path> <project_path>  - Launch explorer agent"
    echo "  planner <type> <spec_path>                  - Launch planner agent"
    echo "  coder <task_id> <spec_path> <task_spec>     - Launch coder agent"
    echo "  reviewer <task_id> <spec_path> <output>     - Launch reviewer agent"
    echo "  final <type> <spec_path>                    - Launch final reviewer"
    echo "  browser <spec_path> <test_cases>            - Launch browser tester"
    echo ""
    echo "Explorer types: structure, tech, patterns, tests, deps"
    echo "Planner types: architecture, api, database, frontend, testing, consolidator"
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
        coder)
            launch_coder_agent "$2" "$3" "$4" "$5"
            ;;
        reviewer)
            launch_reviewer_agent "$2" "$3" "$4"
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
