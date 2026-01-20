#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# RALPH LOOP - Orquestador Principal de Ejecución
#
# IMPORTANTE: Este script NO escribe código.
# Su rol es COORDINAR agentes Coder y Reviewer.
#═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN
#───────────────────────────────────────────────────────────────────────────────

PRD_FILE=""
SPEC_PATH=""
MAX_ITERATIONS=${MAX_ITERATIONS:-100}
MAX_CODER_RETRIES=${MAX_CODER_RETRIES:-3}

#───────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE WAVE
#───────────────────────────────────────────────────────────────────────────────

execute_wave() {
    local wave_id=$1
    local wave_name=$2

    log_wave "$wave_id" "$wave_name"

    # Verificar dependencias
    if ! check_wave_dependencies "$PRD_FILE" "$wave_id"; then
        log_warn "Wave $wave_id tiene dependencias no completadas, saltando..."
        return 1
    fi

    # Obtener tareas de la wave
    local tasks=$(jq -r ".waves[] | select(.id == $wave_id) | .tasks[]" "$PRD_FILE" 2>/dev/null)

    if [[ -z "$tasks" ]]; then
        log_warn "Wave $wave_id no tiene tareas"
        set_wave_status "$PRD_FILE" "$wave_id" "completed"
        return 0
    fi

    # Marcar wave como in_progress
    set_wave_status "$PRD_FILE" "$wave_id" "in_progress"

    # Arrays para procesos paralelos
    local pids=()
    local task_ids=()
    local running=0

    # Lanzar Coders en paralelo (hasta MAX_PARALLEL_AGENTS)
    for task_id in $tasks; do
        # Verificar si ya está completada
        local task_passed=$(get_task_status "$PRD_FILE" "$task_id")
        if [[ "$task_passed" == "true" ]]; then
            log_info "Task $task_id ya completada, saltando..."
            continue
        fi

        # Esperar si hay demasiados procesos
        while [[ $running -ge $MAX_PARALLEL_AGENTS ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[$i]'
                    running=$((running - 1))
                fi
            done
            sleep 2
        done

        # Lanzar Coder para esta tarea
        log_info "Lanzando Coder para task: $task_id"
        execute_task "$task_id" &
        pids+=($!)
        task_ids+=("$task_id")
        running=$((running + 1))
    done

    # Esperar todos los procesos
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    # Verificar si todas las tareas de la wave están completadas
    local pending=$(jq "[.waves[] | select(.id == $wave_id) | .tasks[] as \$t | .waves[].tasks[] | select(.id == \$t and .passes == false)] | length" "$PRD_FILE" 2>/dev/null || echo "0")

    if [[ "$pending" == "0" ]] || [[ -z "$pending" ]]; then
        set_wave_status "$PRD_FILE" "$wave_id" "completed"
        log_info "Wave $wave_id completada exitosamente"
        return 0
    else
        log_warn "Wave $wave_id tiene $pending tareas pendientes"
        return 1
    fi
}

execute_task() {
    local task_id=$1
    local iteration=0

    log_info "Ejecutando task: $task_id"

    # Obtener spec de la tarea
    local task_spec=$(jq -r ".waves[].tasks[] | select(.id == \"$task_id\")" "$PRD_FILE")
    local task_title=$(echo "$task_spec" | jq -r '.title // .description // "Unknown"')

    log_progress "$SPEC_PATH" "Iniciando task $task_id: $task_title"

    while [[ $iteration -lt $MAX_CODER_RETRIES ]]; do
        iteration=$((iteration + 1))
        log_info "Task $task_id - Iteración $iteration/$MAX_CODER_RETRIES"

        # Obtener feedback previo si existe
        local feedback=""
        local feedback_file="${SPEC_PATH}/communication/reviewer_${task_id}_feedback.json"
        if [[ -f "$feedback_file" ]]; then
            feedback=$(cat "$feedback_file")
        fi

        #───────────────────────────────────────────────────────────────────────
        # LANZAR CODER AGENT
        #───────────────────────────────────────────────────────────────────────
        log_info "Lanzando Coder Agent para $task_id..."

        "${SCRIPT_DIR}/agent_launcher.sh" coder "$task_id" "$SPEC_PATH" "$task_spec" "$feedback"
        local coder_exit=$?

        if [[ $coder_exit -ne 0 ]]; then
            log_error "Coder falló para task $task_id"
            log_progress "$SPEC_PATH" "Task $task_id: Coder falló (iter $iteration)"
            continue
        fi

        #───────────────────────────────────────────────────────────────────────
        # LANZAR REVIEWER AGENT
        #───────────────────────────────────────────────────────────────────────
        local coder_output="${SPEC_PATH}/communication/coder_${task_id}_output.json"

        log_info "Lanzando Reviewer Agent para $task_id..."

        "${SCRIPT_DIR}/agent_launcher.sh" reviewer "$task_id" "$SPEC_PATH" "$coder_output"
        local reviewer_exit=$?

        if [[ $reviewer_exit -ne 0 ]]; then
            log_error "Reviewer falló para task $task_id"
            continue
        fi

        #───────────────────────────────────────────────────────────────────────
        # EVALUAR FEEDBACK
        #───────────────────────────────────────────────────────────────────────
        local feedback_file="${SPEC_PATH}/communication/reviewer_${task_id}_feedback.json"

        if [[ -f "$feedback_file" ]]; then
            local approved=$(jq -r '.approved // false' "$feedback_file" 2>/dev/null || echo "false")

            if [[ "$approved" == "true" ]]; then
                log_info "Task $task_id APROBADA por Reviewer"
                set_task_passed "$PRD_FILE" "$task_id" true
                log_progress "$SPEC_PATH" "Task $task_id: COMPLETADA (iter $iteration)"
                return 0
            else
                log_warn "Task $task_id requiere correcciones"
                local issues=$(jq -r '.issues | length' "$feedback_file" 2>/dev/null || echo "0")
                log_warn "Issues encontrados: $issues"
            fi
        else
            # Sin feedback = asumimos aprobado
            log_info "Task $task_id completada (sin feedback explícito)"
            set_task_passed "$PRD_FILE" "$task_id" true
            log_progress "$SPEC_PATH" "Task $task_id: COMPLETADA (iter $iteration)"
            return 0
        fi
    done

    log_error "Task $task_id falló después de $MAX_CODER_RETRIES intentos"
    log_progress "$SPEC_PATH" "Task $task_id: FALLIDA después de $MAX_CODER_RETRIES intentos"
    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# REVISIÓN FINAL
#───────────────────────────────────────────────────────────────────────────────

execute_final_review() {
    log_phase "REVISIÓN FINAL"

    local pids=()

    # Lanzar los 3 revisores finales en paralelo
    log_info "Lanzando Security Reviewer..."
    "${SCRIPT_DIR}/agent_launcher.sh" final security "$SPEC_PATH" &
    pids+=($!)

    log_info "Lanzando Tests Reviewer..."
    "${SCRIPT_DIR}/agent_launcher.sh" final tests "$SPEC_PATH" &
    pids+=($!)

    log_info "Lanzando Architecture Reviewer..."
    "${SCRIPT_DIR}/agent_launcher.sh" final architecture "$SPEC_PATH" &
    pids+=($!)

    # Esperar todos
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed revisores finales fallaron"
    fi

    # Generar reporte consolidado
    generate_final_report

    return $failed
}

generate_final_report() {
    local report_file="${SPEC_PATH}/reports/FINAL_REPORT.md"

    cat > "$report_file" << EOF
# Reporte Final - Ralph Orchestrator

## Resumen de Ejecución

| Campo | Valor |
|-------|-------|
| Fecha | $(date '+%Y-%m-%d %H:%M:%S') |
| PRD | ${PRD_FILE} |
| Spec Path | ${SPEC_PATH} |

## Waves Ejecutadas

$(jq -r '.waves[] | "| Wave \(.id) | \(.name) | \(.status) |"' "$PRD_FILE")

## Revisiones Finales

### Seguridad
$(cat "${SPEC_PATH}/reports/security_review.md" 2>/dev/null || echo "No disponible")

### Tests
$(cat "${SPEC_PATH}/reports/tests_review.md" 2>/dev/null || echo "No disponible")

### Arquitectura
$(cat "${SPEC_PATH}/reports/architecture_review.md" 2>/dev/null || echo "No disponible")

## Log de Progreso

\`\`\`
$(cat "${SPEC_PATH}/progress.txt" 2>/dev/null || echo "No disponible")
\`\`\`

---
Generado por Ralph Orchestrator
EOF

    log_info "Reporte final generado: $report_file"
}

#───────────────────────────────────────────────────────────────────────────────
# LOOP PRINCIPAL
#───────────────────────────────────────────────────────────────────────────────

run_ralph_loop() {
    log_phase "RALPH LOOP INICIADO"

    local start_time=$(date +%s)
    local iteration=0

    # Obtener lista de waves ordenadas
    local waves=$(jq -r '.waves | sort_by(.id) | .[].id' "$PRD_FILE")

    while [[ $iteration -lt $MAX_ITERATIONS ]]; do
        iteration=$((iteration + 1))

        log_info "═══ Iteración $iteration/$MAX_ITERATIONS ═══"

        # Verificar si todas las waves están completadas
        if all_waves_completed "$PRD_FILE"; then
            log_info "Todas las waves completadas"
            break
        fi

        # Ejecutar waves pendientes
        for wave_id in $waves; do
            local wave_status=$(get_wave_status "$PRD_FILE" "$wave_id")

            if [[ "$wave_status" == "completed" ]]; then
                continue
            fi

            local wave_name=$(jq -r ".waves[] | select(.id == $wave_id) | .name" "$PRD_FILE")

            execute_wave "$wave_id" "$wave_name"
        done

        # Pequeña pausa entre iteraciones
        sleep 2
    done

    # Ejecutar revisión final
    execute_final_review

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_phase "RALPH LOOP COMPLETADO"
    log_info "Duración total: ${duration}s"
    log_info "Iteraciones: $iteration"

    # Verificar estado final
    if all_waves_completed "$PRD_FILE"; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║                    RALPH COMPLETE                             ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        return 0
    else
        log_warn "Algunas waves no se completaron"
        return 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CLI
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    echo "Usage: ralph.sh <prd_file> [options]"
    echo ""
    echo "Arguments:"
    echo "  prd_file              Path to PRD.json file"
    echo ""
    echo "Options:"
    echo "  --max-iterations N    Maximum iterations (default: 100)"
    echo "  --max-retries N       Max coder retries per task (default: 3)"
    echo "  --debug               Enable debug logging"
    echo "  -h, --help            Show this help"
    echo ""
    echo "Environment variables:"
    echo "  MAX_PARALLEL_AGENTS   Max parallel agents (default: 6)"
    echo "  DEBUG                 Enable debug mode (1/0)"
}

# Main
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-iterations)
                MAX_ITERATIONS=$2
                shift 2
                ;;
            --max-retries)
                MAX_CODER_RETRIES=$2
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
                if [[ -z "$PRD_FILE" ]]; then
                    PRD_FILE=$1
                fi
                shift
                ;;
        esac
    done

    # Validar argumentos
    if [[ -z "$PRD_FILE" ]]; then
        log_error "PRD file requerido"
        show_help
        exit 1
    fi

    # Validar PRD
    if ! validate_prd "$PRD_FILE"; then
        exit 1
    fi

    # Obtener spec path del PRD
    SPEC_PATH=$(jq -r '.project.spec_path // ""' "$PRD_FILE")
    if [[ -z "$SPEC_PATH" ]] || [[ "$SPEC_PATH" == "null" ]]; then
        SPEC_PATH=$(dirname "$PRD_FILE")
    fi

    # Verificar dependencias
    check_claude_installed || exit 1
    check_jq_installed || exit 1

    # Crear directorios necesarios
    ensure_dir "${SPEC_PATH}/communication"
    ensure_dir "${SPEC_PATH}/logs"
    ensure_dir "${SPEC_PATH}/reports"

    # Inicializar log de progreso
    log_progress "$SPEC_PATH" "Ralph Loop iniciado"
    log_progress "$SPEC_PATH" "PRD: $PRD_FILE"
    log_progress "$SPEC_PATH" "Max iterations: $MAX_ITERATIONS"
    log_progress "$SPEC_PATH" "Max parallel agents: $MAX_PARALLEL_AGENTS"

    # Ejecutar loop
    run_ralph_loop
}

# Ejecutar si es el script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
