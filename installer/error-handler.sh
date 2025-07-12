#!/bin/bash

# AP Mapping Error Handler Framework
# Comprehensive error classification, handling, and recovery system

# Error handler version
ERROR_HANDLER_VERSION="1.0.0"

# Initialize error handler
init_error_handler() {
    # Error tracking
    declare -gA ERROR_HISTORY
    declare -gA ERROR_COUNTS
    declare -gA ERROR_CONTEXT
    
    # Recovery strategies
    declare -gA RECOVERY_STRATEGIES
    declare -gA ERROR_SOLUTIONS
    
    # Error categories
    readonly ERROR_CATEGORIES=(
        "SYSTEM"        # System-level errors (permissions, resources)
        "CONFIG"        # Configuration errors (invalid JSON, missing vars)
        "INSTALL"       # Installation errors (conflicts, missing files)
        "NETWORK"       # Network errors (downloads, connectivity)
        "DEPENDENCY"    # Dependency errors (missing commands, versions)
        "USER"          # User errors (invalid input, cancelled)
        "INTERNAL"      # Internal errors (bugs, unexpected states)
    )
    
    # Error codes mapping
    declare -gA ERROR_CODES=(
        # System errors (1000-1999)
        ["PERMISSION_DENIED"]=1001
        ["DISK_FULL"]=1002
        ["OUT_OF_MEMORY"]=1003
        ["RESOURCE_BUSY"]=1004
        
        # Config errors (2000-2999)
        ["INVALID_JSON"]=2001
        ["MISSING_REQUIRED_VAR"]=2002
        ["INVALID_PATH"]=2003
        ["CONFIG_NOT_FOUND"]=2004
        
        # Install errors (3000-3999)
        ["FILE_EXISTS"]=3001
        ["FILE_NOT_FOUND"]=3002
        ["CHECKSUM_MISMATCH"]=3003
        ["INSTALL_INCOMPLETE"]=3004
        
        # Network errors (4000-4999)
        ["CONNECTION_FAILED"]=4001
        ["DOWNLOAD_FAILED"]=4002
        ["TIMEOUT"]=4003
        ["DNS_FAILURE"]=4004
        
        # Dependency errors (5000-5999)
        ["COMMAND_NOT_FOUND"]=5001
        ["VERSION_MISMATCH"]=5002
        ["LIBRARY_MISSING"]=5003
        ["PYTHON_MODULE_MISSING"]=5004
        
        # User errors (6000-6999)
        ["INVALID_INPUT"]=6001
        ["USER_CANCELLED"]=6002
        ["CONFIRMATION_FAILED"]=6003
        
        # Internal errors (9000-9999)
        ["UNKNOWN_ERROR"]=9001
        ["ASSERTION_FAILED"]=9002
        ["STATE_CORRUPTED"]=9003
    )
    
    # Initialize recovery strategies
    _init_recovery_strategies
    
    # Initialize error solutions
    _init_error_solutions
    
    # Set up error trap if not in recovery mode
    if [ "${RECOVERY_MODE:-false}" != "true" ]; then
        trap '_handle_trapped_error $? "$BASH_COMMAND" "$LINENO"' ERR
    fi
    
    log_debug "Error handler initialized (v$ERROR_HANDLER_VERSION)" "ERROR_HANDLER"
}

# Initialize recovery strategies
_init_recovery_strategies() {
    # Permission errors
    RECOVERY_STRATEGIES["PERMISSION_DENIED"]="retry_with_sudo check_ownership fix_permissions"
    
    # Disk space errors
    RECOVERY_STRATEGIES["DISK_FULL"]="cleanup_temp suggest_cleanup check_alternative_location"
    
    # Network errors
    RECOVERY_STRATEGIES["CONNECTION_FAILED"]="retry_with_backoff check_connectivity use_offline_mode"
    RECOVERY_STRATEGIES["DOWNLOAD_FAILED"]="retry_download use_mirror verify_url"
    
    # Dependency errors
    RECOVERY_STRATEGIES["COMMAND_NOT_FOUND"]="suggest_install check_path use_alternative"
    RECOVERY_STRATEGIES["VERSION_MISMATCH"]="suggest_upgrade check_compatibility use_older_version"
    
    # Config errors
    RECOVERY_STRATEGIES["INVALID_JSON"]="show_json_error suggest_fix validate_json"
    RECOVERY_STRATEGIES["MISSING_REQUIRED_VAR"]="prompt_for_value use_default check_env"
}

# Initialize error solutions
_init_error_solutions() {
    # Permission solutions
    ERROR_SOLUTIONS["PERMISSION_DENIED"]="Try running with sudo or check file ownership"
    
    # Disk space solutions
    ERROR_SOLUTIONS["DISK_FULL"]="Free up disk space or choose a different installation location"
    
    # Network solutions
    ERROR_SOLUTIONS["CONNECTION_FAILED"]="Check your internet connection and try again"
    ERROR_SOLUTIONS["DOWNLOAD_FAILED"]="The download failed. Check the URL or try again later"
    
    # Dependency solutions
    ERROR_SOLUTIONS["COMMAND_NOT_FOUND"]="Install the missing command or add it to your PATH"
    ERROR_SOLUTIONS["VERSION_MISMATCH"]="Update to the required version or check compatibility"
    
    # Config solutions
    ERROR_SOLUTIONS["INVALID_JSON"]="Fix the JSON syntax error in the configuration file"
    ERROR_SOLUTIONS["MISSING_REQUIRED_VAR"]="Set the required variable or use --defaults"
}

# Main error handler function
handle_error() {
    local error_code="${1:-UNKNOWN_ERROR}"
    local error_message="${2:-An error occurred}"
    local component="${3:-UNKNOWN}"
    local context="${4:-}"
    
    # Capture error context
    capture_error_context "$error_code" "$error_message" "$component" "$context"
    
    # Log the error
    log_error "[$error_code] $error_message" "$component"
    
    # Increment error count
    ((ERROR_COUNTS[$error_code]++))
    
    # Add to error history
    local timestamp=$(date +%s)
    ERROR_HISTORY[$timestamp]="$error_code:$component:$error_message"
    
    # Display user-friendly error
    display_error "$error_code" "$error_message"
    
    # Attempt recovery if available
    if [ "${AUTO_RECOVER:-true}" == "true" ]; then
        attempt_recovery "$error_code" "$component" "$context"
    fi
    
    # Check if we should exit
    if should_exit_on_error "$error_code"; then
        log_error "Unrecoverable error - exiting" "ERROR_HANDLER"
        generate_error_report
        exit "${ERROR_CODES[$error_code]:-1}"
    fi
    
    return "${ERROR_CODES[$error_code]:-1}"
}

# Capture error context
capture_error_context() {
    local error_code="$1"
    local error_message="$2"
    local component="$3"
    local additional_context="$4"
    
    # Capture system state
    ERROR_CONTEXT["$error_code:timestamp"]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ERROR_CONTEXT["$error_code:component"]="$component"
    ERROR_CONTEXT["$error_code:message"]="$error_message"
    ERROR_CONTEXT["$error_code:pwd"]="$PWD"
    ERROR_CONTEXT["$error_code:user"]="$USER"
    ERROR_CONTEXT["$error_code:shell"]="$SHELL"
    ERROR_CONTEXT["$error_code:bash_version"]="$BASH_VERSION"
    
    # Capture additional context if provided
    if [ -n "$additional_context" ]; then
        ERROR_CONTEXT["$error_code:additional"]="$additional_context"
    fi
    
    # Capture stack trace
    local stack_trace=""
    local i=0
    while caller $i &>/dev/null; do
        stack_trace+="$(caller $i)\n"
        ((i++))
    done
    ERROR_CONTEXT["$error_code:stack_trace"]="$stack_trace"
}

# Display user-friendly error
display_error() {
    local error_code="$1"
    local error_message="$2"
    
    # Get error category
    local category=$(get_error_category "$error_code")
    
    # Display error header
    echo ""
    print_color "$RED" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$RED" "⚠️  ERROR: $category Error"
    print_color "$RED" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Display error details
    print_color "$YELLOW" "Error Code: $error_code"
    print_color "$WHITE" "Message: $error_message"
    
    # Display solution if available
    if [ -n "${ERROR_SOLUTIONS[$error_code]}" ]; then
        echo ""
        print_color "$GREEN" "💡 Suggested Solution:"
        print_color "$WHITE" "   ${ERROR_SOLUTIONS[$error_code]}"
    fi
    
    echo ""
}

# Attempt automatic recovery
attempt_recovery() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    # Get recovery strategies
    local strategies="${RECOVERY_STRATEGIES[$error_code]}"
    if [ -z "$strategies" ]; then
        log_debug "No recovery strategies for $error_code" "ERROR_HANDLER"
        return 1
    fi
    
    log_info "Attempting automatic recovery for $error_code" "ERROR_HANDLER"
    
    # Try each strategy
    for strategy in $strategies; do
        log_debug "Trying recovery strategy: $strategy" "ERROR_HANDLER"
        
        if $strategy "$error_code" "$component" "$context"; then
            log_info "Recovery successful using $strategy" "ERROR_HANDLER"
            print_color "$GREEN" "✓ Automatic recovery successful!"
            return 0
        fi
    done
    
    log_warn "All recovery strategies failed for $error_code" "ERROR_HANDLER"
    return 1
}

# Recovery strategies

# Retry with sudo
retry_with_sudo() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    if [ "$EUID" -eq 0 ]; then
        return 1  # Already root
    fi
    
    if command -v sudo >/dev/null 2>&1; then
        print_color "$YELLOW" "Retrying with sudo privileges..."
        # Context should contain the failed command
        if [ -n "$context" ] && sudo $context; then
            return 0
        fi
    fi
    
    return 1
}

# Check ownership
check_ownership() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    # Extract file path from context
    local file_path="$context"
    if [ -z "$file_path" ] || [ ! -e "$file_path" ]; then
        return 1
    fi
    
    local owner=$(stat -c %U "$file_path" 2>/dev/null || stat -f %Su "$file_path" 2>/dev/null)
    local current_user="$USER"
    
    if [ "$owner" != "$current_user" ]; then
        print_color "$YELLOW" "File is owned by $owner, current user is $current_user"
        
        if prompt_user "Change ownership to current user?" "no"; then
            if sudo chown "$current_user" "$file_path"; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Cleanup temporary files
cleanup_temp() {
    local error_code="$1"
    
    print_color "$YELLOW" "Cleaning up temporary files..."
    
    # Clean system temp
    local temp_dirs=("/tmp" "/var/tmp" "$HOME/.cache")
    local freed_space=0
    
    for dir in "${temp_dirs[@]}"; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            # Find and remove old temp files (older than 7 days)
            local space_before=$(df "$dir" | awk 'NR==2 {print $4}')
            find "$dir" -type f -mtime +7 -name "tmp*" -delete 2>/dev/null || true
            find "$dir" -type f -mtime +7 -name "*.tmp" -delete 2>/dev/null || true
            local space_after=$(df "$dir" | awk 'NR==2 {print $4}')
            
            if [ -n "$space_before" ] && [ -n "$space_after" ]; then
                freed_space=$((freed_space + space_after - space_before))
            fi
        fi
    done
    
    if [ $freed_space -gt 0 ]; then
        print_color "$GREEN" "Freed up $(numfmt --to=iec $((freed_space * 1024)) 2>/dev/null || echo "${freed_space}K") of space"
        return 0
    fi
    
    return 1
}

# Retry with backoff
retry_with_backoff() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    local max_retries=3
    local delay=1
    
    for i in $(seq 1 $max_retries); do
        print_color "$YELLOW" "Retry attempt $i/$max_retries (waiting ${delay}s)..."
        sleep $delay
        
        # Context should contain the command to retry
        if [ -n "$context" ] && eval "$context" 2>/dev/null; then
            return 0
        fi
        
        delay=$((delay * 2))  # Exponential backoff
    done
    
    return 1
}

# Check connectivity
check_connectivity() {
    local error_code="$1"
    
    print_color "$YELLOW" "Checking network connectivity..."
    
    # Test connectivity to common endpoints
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com" "github.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            print_color "$GREEN" "✓ Network connectivity confirmed"
            return 0
        fi
    done
    
    print_color "$RED" "✗ No network connectivity detected"
    return 1
}

# Suggest installation
suggest_install() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    # Extract command name from context
    local cmd="$context"
    if [ -z "$cmd" ]; then
        return 1
    fi
    
    print_color "$YELLOW" "Command '$cmd' not found. Checking installation options..."
    
    # Detect package manager and suggest installation
    if command -v apt-get >/dev/null 2>&1; then
        print_color "$WHITE" "To install on Debian/Ubuntu:"
        print_color "$CYAN" "  sudo apt-get update && sudo apt-get install $cmd"
    elif command -v yum >/dev/null 2>&1; then
        print_color "$WHITE" "To install on RHEL/CentOS:"
        print_color "$CYAN" "  sudo yum install $cmd"
    elif command -v brew >/dev/null 2>&1; then
        print_color "$WHITE" "To install on macOS:"
        print_color "$CYAN" "  brew install $cmd"
    else
        print_color "$WHITE" "Please install '$cmd' using your system's package manager"
    fi
    
    return 1  # Don't auto-install, just suggest
}

# Show JSON error details
show_json_error() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    # Context should be the JSON file path
    local json_file="$context"
    if [ -z "$json_file" ] || [ ! -f "$json_file" ]; then
        return 1
    fi
    
    print_color "$YELLOW" "Analyzing JSON syntax error..."
    
    # Try to identify the error using Python
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
import sys

try:
    with open('$json_file', 'r') as f:
        json.load(f)
    print('JSON appears to be valid now')
    sys.exit(0)
except json.JSONDecodeError as e:
    print(f'JSON Error at line {e.lineno}, column {e.colno}: {e.msg}')
    # Show context around error
    with open('$json_file', 'r') as f:
        lines = f.readlines()
        start = max(0, e.lineno - 3)
        end = min(len(lines), e.lineno + 2)
        print('\\nContext:')
        for i in range(start, end):
            marker = ' >>> ' if i == e.lineno - 1 else '     '
            print(f'{marker}{i+1}: {lines[i]}', end='')
    sys.exit(1)
" 2>&1
        
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    
    return 1
}

# Prompt for missing value
prompt_for_value() {
    local error_code="$1"
    local component="$2"
    local context="$3"
    
    # Context should be the variable name
    local var_name="$context"
    if [ -z "$var_name" ]; then
        return 1
    fi
    
    print_color "$YELLOW" "Missing required variable: $var_name"
    
    # Get variable description if available
    local description=""
    case "$var_name" in
        "PROJECT_NAME")
            description="Name of your project"
            ;;
        "PROJECT_ROOT")
            description="Root directory of your project"
            ;;
        "AP_ROOT")
            description="AP Mapping installation directory"
            ;;
        *)
            description="Value for $var_name"
            ;;
    esac
    
    # Prompt user
    echo -n "Please enter $description: "
    read -r value
    
    if [ -n "$value" ]; then
        # Export the variable
        export "$var_name=$value"
        
        # Try to save to settings if possible
        if [ -n "$PROJECT_ROOT" ] && [ -d "$PROJECT_ROOT/.claude" ]; then
            local settings_file="$PROJECT_ROOT/.claude/settings.json"
            if [ -f "$settings_file" ]; then
                # Update settings.json
                python3 -c "
import json
with open('$settings_file', 'r') as f:
    settings = json.load(f)
settings['$var_name'] = '$value'
with open('$settings_file', 'w') as f:
    json.dump(settings, f, indent=2)
" 2>/dev/null && print_color "$GREEN" "✓ Saved to settings.json"
            fi
        fi
        
        return 0
    fi
    
    return 1
}

# Get error category
get_error_category() {
    local error_code="$1"
    
    case "$error_code" in
        PERMISSION_DENIED|DISK_FULL|OUT_OF_MEMORY|RESOURCE_BUSY)
            echo "System"
            ;;
        INVALID_JSON|MISSING_REQUIRED_VAR|INVALID_PATH|CONFIG_NOT_FOUND)
            echo "Configuration"
            ;;
        FILE_EXISTS|FILE_NOT_FOUND|CHECKSUM_MISMATCH|INSTALL_INCOMPLETE)
            echo "Installation"
            ;;
        CONNECTION_FAILED|DOWNLOAD_FAILED|TIMEOUT|DNS_FAILURE)
            echo "Network"
            ;;
        COMMAND_NOT_FOUND|VERSION_MISMATCH|LIBRARY_MISSING|PYTHON_MODULE_MISSING)
            echo "Dependency"
            ;;
        INVALID_INPUT|USER_CANCELLED|CONFIRMATION_FAILED)
            echo "User"
            ;;
        *)
            echo "Internal"
            ;;
    esac
}

# Check if we should exit on this error
should_exit_on_error() {
    local error_code="$1"
    
    # Critical errors that should always exit
    local critical_errors=(
        "OUT_OF_MEMORY"
        "STATE_CORRUPTED"
        "USER_CANCELLED"
    )
    
    for critical in "${critical_errors[@]}"; do
        if [ "$error_code" == "$critical" ]; then
            return 0
        fi
    done
    
    # Check if error has occurred too many times
    local error_count="${ERROR_COUNTS[$error_code]:-0}"
    if [ "$error_count" -gt 3 ]; then
        log_error "Error $error_code occurred $error_count times - giving up" "ERROR_HANDLER"
        return 0
    fi
    
    # Check if in strict mode
    if [ "${STRICT_MODE:-false}" == "true" ]; then
        return 0
    fi
    
    return 1
}

# Handle trapped errors
_handle_trapped_error() {
    local exit_code="$1"
    local failed_command="$2"
    local line_number="$3"
    
    # Don't handle if already in error handler
    if [ "${IN_ERROR_HANDLER:-false}" == "true" ]; then
        return $exit_code
    fi
    
    IN_ERROR_HANDLER=true
    
    # Try to determine error type from exit code and command
    local error_code="UNKNOWN_ERROR"
    local error_message="Command failed: $failed_command (line $line_number)"
    
    # Common exit code mappings
    case "$exit_code" in
        1)
            if [[ "$failed_command" =~ "permission denied" ]]; then
                error_code="PERMISSION_DENIED"
            fi
            ;;
        2)
            if [[ "$failed_command" =~ "No such file" ]]; then
                error_code="FILE_NOT_FOUND"
            fi
            ;;
        127)
            error_code="COMMAND_NOT_FOUND"
            # Extract command name
            local cmd=$(echo "$failed_command" | awk '{print $1}')
            error_message="Command not found: $cmd"
            ;;
        *)
            error_message="Command failed with exit code $exit_code: $failed_command"
            ;;
    esac
    
    # Handle the error
    handle_error "$error_code" "$error_message" "SHELL" "$failed_command"
    
    IN_ERROR_HANDLER=false
    
    return $exit_code
}

# Generate error report
generate_error_report() {
    local report_file="${ERROR_REPORT_FILE:-error-report-$(date +%Y%m%d-%H%M%S).txt}"
    
    {
        echo "AP Mapping Installation Error Report"
        echo "=================================="
        echo ""
        echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "Version: $INSTALLER_VERSION"
        echo ""
        
        echo "Error Summary"
        echo "-------------"
        echo "Total Errors: ${#ERROR_HISTORY[@]}"
        echo ""
        
        echo "Error Counts by Type:"
        for error_code in "${!ERROR_COUNTS[@]}"; do
            echo "  $error_code: ${ERROR_COUNTS[$error_code]}"
        done
        echo ""
        
        echo "Error History"
        echo "-------------"
        for timestamp in "${!ERROR_HISTORY[@]}"; do
            local error_info="${ERROR_HISTORY[$timestamp]}"
            local error_date=$(date -d "@$timestamp" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$timestamp" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
            echo "[$error_date] $error_info"
        done
        echo ""
        
        echo "Error Context Details"
        echo "--------------------"
        for key in "${!ERROR_CONTEXT[@]}"; do
            echo "$key: ${ERROR_CONTEXT[$key]}"
        done
        echo ""
        
        echo "System Information"
        echo "-----------------"
        echo "OS: $(uname -s) $(uname -r)"
        echo "Shell: $SHELL"
        echo "Bash Version: $BASH_VERSION"
        echo "User: $USER"
        echo "Working Directory: $PWD"
        echo ""
        
    } > "$report_file"
    
    print_color "$YELLOW" "Error report saved to: $report_file"
}

# Export error handler functions
export -f handle_error
export -f capture_error_context
export -f attempt_recovery
export -f generate_error_report

# Initialize if sourced directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "Error Handler Framework v$ERROR_HANDLER_VERSION"
    echo "This script should be sourced, not executed directly"
    exit 1
fi