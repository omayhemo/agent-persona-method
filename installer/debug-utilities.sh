#!/bin/bash

# AP Mapping Debug Utilities
# Enhanced debugging capabilities for troubleshooting installations

# Source logging framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging-framework.sh"

# Debug configuration
DEBUG_MODE="${DEBUG_MODE:-false}"
TRACE_MODE="${TRACE_MODE:-false}"
VERBOSE_MODE="${VERBOSE_MODE:-false}"
DEBUG_OUTPUT_DIR="${DEBUG_OUTPUT_DIR:-./debug}"
TRACE_COMMANDS="${TRACE_COMMANDS:-false}"
TRACE_FUNCTIONS="${TRACE_FUNCTIONS:-false}"
TRACE_VARIABLES="${TRACE_VARIABLES:-false}"

# Stack trace for function calls
declare -a FUNCTION_STACK=()
STACK_DEPTH=0

# Initialize debug utilities
init_debug() {
    local debug_level="${1:-INFO}"
    
    # Set up debug directory
    if [[ "$DEBUG_MODE" == "true" ]] || [[ "$TRACE_MODE" == "true" ]]; then
        mkdir -p "$DEBUG_OUTPUT_DIR"
        
        # Set appropriate log level
        if [[ "$TRACE_MODE" == "true" ]]; then
            set_log_level "TRACE"
            TRACE_COMMANDS="true"
            TRACE_FUNCTIONS="true"
            TRACE_VARIABLES="true"
        elif [[ "$DEBUG_MODE" == "true" ]]; then
            set_log_level "DEBUG"
        fi
        
        log_info "Debug utilities initialized (Mode: ${TRACE_MODE:-DEBUG})" "DEBUG"
    fi
}

# Enable command tracing
enable_command_trace() {
    if [[ "$TRACE_COMMANDS" == "true" ]]; then
        set -x
        export PS4='+ [${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:+${FUNCNAME[0]}()}] '
        
        # Redirect trace output to both console and file
        exec 4>&2
        exec 2> >(tee -a "$DEBUG_OUTPUT_DIR/command-trace.log" >&4)
        
        log_debug "Command tracing enabled" "DEBUG"
    fi
}

# Disable command tracing
disable_command_trace() {
    set +x
    if [[ -n "${4:-}" ]]; then
        exec 2>&4 4>&-
    fi
    log_debug "Command tracing disabled" "DEBUG"
}

# Function entry trace
trace_function_entry() {
    local function_name="${1:-${FUNCNAME[1]}}"
    shift
    local args=("$@")
    
    if [[ "$TRACE_FUNCTIONS" == "true" ]]; then
        FUNCTION_STACK+=("$function_name")
        ((STACK_DEPTH++))
        
        local indent=$(printf '%*s' $((STACK_DEPTH * 2)) '')
        log_trace "${indent}→ Entering: $function_name" "TRACE"
        
        if [[ ${#args[@]} -gt 0 ]]; then
            log_trace "${indent}  Args: ${args[*]}" "TRACE"
        fi
    fi
}

# Function exit trace
trace_function_exit() {
    local function_name="${1:-${FUNCNAME[1]}}"
    local return_code="${2:-$?}"
    
    if [[ "$TRACE_FUNCTIONS" == "true" ]]; then
        local indent=$(printf '%*s' $((STACK_DEPTH * 2)) '')
        log_trace "${indent}← Exiting: $function_name (return: $return_code)" "TRACE"
        
        if [[ ${#FUNCTION_STACK[@]} -gt 0 ]]; then
            unset 'FUNCTION_STACK[-1]'
            ((STACK_DEPTH--))
        fi
    fi
    
    return $return_code
}

# Trace variable changes
trace_variable() {
    local var_name="$1"
    local old_value="$2"
    local new_value="$3"
    local context="${4:-${FUNCNAME[1]}}"
    
    if [[ "$TRACE_VARIABLES" == "true" ]]; then
        if [[ "$old_value" != "$new_value" ]]; then
            log_trace "Variable changed: $var_name" "TRACE"
            log_trace "  Old: '$old_value'" "TRACE"
            log_trace "  New: '$new_value'" "TRACE"
            log_trace "  Context: $context" "TRACE"
        fi
    fi
}

# Debug checkpoint
debug_checkpoint() {
    local checkpoint_name="$1"
    local description="$2"
    
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_debug "Checkpoint: $checkpoint_name - $description" "DEBUG"
        
        # Capture system state
        if [[ "$VERBOSE_MODE" == "true" ]]; then
            capture_system_state "$checkpoint_name"
        fi
    fi
}

# Capture system state for debugging
capture_system_state() {
    local checkpoint="$1"
    local state_file="$DEBUG_OUTPUT_DIR/state-$checkpoint-$(date +%s).txt"
    
    {
        echo "=== System State at $checkpoint ==="
        echo "Date: $(date)"
        echo ""
        
        echo "=== Environment Variables ==="
        env | grep -E '^(AP_|PROJECT_|CLAUDE_|SESSION_|NOTES_)' | sort
        echo ""
        
        echo "=== Process Info ==="
        echo "PID: $$"
        echo "PPID: $PPID"
        echo "User: $(whoami)"
        echo "Working Directory: $(pwd)"
        echo ""
        
        echo "=== Memory Usage ==="
        if command -v free >/dev/null 2>&1; then
            free -h
        elif command -v vm_stat >/dev/null 2>&1; then
            vm_stat
        fi
        echo ""
        
        echo "=== Disk Usage ==="
        df -h .
        echo ""
        
        echo "=== Recent Files ==="
        find . -type f -mmin -5 2>/dev/null | head -20
        echo ""
        
    } > "$state_file"
    
    log_trace "System state captured to: $state_file" "DEBUG"
}

# Debug assertion
assert() {
    local condition="$1"
    local message="$2"
    local fatal="${3:-false}"
    
    if ! eval "$condition"; then
        log_error "Assertion failed: $condition" "ASSERT"
        log_error "Message: $message" "ASSERT"
        
        # Capture stack trace
        print_stack_trace
        
        if [[ "$fatal" == "true" ]]; then
            log_fatal "Fatal assertion failure, exiting" "ASSERT"
            exit 1
        fi
    fi
}

# Print stack trace
print_stack_trace() {
    log_error "Stack trace:" "DEBUG"
    
    local frame=0
    while caller $frame; do
        ((frame++))
    done | while read line func file; do
        log_error "  at $func ($file:$line)" "DEBUG"
    done
}

# Debug break point
debug_break() {
    local message="${1:-Debug break point reached}"
    
    if [[ "$DEBUG_MODE" == "true" ]] && [[ -t 0 ]]; then
        log_warn "$message" "DEBUG"
        log_warn "Press Enter to continue, or type 'skip' to disable breaks..." "DEBUG"
        
        read -r response
        if [[ "$response" == "skip" ]]; then
            DEBUG_MODE="false"
            log_info "Debug breaks disabled" "DEBUG"
        fi
    fi
}

# Watch variable for changes
watch_variable() {
    local var_name="$1"
    local watch_file="$DEBUG_OUTPUT_DIR/watch-$var_name.log"
    
    if [[ "$DEBUG_MODE" == "true" ]]; then
        local current_value="${!var_name:-<unset>}"
        local last_value=""
        
        if [[ -f "$watch_file" ]]; then
            last_value=$(tail -1 "$watch_file" | cut -d'|' -f2)
        fi
        
        if [[ "$current_value" != "$last_value" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S')|$current_value|${FUNCNAME[1]}" >> "$watch_file"
            log_debug "Variable $var_name changed: '$last_value' → '$current_value'" "WATCH"
        fi
    fi
}

# Performance profiling wrapper
profile_function() {
    local function_name="$1"
    shift
    
    if [[ "$PERF_TRACKING" == "true" ]]; then
        local start_time=$(date +%s%N)
        local start_mem=$(get_memory_usage)
        
        # Execute function
        "$function_name" "$@"
        local result=$?
        
        local end_time=$(date +%s%N)
        local end_mem=$(get_memory_usage)
        
        local duration=$((end_time - start_time))
        local duration_ms=$((duration / 1000000))
        local mem_diff=$((end_mem - start_mem))
        
        log_info "Profile: $function_name - Time: ${duration_ms}ms, Memory: ${mem_diff}KB" "PROFILE"
        
        return $result
    else
        # Just execute normally
        "$function_name" "$@"
    fi
}

# Get current memory usage in KB
get_memory_usage() {
    if [[ -f /proc/$$/status ]]; then
        awk '/VmRSS/ {print $2}' /proc/$$/status
    else
        echo "0"
    fi
}

# Dump all variables for debugging
dump_variables() {
    local output_file="${1:-$DEBUG_OUTPUT_DIR/variables-dump-$(date +%s).txt}"
    
    {
        echo "=== Variable Dump ==="
        echo "Date: $(date)"
        echo "Function: ${FUNCNAME[1]}"
        echo ""
        
        # AP Mapping specific variables
        echo "=== AP Mapping Variables ==="
        set | grep -E '^(AP_|PROJECT_|CLAUDE_|SESSION_|NOTES_)' | while IFS='=' read -r name value; do
            # Mask sensitive values
            if [[ "$name" =~ (PASSWORD|TOKEN|SECRET|KEY) ]]; then
                echo "$name=<masked>"
            else
                echo "$name=$value"
            fi
        done
        echo ""
        
        # Installation state
        echo "=== Installation State ==="
        set | grep -E '^(INSTALLATION_|BACKUP_|ROLLBACK_)' 
        echo ""
        
    } > "$output_file"
    
    log_debug "Variables dumped to: $output_file" "DEBUG"
}

# Interactive debug shell
debug_shell() {
    local context="${1:-Debug Shell}"
    
    if [[ "$DEBUG_MODE" == "true" ]] && [[ -t 0 ]]; then
        log_warn "Entering debug shell: $context" "DEBUG"
        log_warn "Type 'exit' to continue execution" "DEBUG"
        
        # Save current environment
        local old_ps1="$PS1"
        export PS1="[DEBUG]> "
        
        # Start subshell
        bash --norc
        
        # Restore environment
        export PS1="$old_ps1"
        
        log_info "Exited debug shell" "DEBUG"
    fi
}

# Generate debug report
generate_debug_report() {
    local report_file="$DEBUG_OUTPUT_DIR/debug-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log_info "Generating debug report..." "DEBUG"
    
    {
        echo "==================================="
        echo "AP Mapping Installation Debug Report"
        echo "==================================="
        echo ""
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo ""
        
        echo "=== Configuration ==="
        echo "DEBUG_MODE: $DEBUG_MODE"
        echo "TRACE_MODE: $TRACE_MODE"
        echo "LOG_LEVEL: $LOG_LEVEL"
        echo ""
        
        echo "=== Installation Summary ==="
        if [[ -f "$LOG_FILE" ]]; then
            echo "Errors:"
            grep -E '\\[ERROR\\]|\\[FATAL\\]' "$LOG_FILE" | tail -20
            echo ""
            echo "Warnings:"
            grep '\\[WARN\\]' "$LOG_FILE" | tail -20
        fi
        echo ""
        
        echo "=== Recent Activity ==="
        if [[ -d "$DEBUG_OUTPUT_DIR" ]]; then
            find "$DEBUG_OUTPUT_DIR" -type f -name "*.log" -mmin -10 -exec basename {} \\; | sort
        fi
        echo ""
        
        echo "=== Recommendations ==="
        analyze_debug_logs
        
    } > "$report_file"
    
    log_info "Debug report generated: $report_file" "DEBUG"
    echo "$report_file"
}

# Analyze debug logs for common issues
analyze_debug_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        # Check for common patterns
        if grep -q "Permission denied" "$LOG_FILE"; then
            echo "- Permission issues detected. Check file/directory permissions."
        fi
        
        if grep -q "No such file or directory" "$LOG_FILE"; then
            echo "- Missing files detected. Verify installation package integrity."
        fi
        
        if grep -q "command not found" "$LOG_FILE"; then
            echo "- Missing dependencies detected. Run prerequisite checks."
        fi
        
        if grep -q "already exists" "$LOG_FILE"; then
            echo "- Existing installation detected. Consider using --force or cleanup."
        fi
    fi
}

# Export debug functions
export -f init_debug enable_command_trace disable_command_trace
export -f trace_function_entry trace_function_exit trace_variable
export -f debug_checkpoint debug_break debug_shell
export -f assert print_stack_trace watch_variable
export -f dump_variables generate_debug_report