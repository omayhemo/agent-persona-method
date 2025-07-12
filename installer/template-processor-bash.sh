#!/bin/bash
# AP Mapping Template Processor - Pure Bash Implementation
# Supports variable substitution with {{VAR}} syntax

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize variables
declare -A TEMPLATE_VARS=()
TEMPLATE_FILE=""
OUTPUT_FILE=""
DEBUG="${DEBUG:-false}"
VALIDATE_ONLY=false

# Debug logging
debug() {
    [ "$DEBUG" == "true" ] && echo "[DEBUG] $*" >&2
}

# Error handling
error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Show usage
usage() {
    cat << EOF
AP Mapping Template Processor (Bash version)

Usage: $(basename "$0") [OPTIONS] <template-file> [output-file]

Options:
    -v, --vars FILE      Load variables from JSON file
    -s, --set VAR=VALUE  Set a variable
    -e, --env            Load variables from environment
    -d, --debug          Enable debug output
    --validate           Validate template syntax only
    -h, --help           Show this help

Examples:
    # Process template to stdout
    $(basename "$0") template.txt

    # Process template to file
    $(basename "$0") template.txt output.txt

    # Load variables from JSON
    $(basename "$0") --vars vars.json template.txt

    # Set variables directly
    $(basename "$0") --set PROJECT_NAME=MyProject template.txt

EOF
    exit 0
}

# Load variables from JSON file
load_json_vars() {
    local json_file="$1"
    
    if [ ! -f "$json_file" ]; then
        error "JSON file not found: $json_file"
    fi
    
    debug "Loading variables from: $json_file"
    
    # Use jq if available, otherwise use basic parsing
    if command -v jq &>/dev/null; then
        # Extract key-value pairs using jq
        while IFS='=' read -r key value; do
            TEMPLATE_VARS["$key"]="$value"
            debug "Loaded from JSON: $key=$value"
        done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$json_file" 2>/dev/null || echo "")
    else
        # Basic JSON parsing (handles simple key-value pairs)
        while IFS=':' read -r key value; do
            # Clean up key and value
            key=$(echo "$key" | sed 's/["{,]//g' | xargs)
            value=$(echo "$value" | sed 's/["},]//g' | xargs)
            
            if [ -n "$key" ] && [ -n "$value" ]; then
                TEMPLATE_VARS["$key"]="$value"
                debug "Loaded from JSON (basic): $key=$value"
            fi
        done < <(grep -E '^\s*"[^"]+"\s*:\s*"[^"]*"' "$json_file")
    fi
}

# Load variables from environment
load_env_vars() {
    debug "Loading variables from environment"
    
    # Load AP Mapping specific variables
    for var in PROJECT_NAME PROJECT_ROOT PROJECT_DOCS AP_ROOT \
               CLAUDE_SETTINGS_PATH CLAUDE_HOOKS_PATH CLAUDE_COMMANDS_PATH \
               NOTES_TYPE NOTES_PATH SESSION_NOTE_TITLE RULES_PATH \
               ARCHIVE_SESSION_NOTES SPEAK_ANALYST SPEAK_ARCHITECT \
               SPEAK_DESIGN_ARCHITECT SPEAK_DEVELOPER SPEAK_ORCHESTRATOR \
               SPEAK_PM SPEAK_PO SPEAK_QA SPEAK_SM FALLBACK_TTS; do
        if [ -n "${!var}" ]; then
            TEMPLATE_VARS["$var"]="${!var}"
            debug "Loaded from env: $var=${!var}"
        fi
    done
}

# Process template file
process_template() {
    local template_file="$1"
    local content
    
    if [ ! -f "$template_file" ]; then
        error "Template file not found: $template_file"
    fi
    
    debug "Processing template: $template_file"
    
    # Read template content
    content=$(<"$template_file")
    
    # Validate mode - just check syntax
    if [ "$VALIDATE_ONLY" == "true" ]; then
        # Check for unclosed variables
        if echo "$content" | grep -q '{{[^}]*$'; then
            error "Unclosed variable found in template"
        fi
        
        # Check for basic syntax errors
        if echo "$content" | grep -q '}[^}]}'; then
            error "Malformed variable syntax found"
        fi
        
        echo "Template syntax is valid"
        return 0
    fi
    
    # Process each variable
    for var in "${!TEMPLATE_VARS[@]}"; do
        local value="${TEMPLATE_VARS[$var]}"
        debug "Replacing {{$var}} with '$value'"
        
        # Escape special characters in the value for sed
        value=$(printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|]/\\&/g')
        
        # Replace all occurrences of {{VAR}}
        content=$(echo "$content" | sed "s/{{${var}}}/${value}/g")
    done
    
    # Output result
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$content" > "$OUTPUT_FILE"
        debug "Wrote processed template to: $OUTPUT_FILE"
    else
        echo "$content"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--vars)
            load_json_vars "$2"
            shift 2
            ;;
        -s|--set)
            if [[ "$2" =~ ^([^=]+)=(.*)$ ]]; then
                var_name="${BASH_REMATCH[1]}"
                var_value="${BASH_REMATCH[2]}"
                TEMPLATE_VARS["$var_name"]="$var_value"
                debug "Set variable: $var_name=$var_value"
            else
                error "Invalid variable format. Use VAR=VALUE"
            fi
            shift 2
            ;;
        -e|--env)
            load_env_vars
            shift
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            if [ -z "$TEMPLATE_FILE" ]; then
                TEMPLATE_FILE="$1"
            elif [ -z "$OUTPUT_FILE" ]; then
                OUTPUT_FILE="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Check if template file was provided
if [ -z "$TEMPLATE_FILE" ]; then
    error "No template file specified"
fi

# Process the template
process_template "$TEMPLATE_FILE"