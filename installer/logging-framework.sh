#!/bin/bash

# AP Mapping Logging Framework
# Provides structured logging, debug capabilities, and performance tracking

# Logging configuration
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOG_FILE:-}"
LOG_DIR="${LOG_DIR:-./logs}"
LOG_TO_FILE="${LOG_TO_FILE:-true}"
LOG_TO_CONSOLE="${LOG_TO_CONSOLE:-true}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB default
LOG_ROTATION_COUNT="${LOG_ROTATION_COUNT:-5}"
LOG_TIMESTAMP_FORMAT="${LOG_TIMESTAMP_FORMAT:-%Y-%m-%dT%H:%M:%S%z}"
LOG_BUFFER_SIZE="${LOG_BUFFER_SIZE:-100}"
LOG_COMPONENT="${LOG_COMPONENT:-INSTALLER}"

# Performance tracking
declare -A PERF_TIMERS
declare -A PERF_COUNTERS
PERF_TRACKING="${PERF_TRACKING:-false}"

# Log levels
declare -A LOG_LEVELS=(
    ["TRACE"]=0
    ["DEBUG"]=1
    ["INFO"]=2
    ["WARN"]=3
    ["ERROR"]=4
    ["FATAL"]=5
    ["OFF"]=99
)

# Color codes for console output
declare -A LOG_COLORS=(
    ["TRACE"]="\033[0;37m"   # Light gray
    ["DEBUG"]="\033[0;36m"   # Cyan
    ["INFO"]="\033[0;32m"    # Green
    ["WARN"]="\033[1;33m"    # Yellow
    ["ERROR"]="\033[0;31m"   # Red
    ["FATAL"]="\033[1;31m"   # Bold red
)
LOG_COLOR_RESET="\033[0m"

# Log buffer for batch writing
declare -a LOG_BUFFER=()

# Initialize logging system
init_logging() {
    local component="${1:-INSTALLER}"
    local log_file="${2:-}"
    
    LOG_COMPONENT="$component"
    
    # Set up log file if specified
    if [[ -n "$log_file" ]]; then
        LOG_FILE="$log_file"
    elif [[ "$LOG_TO_FILE" == "true" ]] && [[ -z "$LOG_FILE" ]]; then
        # Generate default log file name
        mkdir -p "$LOG_DIR"
        LOG_FILE="$LOG_DIR/ap-installer-$(date +%Y%m%d-%H%M%S).log"
    fi
    
    # Create log directory if needed
    if [[ -n "$LOG_FILE" ]]; then
        local log_dir=$(dirname "$LOG_FILE")
        mkdir -p "$log_dir"
        
        # Initialize log file with header
        {
            echo "==============================================="
            echo "AP Mapping Installer Log"
            echo "Started: $(date)"
            echo "Component: $LOG_COMPONENT"
            echo "Log Level: $LOG_LEVEL"
            echo "==============================================="
            echo ""
        } >> "$LOG_FILE"
    fi
    
    # Set up signal handlers for clean shutdown
    trap 'flush_log_buffer; finalize_logging' EXIT
    trap 'flush_log_buffer; finalize_logging; exit 130' INT TERM
    
    log_info "Logging system initialized" "LOGGING"
}

# Set log level
set_log_level() {
    local level="${1^^}"
    
    if [[ -n "${LOG_LEVELS[$level]}" ]]; then
        LOG_LEVEL="$level"
        log_info "Log level changed to: $level" "LOGGING"
    else
        log_error "Invalid log level: $level" "LOGGING"
        return 1
    fi
}

# Get numeric log level
get_log_level_value() {
    local level="${1^^}"
    echo "${LOG_LEVELS[$level]:-99}"
}

# Check if we should log at given level
should_log() {
    local level="${1^^}"
    local current_value=$(get_log_level_value "$LOG_LEVEL")
    local check_value=$(get_log_level_value "$level")
    
    [[ $check_value -ge $current_value ]]
}

# Format log message
format_log_message() {
    local level="$1"
    local message="$2"
    local component="${3:-$LOG_COMPONENT}"
    local timestamp=$(date "+$LOG_TIMESTAMP_FORMAT")
    
    echo "[$timestamp] [$level] [$component] $message"
}

# Write to log file
write_to_log_file() {
    local formatted_message="$1"
    
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        # Check log rotation
        check_log_rotation
        
        # Buffer or write directly
        if [[ ${#LOG_BUFFER[@]} -ge $LOG_BUFFER_SIZE ]]; then
            flush_log_buffer
        fi
        
        LOG_BUFFER+=("$formatted_message")
    fi
}

# Write to console
write_to_console() {
    local level="$1"
    local message="$2"
    local component="$3"
    local timestamp=$(date "+%H:%M:%S")
    
    if [[ "$LOG_TO_CONSOLE" == "true" ]]; then
        local color="${LOG_COLORS[$level]}"
        local prefix="[$timestamp] "
        
        # Different formatting for different levels
        case "$level" in
            "ERROR"|"FATAL")
                echo -e "${color}${prefix}❌ $message${LOG_COLOR_RESET}" >&2
                ;;
            "WARN")
                echo -e "${color}${prefix}⚠️  $message${LOG_COLOR_RESET}" >&2
                ;;
            "INFO")
                echo -e "${color}${prefix}ℹ️  $message${LOG_COLOR_RESET}"
                ;;
            "DEBUG")
                echo -e "${color}${prefix}🔍 [$component] $message${LOG_COLOR_RESET}"
                ;;
            "TRACE")
                echo -e "${color}${prefix}🔬 [$component] $message${LOG_COLOR_RESET}"
                ;;
        esac
    fi
}

# Flush log buffer
flush_log_buffer() {
    if [[ ${#LOG_BUFFER[@]} -gt 0 ]] && [[ -n "$LOG_FILE" ]]; then
        printf '%s\n' "${LOG_BUFFER[@]}" >> "$LOG_FILE"
        LOG_BUFFER=()
    fi
}

# Core logging function
log_message() {
    local level="$1"
    local message="$2"
    local component="${3:-$LOG_COMPONENT}"
    
    if should_log "$level"; then
        local formatted_message=$(format_log_message "$level" "$message" "$component")
        
        # Write to file
        write_to_log_file "$formatted_message"
        
        # Write to console
        write_to_console "$level" "$message" "$component"
    fi
}

# Convenience logging functions
log_trace() {
    log_message "TRACE" "$1" "${2:-$LOG_COMPONENT}"
}

log_debug() {
    log_message "DEBUG" "$1" "${2:-$LOG_COMPONENT}"
}

log_info() {
    log_message "INFO" "$1" "${2:-$LOG_COMPONENT}"
}

log_warn() {
    log_message "WARN" "$1" "${2:-$LOG_COMPONENT}"
}

log_error() {
    log_message "ERROR" "$1" "${2:-$LOG_COMPONENT}"
}

log_fatal() {
    log_message "FATAL" "$1" "${2:-$LOG_COMPONENT}"
    flush_log_buffer
}

# Log command execution
log_command() {
    local command="$1"
    local component="${2:-$LOG_COMPONENT}"
    
    log_debug "Executing: $command" "$component"
    
    if [[ "$(get_log_level_value "$LOG_LEVEL")" -le "$(get_log_level_value "TRACE")" ]]; then
        # In trace mode, show real-time output
        eval "$command" 2>&1 | while IFS= read -r line; do
            log_trace "  | $line" "$component"
        done
        return ${PIPESTATUS[0]}
    else
        # Normal execution
        eval "$command"
    fi
}

# Log variable state
log_variables() {
    local component="${1:-$LOG_COMPONENT}"
    local vars=("${@:2}")
    
    if should_log "DEBUG"; then
        log_debug "Variable state:" "$component"
        for var in "${vars[@]}"; do
            local value="${!var:-<unset>}"
            # Mask sensitive values
            if [[ "$var" =~ (PASSWORD|TOKEN|SECRET|KEY) ]]; then
                value="<masked>"
            fi
            log_debug "  $var=$value" "$component"
        done
    fi
}

# Check and perform log rotation
check_log_rotation() {
    if [[ -n "$LOG_FILE" ]] && [[ -f "$LOG_FILE" ]]; then
        local file_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        
        if [[ $file_size -gt $LOG_MAX_SIZE ]]; then
            rotate_logs
        fi
    fi
}

# Rotate log files
rotate_logs() {
    if [[ -n "$LOG_FILE" ]]; then
        flush_log_buffer
        
        # Rotate existing logs
        for ((i=$LOG_ROTATION_COUNT-1; i>0; i--)); do
            if [[ -f "$LOG_FILE.$i" ]]; then
                mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
            fi
        done
        
        # Move current log
        if [[ -f "$LOG_FILE" ]]; then
            mv "$LOG_FILE" "$LOG_FILE.1"
            
            # Compress rotated log
            if command -v gzip >/dev/null 2>&1; then
                gzip "$LOG_FILE.1"
            fi
        fi
        
        log_info "Log rotated (size exceeded $LOG_MAX_SIZE bytes)" "LOGGING"
    fi
}

# Performance tracking functions
start_timer() {
    local timer_name="$1"
    
    if [[ "$PERF_TRACKING" == "true" ]]; then
        PERF_TIMERS[$timer_name]=$(date +%s%N)
        log_trace "Timer started: $timer_name" "PERFORMANCE"
    fi
}

stop_timer() {
    local timer_name="$1"
    local component="${2:-$LOG_COMPONENT}"
    
    if [[ "$PERF_TRACKING" == "true" ]] && [[ -n "${PERF_TIMERS[$timer_name]}" ]]; then
        local start_time="${PERF_TIMERS[$timer_name]}"
        local end_time=$(date +%s%N)
        local duration=$((end_time - start_time))
        local duration_ms=$((duration / 1000000))
        
        log_debug "Timer $timer_name: ${duration_ms}ms" "$component"
        unset PERF_TIMERS[$timer_name]
        
        # Track in performance counters
        PERF_COUNTERS["${timer_name}_last"]=$duration_ms
        PERF_COUNTERS["${timer_name}_count"]=$((${PERF_COUNTERS["${timer_name}_count"]:-0} + 1))
        PERF_COUNTERS["${timer_name}_total"]=$((${PERF_COUNTERS["${timer_name}_total"]:-0} + duration_ms))
    fi
}

# Time a function execution
time_function() {
    local timer_name="$1"
    local function_name="$2"
    shift 2
    
    start_timer "$timer_name"
    "$function_name" "$@"
    local result=$?
    stop_timer "$timer_name"
    
    return $result
}

# Increment counter
increment_counter() {
    local counter_name="$1"
    local increment="${2:-1}"
    
    if [[ "$PERF_TRACKING" == "true" ]]; then
        PERF_COUNTERS[$counter_name]=$((${PERF_COUNTERS[$counter_name]:-0} + increment))
        log_trace "Counter $counter_name: ${PERF_COUNTERS[$counter_name]}" "PERFORMANCE"
    fi
}

# Generate performance report
generate_performance_report() {
    if [[ "$PERF_TRACKING" == "true" ]]; then
        log_info "Performance Report:" "PERFORMANCE"
        
        # Report timers
        for timer in "${!PERF_COUNTERS[@]}"; do
            if [[ "$timer" =~ _total$ ]]; then
                local base_name="${timer%_total}"
                local total="${PERF_COUNTERS[$timer]}"
                local count="${PERF_COUNTERS[${base_name}_count]:-1}"
                local avg=$((total / count))
                
                log_info "  $base_name: Total=${total}ms, Count=$count, Avg=${avg}ms" "PERFORMANCE"
            elif [[ ! "$timer" =~ _(count|last)$ ]]; then
                log_info "  $timer: ${PERF_COUNTERS[$timer]}" "PERFORMANCE"
            fi
        done
    fi
}

# Log structured data (JSON-like)
log_structured() {
    local level="$1"
    local event="$2"
    shift 2
    
    local data="event='$event'"
    while [[ $# -gt 0 ]]; do
        data="$data, $1='$2'"
        shift 2
    done
    
    log_message "$level" "{$data}" "$LOG_COMPONENT"
}

# Finalize logging
finalize_logging() {
    flush_log_buffer
    
    if [[ -n "$LOG_FILE" ]]; then
        {
            echo ""
            echo "==============================================="
            echo "Log ended: $(date)"
            echo "==============================================="
        } >> "$LOG_FILE"
    fi
}

# Export functions for use in other scripts
export -f init_logging set_log_level should_log log_trace log_debug log_info log_warn log_error log_fatal
export -f log_command log_variables log_structured
export -f start_timer stop_timer time_function increment_counter generate_performance_report
export -f flush_log_buffer finalize_logging