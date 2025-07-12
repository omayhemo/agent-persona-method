#!/bin/bash

# AP Mapping Profile Manager
# Installation profile management for different scenarios

# Profile manager version
PROFILE_MANAGER_VERSION="1.0.0"

# Profile configuration
PROFILES_DIR=".ap-profiles"
PROFILE_EXTENSION=".profile"
SYSTEM_PROFILES_DIR="$SCRIPT_DIR/profiles"
DEFAULT_PROFILE="default"

# Profile types
declare -gA PROFILE_TYPES=(
    ["minimal"]="Minimal installation with core features only"
    ["standard"]="Standard installation with recommended features"
    ["full"]="Complete installation with all features"
    ["developer"]="Developer setup with debugging tools"
    ["production"]="Production deployment with optimizations"
    ["custom"]="User-defined custom profile"
)

# Active profile
ACTIVE_PROFILE=""
declare -gA PROFILE_SETTINGS
declare -gA PROFILE_METADATA

# Initialize profile manager
init_profile_manager() {
    local project_root="${1:-$PROJECT_ROOT}"
    
    # Set up profile directories
    if [ -n "$project_root" ]; then
        USER_PROFILES_DIR="$project_root/$PROFILES_DIR"
        mkdir -p "$USER_PROFILES_DIR"
    fi
    
    # Create system profiles directory if needed
    mkdir -p "$SYSTEM_PROFILES_DIR" 2>/dev/null || true
    
    # Initialize default profiles if missing
    _init_default_profiles
    
    # Load user preferences
    _load_user_preferences
    
    log_debug "Profile manager initialized (v$PROFILE_MANAGER_VERSION)" "PROFILE"
    return 0
}

# Create profile
create_profile() {
    local profile_name="$1"
    local profile_type="${2:-custom}"
    local base_profile="${3:-}"  # Optional base profile to extend
    
    if [ -z "$profile_name" ]; then
        log_error "Profile name required" "PROFILE"
        return 1
    fi
    
    # Validate profile name
    if ! [[ "$profile_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid profile name. Use only letters, numbers, underscore, and hyphen" "PROFILE"
        return 1
    fi
    
    local profile_file="$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
    
    # Check if profile exists
    if [ -f "$profile_file" ]; then
        if ! confirm_action "Profile '$profile_name' exists. Overwrite?"; then
            return 0
        fi
    fi
    
    log_info "Creating profile: $profile_name (type: $profile_type)" "PROFILE"
    
    # Start with base profile or template
    if [ -n "$base_profile" ]; then
        if ! load_profile "$base_profile" >/dev/null 2>&1; then
            log_warn "Base profile not found, starting fresh" "PROFILE"
        fi
    else
        # Load template based on type
        case "$profile_type" in
            minimal)
                _load_minimal_template
                ;;
            standard)
                _load_standard_template
                ;;
            full)
                _load_full_template
                ;;
            developer)
                _load_developer_template
                ;;
            production)
                _load_production_template
                ;;
            *)
                _load_minimal_template
                ;;
        esac
    fi
    
    # Interactive profile creation if in interactive mode
    if [ "$INTERACTIVE_MODE" = true ]; then
        _interactive_profile_setup "$profile_name"
    fi
    
    # Save profile
    _save_profile "$profile_file" "$profile_name" "$profile_type"
    
    show_status "success" "Profile created: $profile_name"
    return 0
}

# Load profile
load_profile() {
    local profile_name="$1"
    local silent="${2:-false}"
    
    if [ -z "$profile_name" ]; then
        log_error "Profile name required" "PROFILE"
        return 1
    fi
    
    # Find profile file
    local profile_file=""
    if [ -f "$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" ]; then
        profile_file="$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
    elif [ -f "$SYSTEM_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" ]; then
        profile_file="$SYSTEM_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
    elif [ -f "$profile_name" ]; then
        # Direct file path
        profile_file="$profile_name"
    else
        log_error "Profile not found: $profile_name" "PROFILE"
        return 1
    fi
    
    log_info "Loading profile: $profile_name" "PROFILE"
    
    # Clear current settings
    PROFILE_SETTINGS=()
    PROFILE_METADATA=()
    
    # Load profile
    if ! source "$profile_file"; then
        log_error "Failed to load profile: $profile_file" "PROFILE"
        return 1
    fi
    
    ACTIVE_PROFILE="$profile_name"
    
    if [ "$silent" != true ]; then
        show_status "success" "Profile loaded: $profile_name"
        
        # Show profile summary
        echo "Profile Settings:"
        for key in "${!PROFILE_SETTINGS[@]}"; do
            echo "  $key: ${PROFILE_SETTINGS[$key]}"
        done | sort
    fi
    
    return 0
}

# List profiles
list_profiles() {
    local format="${1:-table}"  # table, json, simple
    local show_all="${2:-true}"  # Include system profiles
    
    local profiles=()
    
    # Collect user profiles
    if [ -d "$USER_PROFILES_DIR" ]; then
        for profile in "$USER_PROFILES_DIR"/*${PROFILE_EXTENSION}; do
            if [ -f "$profile" ]; then
                profiles+=("user:$(basename "$profile" "$PROFILE_EXTENSION")")
            fi
        done
    fi
    
    # Collect system profiles
    if [ "$show_all" = true ] && [ -d "$SYSTEM_PROFILES_DIR" ]; then
        for profile in "$SYSTEM_PROFILES_DIR"/*${PROFILE_EXTENSION}; do
            if [ -f "$profile" ]; then
                profiles+=("system:$(basename "$profile" "$PROFILE_EXTENSION")")
            fi
        done
    fi
    
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "No profiles found"
        return 0
    fi
    
    case "$format" in
        table)
            local headers=("Name" "Type" "Location" "Description")
            local rows=()
            
            for profile_info in "${profiles[@]}"; do
                IFS=':' read -r location name <<< "$profile_info"
                
                # Load profile metadata
                local profile_file=""
                if [ "$location" = "user" ]; then
                    profile_file="$USER_PROFILES_DIR/${name}${PROFILE_EXTENSION}"
                else
                    profile_file="$SYSTEM_PROFILES_DIR/${name}${PROFILE_EXTENSION}"
                fi
                
                local type="custom"
                local description="No description"
                
                if [ -f "$profile_file" ]; then
                    # Extract metadata
                    type=$(grep "^# TYPE:" "$profile_file" 2>/dev/null | cut -d: -f2- | xargs || echo "custom")
                    description=$(grep "^# DESCRIPTION:" "$profile_file" 2>/dev/null | cut -d: -f2- | xargs || echo "No description")
                fi
                
                # Mark active profile
                if [ "$name" = "$ACTIVE_PROFILE" ]; then
                    name="$name *"
                fi
                
                rows+=("$name|$type|$location|$description")
            done
            
            show_table headers rows
            
            if [ -n "$ACTIVE_PROFILE" ]; then
                echo ""
                echo "* Active profile"
            fi
            ;;
            
        json)
            echo "{"
            echo "  \"profiles\": ["
            local first=true
            
            for profile_info in "${profiles[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo ","
                fi
                
                IFS=':' read -r location name <<< "$profile_info"
                
                echo "    {"
                echo "      \"name\": \"$name\","
                echo "      \"location\": \"$location\","
                echo "      \"active\": $([ "$name" = "$ACTIVE_PROFILE" ] && echo "true" || echo "false")"
                echo -n "    }"
            done
            
            echo ""
            echo "  ]"
            echo "}"
            ;;
            
        simple)
            for profile_info in "${profiles[@]}"; do
                IFS=':' read -r location name <<< "$profile_info"
                if [ "$name" = "$ACTIVE_PROFILE" ]; then
                    echo "* $name ($location)"
                else
                    echo "  $name ($location)"
                fi
            done
            ;;
    esac
}

# Export profile
export_profile() {
    local profile_name="${1:-$ACTIVE_PROFILE}"
    local output_file="$2"
    local format="${3:-profile}"  # profile, json, env
    
    if [ -z "$profile_name" ]; then
        log_error "No profile specified" "PROFILE"
        return 1
    fi
    
    # Load profile if not active
    if [ "$profile_name" != "$ACTIVE_PROFILE" ]; then
        if ! load_profile "$profile_name" true; then
            return 1
        fi
    fi
    
    # Default output file
    if [ -z "$output_file" ]; then
        output_file="${profile_name}-export.${format}"
    fi
    
    log_info "Exporting profile: $profile_name to $output_file" "PROFILE"
    
    case "$format" in
        profile)
            # Export as profile file
            local source_file=""
            if [ -f "$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" ]; then
                source_file="$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
            elif [ -f "$SYSTEM_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" ]; then
                source_file="$SYSTEM_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
            fi
            
            if [ -n "$source_file" ]; then
                cp "$source_file" "$output_file"
            else
                _save_profile "$output_file" "$profile_name" "exported"
            fi
            ;;
            
        json)
            # Export as JSON
            {
                echo "{"
                echo "  \"profile\": \"$profile_name\","
                echo "  \"exported\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
                echo "  \"version\": \"$PROFILE_MANAGER_VERSION\","
                echo "  \"metadata\": {"
                for key in "${!PROFILE_METADATA[@]}"; do
                    echo "    \"$key\": \"${PROFILE_METADATA[$key]}\","
                done | sed '$ s/,$//'
                echo "  },"
                echo "  \"settings\": {"
                for key in "${!PROFILE_SETTINGS[@]}"; do
                    echo "    \"$key\": \"${PROFILE_SETTINGS[$key]}\","
                done | sed '$ s/,$//'
                echo "  }"
                echo "}"
            } > "$output_file"
            ;;
            
        env)
            # Export as environment variables
            {
                echo "# Profile: $profile_name"
                echo "# Exported: $(date)"
                echo ""
                for key in "${!PROFILE_SETTINGS[@]}"; do
                    echo "export $key=\"${PROFILE_SETTINGS[$key]}\""
                done | sort
            } > "$output_file"
            ;;
    esac
    
    show_status "success" "Profile exported to: $output_file"
    return 0
}

# Import profile
import_profile() {
    local import_file="$1"
    local profile_name="$2"
    
    if [ ! -f "$import_file" ]; then
        log_error "Import file not found: $import_file" "PROFILE"
        return 1
    fi
    
    # Determine profile name
    if [ -z "$profile_name" ]; then
        profile_name=$(basename "$import_file" | sed -E 's/\.(profile|json|env)$//')
    fi
    
    log_info "Importing profile from: $import_file" "PROFILE"
    
    # Determine format
    local format="profile"
    if [[ "$import_file" =~ \.json$ ]]; then
        format="json"
    elif [[ "$import_file" =~ \.env$ ]]; then
        format="env"
    fi
    
    case "$format" in
        profile)
            # Direct copy
            cp "$import_file" "$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
            ;;
            
        json)
            # Parse JSON and create profile
            PROFILE_SETTINGS=()
            while IFS= read -r line; do
                IFS=':' read -r key value <<< "$line"
                PROFILE_SETTINGS["$key"]="$value"
            done < <(jq -r '.settings | to_entries[] | "\(.key):\(.value)"' "$import_file")
            
            _save_profile "$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" "$profile_name" "imported"
            ;;
            
        env)
            # Parse environment file
            PROFILE_SETTINGS=()
            while IFS= read -r line; do
                if [[ "$line" =~ ^export[[:space:]]+([^=]+)=(.*)$ ]]; then
                    local key="${BASH_REMATCH[1]}"
                    local value="${BASH_REMATCH[2]}"
                    value="${value%\"}"
                    value="${value#\"}"
                    PROFILE_SETTINGS["$key"]="$value"
                fi
            done < "$import_file"
            
            _save_profile "$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}" "$profile_name" "imported"
            ;;
    esac
    
    show_status "success" "Profile imported: $profile_name"
    return 0
}

# Delete profile
delete_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        log_error "Profile name required" "PROFILE"
        return 1
    fi
    
    # Only delete user profiles
    local profile_file="$USER_PROFILES_DIR/${profile_name}${PROFILE_EXTENSION}"
    
    if [ ! -f "$profile_file" ]; then
        log_error "Profile not found or is a system profile: $profile_name" "PROFILE"
        return 1
    fi
    
    if ! confirm_action "Delete profile '$profile_name'?"; then
        return 0
    fi
    
    rm -f "$profile_file"
    
    # Clear if active
    if [ "$profile_name" = "$ACTIVE_PROFILE" ]; then
        ACTIVE_PROFILE=""
        PROFILE_SETTINGS=()
        PROFILE_METADATA=()
    fi
    
    log_info "Profile deleted: $profile_name" "PROFILE"
    show_status "success" "Profile deleted"
    
    return 0
}

# Apply profile settings
apply_profile_settings() {
    if [ -z "$ACTIVE_PROFILE" ]; then
        log_warn "No active profile" "PROFILE"
        return 1
    fi
    
    log_info "Applying profile settings: $ACTIVE_PROFILE" "PROFILE"
    
    # Export profile settings as environment variables
    for key in "${!PROFILE_SETTINGS[@]}"; do
        export "$key=${PROFILE_SETTINGS[$key]}"
        log_debug "Set $key=${PROFILE_SETTINGS[$key]}" "PROFILE"
    done
    
    # Apply specific settings
    if [ -n "${PROFILE_SETTINGS[LOG_LEVEL]}" ]; then
        LOG_LEVEL="${PROFILE_SETTINGS[LOG_LEVEL]}"
    fi
    
    if [ -n "${PROFILE_SETTINGS[DEBUG_MODE]}" ]; then
        DEBUG_MODE="${PROFILE_SETTINGS[DEBUG_MODE]}"
    fi
    
    if [ -n "${PROFILE_SETTINGS[INTERACTIVE_MODE]}" ]; then
        INTERACTIVE_MODE="${PROFILE_SETTINGS[INTERACTIVE_MODE]}"
    fi
    
    return 0
}

# Validate profile
validate_profile() {
    local profile_name="${1:-$ACTIVE_PROFILE}"
    
    if [ -z "$profile_name" ]; then
        log_error "No profile specified" "PROFILE"
        return 1
    fi
    
    # Load profile if not active
    if [ "$profile_name" != "$ACTIVE_PROFILE" ]; then
        if ! load_profile "$profile_name" true; then
            return 1
        fi
    fi
    
    log_info "Validating profile: $profile_name" "PROFILE"
    
    local errors=0
    
    # Check required settings
    local required_settings=(
        "PROJECT_NAME"
        "LOG_LEVEL"
        "BACKUP_ENABLED"
    )
    
    for setting in "${required_settings[@]}"; do
        if [ -z "${PROFILE_SETTINGS[$setting]}" ]; then
            log_error "Missing required setting: $setting" "PROFILE"
            ((errors++))
        fi
    done
    
    # Validate settings
    if [ -n "${PROFILE_SETTINGS[LOG_LEVEL]}" ]; then
        case "${PROFILE_SETTINGS[LOG_LEVEL]}" in
            TRACE|DEBUG|INFO|WARN|ERROR|FATAL) ;;
            *)
                log_error "Invalid LOG_LEVEL: ${PROFILE_SETTINGS[LOG_LEVEL]}" "PROFILE"
                ((errors++))
                ;;
        esac
    fi
    
    if [ $errors -gt 0 ]; then
        show_status "error" "Profile validation failed: $errors errors"
        return 1
    else
        show_status "success" "Profile is valid"
        return 0
    fi
}

# Private functions

# Initialize default profiles
_init_default_profiles() {
    # Create minimal profile
    if [ ! -f "$SYSTEM_PROFILES_DIR/minimal${PROFILE_EXTENSION}" ]; then
        cat > "$SYSTEM_PROFILES_DIR/minimal${PROFILE_EXTENSION}" << 'EOF'
#!/bin/bash
# AP Mapping Minimal Profile
# TYPE: minimal
# DESCRIPTION: Minimal installation with core features only

# Metadata
PROFILE_METADATA["type"]="minimal"
PROFILE_METADATA["version"]="1.0.0"
PROFILE_METADATA["description"]="Minimal installation with core features only"

# Core settings
PROFILE_SETTINGS["PROJECT_NAME"]="MyProject"
PROFILE_SETTINGS["LOG_LEVEL"]="INFO"
PROFILE_SETTINGS["LOG_TO_FILE"]="false"
PROFILE_SETTINGS["DEBUG_MODE"]="false"
PROFILE_SETTINGS["INTERACTIVE_MODE"]="true"

# Features
PROFILE_SETTINGS["BACKUP_ENABLED"]="false"
PROFILE_SETTINGS["GENERATE_DOCS"]="false"
PROFILE_SETTINGS["CREATE_MANIFEST"]="false"
PROFILE_SETTINGS["VERIFY_INSTALL"]="false"
PROFILE_SETTINGS["AUTO_CHECKPOINT"]="false"

# Performance
PROFILE_SETTINGS["PARALLEL_OPERATIONS"]="false"
PROFILE_SETTINGS["COMPRESSION_ENABLED"]="false"
EOF
    fi
    
    # Create standard profile
    if [ ! -f "$SYSTEM_PROFILES_DIR/standard${PROFILE_EXTENSION}" ]; then
        cat > "$SYSTEM_PROFILES_DIR/standard${PROFILE_EXTENSION}" << 'EOF'
#!/bin/bash
# AP Mapping Standard Profile
# TYPE: standard
# DESCRIPTION: Standard installation with recommended features

# Metadata
PROFILE_METADATA["type"]="standard"
PROFILE_METADATA["version"]="1.0.0"
PROFILE_METADATA["description"]="Standard installation with recommended features"

# Core settings
PROFILE_SETTINGS["PROJECT_NAME"]="MyProject"
PROFILE_SETTINGS["LOG_LEVEL"]="INFO"
PROFILE_SETTINGS["LOG_TO_FILE"]="true"
PROFILE_SETTINGS["DEBUG_MODE"]="false"
PROFILE_SETTINGS["INTERACTIVE_MODE"]="true"

# Features
PROFILE_SETTINGS["BACKUP_ENABLED"]="true"
PROFILE_SETTINGS["GENERATE_DOCS"]="true"
PROFILE_SETTINGS["CREATE_MANIFEST"]="true"
PROFILE_SETTINGS["VERIFY_INSTALL"]="true"
PROFILE_SETTINGS["AUTO_CHECKPOINT"]="true"

# Performance
PROFILE_SETTINGS["PARALLEL_OPERATIONS"]="true"
PROFILE_SETTINGS["COMPRESSION_ENABLED"]="true"
PROFILE_SETTINGS["MAX_CHECKPOINTS"]="5"
EOF
    fi
    
    # Create developer profile
    if [ ! -f "$SYSTEM_PROFILES_DIR/developer${PROFILE_EXTENSION}" ]; then
        cat > "$SYSTEM_PROFILES_DIR/developer${PROFILE_EXTENSION}" << 'EOF'
#!/bin/bash
# AP Mapping Developer Profile
# TYPE: developer
# DESCRIPTION: Developer setup with debugging tools

# Metadata
PROFILE_METADATA["type"]="developer"
PROFILE_METADATA["version"]="1.0.0"
PROFILE_METADATA["description"]="Developer setup with debugging tools"

# Core settings
PROFILE_SETTINGS["PROJECT_NAME"]="DevProject"
PROFILE_SETTINGS["LOG_LEVEL"]="DEBUG"
PROFILE_SETTINGS["LOG_TO_FILE"]="true"
PROFILE_SETTINGS["DEBUG_MODE"]="true"
PROFILE_SETTINGS["INTERACTIVE_MODE"]="true"

# Features
PROFILE_SETTINGS["BACKUP_ENABLED"]="true"
PROFILE_SETTINGS["GENERATE_DOCS"]="true"
PROFILE_SETTINGS["CREATE_MANIFEST"]="true"
PROFILE_SETTINGS["VERIFY_INSTALL"]="true"
PROFILE_SETTINGS["AUTO_CHECKPOINT"]="true"

# Debug features
PROFILE_SETTINGS["TRACE_MODE"]="false"
PROFILE_SETTINGS["PERF_TRACKING"]="true"
PROFILE_SETTINGS["GENERATE_REPORT"]="true"
PROFILE_SETTINGS["DEBUG_CHECKPOINT"]="true"

# Performance
PROFILE_SETTINGS["PARALLEL_OPERATIONS"]="false"
PROFILE_SETTINGS["COMPRESSION_ENABLED"]="true"
PROFILE_SETTINGS["MAX_CHECKPOINTS"]="20"
EOF
    fi
}

# Interactive profile setup
_interactive_profile_setup() {
    local profile_name="$1"
    
    echo ""
    print_color "$CYAN" "Configure Profile: $profile_name"
    print_color "$CYAN" "================================"
    echo ""
    
    # Project settings
    PROFILE_SETTINGS["PROJECT_NAME"]=$(input_with_validation \
        "Project name" \
        "^[a-zA-Z][a-zA-Z0-9_-]*$" \
        "Invalid project name" \
        "${PROFILE_SETTINGS[PROJECT_NAME]:-MyProject}")
    
    # Logging settings
    local log_levels=("TRACE" "DEBUG" "INFO" "WARN" "ERROR")
    echo ""
    echo "Select log level:"
    local selected=$(show_menu "Log Level" "${log_levels[@]}")
    if [ "$selected" -gt 0 ] && [ "$selected" -le ${#log_levels[@]} ]; then
        PROFILE_SETTINGS["LOG_LEVEL"]="${log_levels[$((selected-1))]}"
    fi
    
    # Feature toggles
    echo ""
    echo "Enable features:"
    PROFILE_SETTINGS["BACKUP_ENABLED"]=$(prompt_user "Enable backup system?" "yes" "yes/no")
    PROFILE_SETTINGS["GENERATE_DOCS"]=$(prompt_user "Generate documentation?" "yes" "yes/no")
    PROFILE_SETTINGS["CREATE_MANIFEST"]=$(prompt_user "Create installation manifest?" "yes" "yes/no")
    PROFILE_SETTINGS["VERIFY_INSTALL"]=$(prompt_user "Verify installation?" "yes" "yes/no")
    PROFILE_SETTINGS["AUTO_CHECKPOINT"]=$(prompt_user "Enable auto-checkpoint?" "yes" "yes/no")
    
    # Advanced settings
    if confirm_action "Configure advanced settings?"; then
        echo ""
        PROFILE_SETTINGS["PARALLEL_OPERATIONS"]=$(prompt_user "Enable parallel operations?" "yes" "yes/no")
        PROFILE_SETTINGS["COMPRESSION_ENABLED"]=$(prompt_user "Enable compression?" "yes" "yes/no")
        PROFILE_SETTINGS["MAX_CHECKPOINTS"]=$(input_with_validation \
            "Maximum checkpoints" \
            "^[0-9]+$" \
            "Must be a number" \
            "${PROFILE_SETTINGS[MAX_CHECKPOINTS]:-10}")
    fi
}

# Save profile
_save_profile() {
    local profile_file="$1"
    local profile_name="$2"
    local profile_type="$3"
    
    {
        echo "#!/bin/bash"
        echo "# AP Mapping Profile: $profile_name"
        echo "# TYPE: $profile_type"
        echo "# DESCRIPTION: ${PROFILE_METADATA[description]:-User-created profile}"
        echo "# Created: $(date)"
        echo ""
        
        echo "# Metadata"
        for key in "${!PROFILE_METADATA[@]}"; do
            echo "PROFILE_METADATA[\"$key\"]=\"${PROFILE_METADATA[$key]}\""
        done | sort
        echo ""
        
        echo "# Settings"
        for key in "${!PROFILE_SETTINGS[@]}"; do
            echo "PROFILE_SETTINGS[\"$key\"]=\"${PROFILE_SETTINGS[$key]}\""
        done | sort
    } > "$profile_file"
    
    chmod +x "$profile_file"
}

# Load user preferences
_load_user_preferences() {
    local prefs_file="$HOME/.ap-installer-prefs"
    
    if [ -f "$prefs_file" ]; then
        source "$prefs_file" 2>/dev/null || true
    fi
}

# Save user preferences
save_user_preferences() {
    local prefs_file="$HOME/.ap-installer-prefs"
    
    {
        echo "# AP Installer User Preferences"
        echo "# Last updated: $(date)"
        echo ""
        echo "LAST_PROFILE=\"$ACTIVE_PROFILE\""
        echo "DEFAULT_LOG_LEVEL=\"${PROFILE_SETTINGS[LOG_LEVEL]:-INFO}\""
        echo "PREFERRED_PROFILE_TYPE=\"${PROFILE_METADATA[type]:-standard}\""
    } > "$prefs_file"
}

# Export profile manager functions
export -f create_profile
export -f load_profile
export -f list_profiles
export -f export_profile
export -f import_profile
export -f apply_profile_settings
export -f validate_profile

# Initialize if sourced directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "Profile Manager v$PROFILE_MANAGER_VERSION"
    echo "This script should be sourced, not executed directly"
    exit 1
fi