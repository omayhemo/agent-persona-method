#!/bin/bash

# AP Mapping Variable Manager v2
# Centralized variable management with validation, type checking, and logging

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging framework
source "$SCRIPT_DIR/logging-framework.sh"

# Initialize logging
init_logging "VARIABLE-MANAGER"

# Global variables
VARIABLES_FILE="$SCRIPT_DIR/variables.json"
VARIABLES_CACHE="/tmp/ap_variables_$$"
EXPORT_FILE=""
INTERACTIVE=true
DEBUG=false

# Performance tracking
PERF_TRACKING="${PERF_TRACKING:-true}"

# Color codes (for backward compatibility)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output (wrapper for logging)
print_color() {
    local color=$1
    local message=$2
    
    # Map colors to log levels
    case "$color" in
        "$RED")
            log_error "$message" "VARIABLE-MANAGER"
            ;;
        "$GREEN")
            log_info "$message" "VARIABLE-MANAGER"
            ;;
        "$YELLOW")
            log_warn "$message" "VARIABLE-MANAGER"
            ;;
        "$BLUE")
            log_debug "$message" "VARIABLE-MANAGER"
            ;;
        *)
            echo -e "${color}${message}${NC}" >&2
            ;;
    esac
}

# Function to print debug messages
debug() {
    log_debug "$1" "VARIABLE-MANAGER"
}

# Function to load variables configuration
load_variables_config() {
    start_timer "load_config"
    
    if [ ! -f "$VARIABLES_FILE" ]; then
        log_error "Variables configuration not found: $VARIABLES_FILE" "VARIABLE-MANAGER"
        stop_timer "load_config"
        return 1
    fi
    
    log_debug "Loading variables from: $VARIABLES_FILE" "VARIABLE-MANAGER"
    
    # Parse JSON and extract variable definitions
    python3 -c "
import json
import sys

with open('$VARIABLES_FILE', 'r') as f:
    config = json.load(f)
    
# Output variable definitions in shell format
for var_name, var_def in config['variables'].items():
    print(f'VAR_NAME_{var_name}=\"{var_name}\"')
    print(f'VAR_TYPE_{var_name}=\"{var_def.get(\"type\", \"string\")}\"')
    print(f'VAR_DESC_{var_name}=\"{var_def.get(\"description\", \"\")}\"')
    print(f'VAR_REQUIRED_{var_name}=\"{var_def.get(\"required\", True)}\"')
    print(f'VAR_DEFAULT_{var_name}=\"{var_def.get(\"default\", \"\")}\"')
"
    
    stop_timer "load_config"
}

# Function to validate string type
validate_string() {
    local var_name=$1
    local value=$2
    local pattern=""
    local min_length=""
    local max_length=""
    
    log_trace "Validating string variable: $var_name" "VALIDATION"
    
    # Extract validation rules
    pattern=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
rules = config['variables'].get('$var_name', {}).get('validation', {})
print(rules.get('pattern', ''))
" 2>/dev/null)
    
    min_length=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
rules = config['variables'].get('$var_name', {}).get('validation', {})
print(rules.get('minLength', ''))
" 2>/dev/null)
    
    max_length=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
rules = config['variables'].get('$var_name', {}).get('validation', {})
print(rules.get('maxLength', ''))
" 2>/dev/null)
    
    # Check pattern
    if [ -n "$pattern" ] && ! echo "$value" | grep -qE "$pattern"; then
        log_error "$var_name: Value does not match required pattern: $pattern" "VALIDATION"
        return 1
    fi
    
    # Check length constraints
    local length=${#value}
    if [ -n "$min_length" ] && [ "$length" -lt "$min_length" ]; then
        log_error "$var_name: Value too short (minimum: $min_length characters)" "VALIDATION"
        return 1
    fi
    
    if [ -n "$max_length" ] && [ "$length" -gt "$max_length" ]; then
        log_error "$var_name: Value too long (maximum: $max_length characters)" "VALIDATION"
        return 1
    fi
    
    log_trace "String validation passed for $var_name" "VALIDATION"
    return 0
}

# Function to validate path type
validate_path() {
    local var_name=$1
    local value=$2
    
    log_trace "Validating path variable: $var_name = $value" "VALIDATION"
    
    # Expand variables in path
    local expanded_path=$(eval echo "$value")
    log_trace "Expanded path: $expanded_path" "VALIDATION"
    
    # Extract validation rules
    local rules=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
rules = config['variables'].get('$var_name', {}).get('validation', {})
print(json.dumps(rules))
" 2>/dev/null)
    
    # Check if path should exist
    if echo "$rules" | grep -q '"exists": true' && [ ! -e "$expanded_path" ]; then
        log_error "$var_name: Path does not exist: $expanded_path" "VALIDATION"
        return 1
    fi
    
    # Check if should be directory
    if echo "$rules" | grep -q '"isDirectory": true' && [ ! -d "$expanded_path" ]; then
        log_error "$var_name: Path is not a directory: $expanded_path" "VALIDATION"
        return 1
    fi
    
    # Check if writable (parent directory if path doesn't exist)
    if echo "$rules" | grep -q '"writable": true'; then
        local check_path="$expanded_path"
        if [ ! -e "$expanded_path" ]; then
            check_path=$(dirname "$expanded_path")
        fi
        if [ ! -w "$check_path" ]; then
            log_error "$var_name: Path is not writable: $check_path" "VALIDATION"
            return 1
        fi
    fi
    
    # Check if executable
    if echo "$rules" | grep -q '"executable": true' && [ -e "$expanded_path" ] && [ ! -x "$expanded_path" ]; then
        log_warn "$var_name: Path is not executable: $expanded_path" "VALIDATION"
        # This is a warning, not an error
    fi
    
    log_trace "Path validation passed for $var_name" "VALIDATION"
    return 0
}

# Function to validate enum type
validate_enum() {
    local var_name=$1
    local value=$2
    
    log_trace "Validating enum variable: $var_name = $value" "VALIDATION"
    
    # Get allowed values
    local allowed_values=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
allowed = config['variables'].get('$var_name', {}).get('allowedValues', [])
print(' '.join(allowed))
" 2>/dev/null)
    
    # Check if value is in allowed list
    local found=false
    for allowed in $allowed_values; do
        if [ "$value" = "$allowed" ]; then
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        log_error "$var_name: Invalid value '$value'. Allowed values: $allowed_values" "VALIDATION"
        return 1
    fi
    
    log_trace "Enum validation passed for $var_name" "VALIDATION"
    return 0
}

# Main validation function
validate_variable() {
    local var_name=$1
    local value=$2
    local var_type=$3
    
    start_timer "validate_$var_name"
    log_debug "Validating $var_name (type: $var_type) = '$value'" "VALIDATION"
    
    # Skip validation for empty optional variables
    local required=$(eval echo "\$VAR_REQUIRED_$var_name")
    if [ "$required" = "False" ] && [ -z "$value" ]; then
        log_trace "Skipping validation for optional empty variable: $var_name" "VALIDATION"
        stop_timer "validate_$var_name"
        return 0
    fi
    
    # Validate based on type
    local result=0
    case "$var_type" in
        string)
            validate_string "$var_name" "$value" || result=$?
            ;;
        path)
            validate_path "$var_name" "$value" || result=$?
            ;;
        enum)
            validate_enum "$var_name" "$value" || result=$?
            ;;
        *)
            log_warn "Unknown type: $var_type for variable: $var_name" "VALIDATION"
            ;;
    esac
    
    stop_timer "validate_$var_name"
    
    if [ $result -eq 0 ]; then
        log_structured "INFO" "variable_validated" "name" "$var_name" "type" "$var_type" "result" "pass"
    else
        log_structured "ERROR" "variable_validation_failed" "name" "$var_name" "type" "$var_type" "value" "$value"
    fi
    
    return $result
}

# Function to resolve variable references
resolve_variable() {
    local value=$1
    local max_depth=10
    local depth=0
    
    log_trace "Resolving variable references in: $value" "RESOLVER"
    
    # Resolve ${VAR} references
    while echo "$value" | grep -q '\${[^}]*}' && [ $depth -lt $max_depth ]; do
        value=$(echo "$value" | sed 's/\${PROJECT_ROOT}/'"${PROJECT_ROOT//\//\\/}"'/g')
        value=$(echo "$value" | sed 's/\${AP_ROOT}/'"${AP_ROOT//\//\\/}"'/g')
        value=$(echo "$value" | sed 's/\${PROJECT_DOCS}/'"${PROJECT_DOCS//\//\\/}"'/g')
        value=$(echo "$value" | sed 's/\${CLAUDE_DIR}/'"${CLAUDE_DIR//\//\\/}"'/g')
        ((depth++))
    done
    
    if [ $depth -eq $max_depth ]; then
        log_warn "Maximum recursion depth reached while resolving: $value" "RESOLVER"
    fi
    
    # Resolve shell command substitutions
    if echo "$value" | grep -q '$(.*)"'; then
        value=$(eval echo "$value")
    fi
    
    log_trace "Resolved to: $value" "RESOLVER"
    echo "$value"
}

# Function to process conditional values
process_conditional() {
    local var_name=$1
    
    log_trace "Processing conditional logic for: $var_name" "CONDITIONAL"
    
    # Check if variable has conditional logic
    local conditional=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
cond = config['variables'].get('$var_name', {}).get('conditional', {})
if cond:
    print(json.dumps(cond))
" 2>/dev/null)
    
    if [ -z "$conditional" ] || [ "$conditional" = "{}" ]; then
        return 0
    fi
    
    # Extract condition components
    local condition=$(echo "$conditional" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('if', ''))
")
    
    local then_value=$(echo "$conditional" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('then', ''))
")
    
    local else_value=$(echo "$conditional" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('else', ''))
")
    
    log_debug "Evaluating condition: $condition" "CONDITIONAL"
    
    # Evaluate condition
    if eval "[ $condition ]" 2>/dev/null; then
        log_trace "Condition true, using: $then_value" "CONDITIONAL"
        echo "$then_value"
    else
        log_trace "Condition false, using: $else_value" "CONDITIONAL"
        echo "$else_value"
    fi
}

# Function to prompt for variable value
prompt_for_variable() {
    local var_name=$1
    local default_value=$2
    local description=$3
    
    if [ "$INTERACTIVE" = false ]; then
        log_debug "Non-interactive mode, using default for $var_name: $default_value" "PROMPT"
        echo "$default_value"
        return
    fi
    
    echo "" >&2
    print_color "$BLUE" "$description"
    read -p "Enter $var_name [$default_value]: " user_input
    
    local result="${user_input:-$default_value}"
    log_debug "User provided value for $var_name: $result" "PROMPT"
    echo "$result"
}

# Function to export variables to file
export_variables() {
    local output_file=$1
    
    start_timer "export_variables"
    log_info "Exporting variables to: $output_file" "EXPORT"
    
    cat > "$output_file" << EOF
# AP Mapping Variable Export
# Generated: $(date)
# Version: $(cat "$VARIABLES_FILE" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])")

EOF
    
    # Export all variables
    eval $(load_variables_config 2>/dev/null)
    
    # Get all variable names
    local var_names=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
for var in config['variables']:
    print(var)
")
    
    local exported_count=0
    for var_name in $var_names; do
        local value=$(eval echo "\$$var_name" 2>/dev/null || echo "")
        if [ -n "$value" ]; then
            echo "export $var_name=\"$value\"" >> "$output_file"
            ((exported_count++))
        fi
    done
    
    stop_timer "export_variables"
    log_info "Exported $exported_count variables to: $output_file" "EXPORT"
    print_color "$GREEN" "✓ Variables exported to: $output_file"
}

# Function to import variables from file
import_variables() {
    local input_file=$1
    
    start_timer "import_variables"
    log_info "Importing variables from: $input_file" "IMPORT"
    
    if [ ! -f "$input_file" ]; then
        log_error "Import file not found: $input_file" "IMPORT"
        stop_timer "import_variables"
        return 1
    fi
    
    # Source the file in a subshell and validate
    (
        source "$input_file"
        
        # Validate all imported variables
        local errors=0
        local imported_count=0
        eval $(load_variables_config 2>/dev/null)
        
        local var_names=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
for var in config['variables']:
    print(var)
")
        
        for var_name in $var_names; do
            local value=$(eval echo "\$$var_name" 2>/dev/null || echo "")
            local var_type=$(eval echo "\$VAR_TYPE_$var_name")
            
            if [ -n "$value" ]; then
                ((imported_count++))
                if ! validate_variable "$var_name" "$value" "$var_type"; then
                    ((errors++))
                fi
            fi
        done
        
        log_info "Imported $imported_count variables with $errors errors" "IMPORT"
        
        if [ $errors -eq 0 ]; then
            print_color "$GREEN" "✓ All imported variables are valid"
            exit 0
        else
            print_color "$RED" "✗ $errors validation errors found"
            exit 1
        fi
    )
    
    local result=$?
    stop_timer "import_variables"
    return $result
}

# Function to process all variables
process_all_variables() {
    start_timer "process_all_variables"
    log_info "Processing all variables" "PROCESSOR"
    
    # Load variable definitions
    eval $(load_variables_config)
    
    # Get all variable names
    local var_names=$(python3 -c "
import json
config = json.load(open('$VARIABLES_FILE'))
for var in config['variables']:
    print(var)
")
    
    local errors=0
    local processed=0
    
    # Log variable state before processing
    log_variables "PROCESSOR" $var_names
    
    # Process each variable
    for var_name in $var_names; do
        ((processed++))
        increment_counter "variables_processed"
        
        local var_type=$(eval echo "\$VAR_TYPE_$var_name")
        local var_desc=$(eval echo "\$VAR_DESC_$var_name")
        local var_default=$(eval echo "\$VAR_DEFAULT_$var_name")
        local var_required=$(eval echo "\$VAR_REQUIRED_$var_name")
        
        log_debug "Processing variable $var_name (type: $var_type, required: $var_required)" "PROCESSOR"
        
        # Check for conditional logic
        local conditional_value=$(process_conditional "$var_name")
        if [ -n "$conditional_value" ]; then
            var_default="$conditional_value"
        fi
        
        # Resolve default value
        var_default=$(resolve_variable "$var_default")
        
        # Get current value or prompt
        local current_value=$(eval echo "\$$var_name" 2>/dev/null || echo "")
        if [ -z "$current_value" ]; then
            if [ "$var_required" = "True" ] || [ "$INTERACTIVE" = true ]; then
                current_value=$(prompt_for_variable "$var_name" "$var_default" "$var_desc")
            else
                current_value="$var_default"
            fi
        fi
        
        # Validate
        if ! validate_variable "$var_name" "$current_value" "$var_type"; then
            ((errors++))
            increment_counter "validation_errors"
            continue
        fi
        
        # Export for use
        export "$var_name=$current_value"
        echo "export $var_name=\"$current_value\"" >> "$VARIABLES_CACHE"
        
        log_trace "Successfully processed $var_name = $current_value" "PROCESSOR"
    done
    
    stop_timer "process_all_variables"
    
    log_info "Processed $processed variables with $errors errors" "PROCESSOR"
    
    if [ $errors -gt 0 ]; then
        log_error "$errors validation errors found" "PROCESSOR"
        return 1
    fi
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive|-n)
            INTERACTIVE=false
            shift
            ;;
        --debug|-d)
            DEBUG=true
            set_log_level "DEBUG"
            shift
            ;;
        --trace)
            set_log_level "TRACE"
            PERF_TRACKING="true"
            shift
            ;;
        --export|-e)
            EXPORT_FILE="$2"
            shift 2
            ;;
        --import|-i)
            import_variables "$2"
            exit $?
            ;;
        --log-level)
            set_log_level "$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --non-interactive, -n    Run without prompts"
            echo "  --debug, -d             Enable debug output"
            echo "  --trace                 Enable trace output with performance tracking"
            echo "  --export FILE, -e FILE  Export variables to file"
            echo "  --import FILE, -i FILE  Import variables from file"
            echo "  --log-level LEVEL       Set log level (TRACE, DEBUG, INFO, WARN, ERROR)"
            echo "  --help, -h              Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1" "ARGS"
            exit 1
            ;;
    esac
done

# Main execution
log_info "AP Mapping Variable Manager v2 starting" "MAIN"
log_info "Log level: $LOG_LEVEL" "MAIN"

print_color "$BLUE" "AP Mapping Variable Manager"
print_color "$BLUE" "========================="

# Clean up any previous cache
rm -f "$VARIABLES_CACHE"

# Process all variables
if process_all_variables; then
    print_color "$GREEN" "\n✓ All variables validated successfully"
    
    # Export if requested
    if [ -n "$EXPORT_FILE" ]; then
        export_variables "$EXPORT_FILE"
    fi
    
    # Generate performance report if tracking
    if [[ "$PERF_TRACKING" == "true" ]]; then
        generate_performance_report
    fi
    
    # Output cache location for sourcing
    echo "$VARIABLES_CACHE"
    
    log_info "Variable manager completed successfully" "MAIN"
    finalize_logging
    exit 0
else
    rm -f "$VARIABLES_CACHE"
    log_error "Variable manager failed with errors" "MAIN"
    finalize_logging
    exit 1
fi