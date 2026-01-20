#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# RALPH ORCHESTRATOR - Utilidades Comunes
#═══════════════════════════════════════════════════════════════════════════════

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración por defecto
MAX_PARALLEL_AGENTS=${MAX_PARALLEL_AGENTS:-6}
MAX_CODER_ITERATIONS=${MAX_CODER_ITERATIONS:-3}
CLAUDE_FLAGS="--dangerously-skip-permissions --print"

#───────────────────────────────────────────────────────────────────────────────
# LOGGING
#───────────────────────────────────────────────────────────────────────────────

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
    fi
}

log_phase() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

log_wave() {
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  WAVE $1: $2${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
}

#───────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE IDs
#───────────────────────────────────────────────────────────────────────────────

generate_execution_id() {
    date '+%Y%m%d_%H%M%S'
}

generate_task_id() {
    local wave_id=$1
    local task_num=$2
    echo "W${wave_id}T${task_num}"
}

#───────────────────────────────────────────────────────────────────────────────
# MANEJO DE ARCHIVOS
#───────────────────────────────────────────────────────────────────────────────

ensure_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Directorio creado: $dir"
    fi
}

write_json() {
    local file=$1
    local content=$2
    echo "$content" | jq '.' > "$file" 2>/dev/null || echo "$content" > "$file"
}

read_json_field() {
    local file=$1
    local field=$2
    jq -r "$field" "$file" 2>/dev/null
}

update_json_field() {
    local file=$1
    local field=$2
    local value=$3
    local tmp=$(mktemp)
    jq "$field = $value" "$file" > "$tmp" && mv "$tmp" "$file"
}

append_to_file() {
    local file=$1
    local content=$2
    echo "$content" >> "$file"
}

#───────────────────────────────────────────────────────────────────────────────
# MANEJO DE PROCESOS
#───────────────────────────────────────────────────────────────────────────────

wait_for_processes() {
    local pids=("$@")
    local failed=0

    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    return $failed
}

kill_processes() {
    local pids=("$@")
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null
    done
}

#───────────────────────────────────────────────────────────────────────────────
# VALIDACIONES
#───────────────────────────────────────────────────────────────────────────────

check_claude_installed() {
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI no está instalado"
        log_error "Instalar con: npm install -g @anthropic-ai/claude-code"
        return 1
    fi
    return 0
}

check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        log_error "jq no está instalado"
        log_error "Instalar con: sudo apt install jq"
        return 1
    fi
    return 0
}

validate_prd() {
    local prd_file=$1

    if [[ ! -f "$prd_file" ]]; then
        log_error "PRD no encontrado: $prd_file"
        return 1
    fi

    if ! jq '.' "$prd_file" > /dev/null 2>&1; then
        log_error "PRD no es JSON válido: $prd_file"
        return 1
    fi

    return 0
}

#───────────────────────────────────────────────────────────────────────────────
# ESTADO DE EJECUCIÓN
#───────────────────────────────────────────────────────────────────────────────

get_wave_status() {
    local prd_file=$1
    local wave_id=$2
    read_json_field "$prd_file" ".waves[] | select(.id == $wave_id) | .status"
}

set_wave_status() {
    local prd_file=$1
    local wave_id=$2
    local status=$3
    local tmp=$(mktemp)
    jq "(.waves[] | select(.id == $wave_id) | .status) = \"$status\"" "$prd_file" > "$tmp" && mv "$tmp" "$prd_file"
}

get_task_status() {
    local prd_file=$1
    local task_id=$2
    read_json_field "$prd_file" ".waves[].tasks[] | select(.id == \"$task_id\") | .passes"
}

set_task_passed() {
    local prd_file=$1
    local task_id=$2
    local passed=$3
    local tmp=$(mktemp)
    jq "(.waves[].tasks[] | select(.id == \"$task_id\") | .passes) = $passed" "$prd_file" > "$tmp" && mv "$tmp" "$prd_file"
}

check_wave_dependencies() {
    local prd_file=$1
    local wave_id=$2

    local deps=$(read_json_field "$prd_file" ".waves[] | select(.id == $wave_id) | .depends_on // []")

    if [[ "$deps" == "[]" ]] || [[ -z "$deps" ]]; then
        return 0
    fi

    for dep_id in $(echo "$deps" | jq -r '.[]'); do
        local dep_status=$(get_wave_status "$prd_file" "$dep_id")
        if [[ "$dep_status" != "completed" ]]; then
            return 1
        fi
    done

    return 0
}

all_waves_completed() {
    local prd_file=$1
    local pending=$(jq '[.waves[] | select(.status != "completed")] | length' "$prd_file")
    [[ "$pending" == "0" ]]
}

#───────────────────────────────────────────────────────────────────────────────
# PROGRESS TRACKING
#───────────────────────────────────────────────────────────────────────────────

log_progress() {
    local spec_path=$1
    local message=$2
    local progress_file="${spec_path}/progress.txt"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$progress_file"
}

#───────────────────────────────────────────────────────────────────────────────
# TEST DE UTILIDADES
#───────────────────────────────────────────────────────────────────────────────

test_utils() {
    log_info "Testing utils.sh..."

    # Test logging
    log_info "Test log_info"
    log_warn "Test log_warn"
    log_debug "Test log_debug (solo visible si DEBUG=1)"

    # Test ID generation
    local exec_id=$(generate_execution_id)
    log_info "Execution ID: $exec_id"

    local task_id=$(generate_task_id 1 1)
    log_info "Task ID: $task_id"

    # Test checks
    check_jq_installed && log_info "jq: OK"
    check_claude_installed && log_info "claude: OK"

    log_info "Utils test completado"
}

# Exportar funciones para subshells
export -f log_info log_warn log_error log_debug log_phase log_wave
export -f generate_execution_id generate_task_id
export -f ensure_dir write_json read_json_field update_json_field append_to_file
export -f wait_for_processes kill_processes
export -f check_claude_installed check_jq_installed validate_prd
export -f get_wave_status set_wave_status get_task_status set_task_passed
export -f check_wave_dependencies all_waves_completed
export -f log_progress
