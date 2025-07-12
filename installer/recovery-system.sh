#!/bin/bash

# AP Mapping Recovery System
# Checkpoint-based recovery and state management

# Recovery system version
RECOVERY_SYSTEM_VERSION="1.0.0"

# Recovery configuration
RECOVERY_DIR=".ap-recovery"
CHECKPOINT_PREFIX="checkpoint"
MAX_CHECKPOINTS=10
CHECKPOINT_COMPRESS=true
RECOVERY_MANIFEST="recovery-manifest.json"

# Recovery state
declare -gA CHECKPOINTS
declare -gA CHECKPOINT_METADATA
CURRENT_CHECKPOINT=""
RECOVERY_MODE=false

# Initialize recovery system
init_recovery_system() {
    local project_root="${1:-$PROJECT_ROOT}"
    
    if [ -z "$project_root" ]; then
        log_error "Project root not specified" "RECOVERY"
        return 1
    fi
    
    # Set up recovery directory
    RECOVERY_BASE="$project_root/$RECOVERY_DIR"
    mkdir -p "$RECOVERY_BASE"
    
    # Load existing checkpoints
    _load_checkpoint_registry
    
    # Set up auto-checkpoint if enabled
    if [ "${AUTO_CHECKPOINT:-true}" = true ]; then
        _setup_auto_checkpoint
    fi
    
    log_debug "Recovery system initialized (v$RECOVERY_SYSTEM_VERSION)" "RECOVERY"
    return 0
}

# Create recovery checkpoint
create_checkpoint() {
    local checkpoint_name="${1:-auto}"
    local description="${2:-Automatic checkpoint}"
    local checkpoint_type="${3:-manual}"  # manual, auto, pre-operation
    
    # Generate checkpoint ID
    local checkpoint_id="${CHECKPOINT_PREFIX}-$(date +%Y%m%d-%H%M%S)-$$"
    if [ "$checkpoint_name" != "auto" ]; then
        checkpoint_id="${CHECKPOINT_PREFIX}-${checkpoint_name}-$(date +%Y%m%d-%H%M%S)"
    fi
    
    local checkpoint_dir="$RECOVERY_BASE/$checkpoint_id"
    
    log_info "Creating checkpoint: $checkpoint_id" "RECOVERY"
    
    # Create checkpoint directory
    mkdir -p "$checkpoint_dir"
    
    # Save current state
    if ! _save_checkpoint_state "$checkpoint_dir"; then
        log_error "Failed to save checkpoint state" "RECOVERY"
        rm -rf "$checkpoint_dir"
        return 1
    fi
    
    # Create checkpoint metadata
    cat > "$checkpoint_dir/metadata.json" << EOF
{
    "checkpoint_id": "$checkpoint_id",
    "name": "$checkpoint_name",
    "description": "$description",
    "type": "$checkpoint_type",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "user": "$USER",
        "hostname": "$(hostname)",
        "pwd": "$PWD",
        "installer_version": "${INSTALLER_VERSION:-unknown}"
    }
}
EOF
    
    # Compress checkpoint if enabled
    if [ "$CHECKPOINT_COMPRESS" = true ]; then
        log_debug "Compressing checkpoint" "RECOVERY"
        tar -czf "$checkpoint_dir.tar.gz" -C "$RECOVERY_BASE" "$checkpoint_id" 2>/dev/null
        if [ $? -eq 0 ]; then
            rm -rf "$checkpoint_dir"
            checkpoint_dir="$checkpoint_dir.tar.gz"
        fi
    fi
    
    # Update checkpoint registry
    CHECKPOINTS["$checkpoint_id"]="$checkpoint_dir"
    CHECKPOINT_METADATA["$checkpoint_id"]="$checkpoint_name|$description|$checkpoint_type|$(date +%s)"
    _save_checkpoint_registry
    
    # Clean up old checkpoints
    _cleanup_old_checkpoints
    
    CURRENT_CHECKPOINT="$checkpoint_id"
    
    log_info "Checkpoint created successfully: $checkpoint_id" "RECOVERY"
    show_status "success" "Checkpoint created: $checkpoint_name"
    
    return 0
}

# List available checkpoints
list_checkpoints() {
    local format="${1:-table}"  # table, json, simple
    
    if [ ${#CHECKPOINTS[@]} -eq 0 ]; then
        echo "No checkpoints available"
        return 0
    fi
    
    case "$format" in
        table)
            # Table headers
            local headers=("ID" "Name" "Type" "Created" "Size")
            local rows=()
            
            # Build rows
            for checkpoint_id in "${!CHECKPOINTS[@]}"; do
                local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
                local metadata="${CHECKPOINT_METADATA[$checkpoint_id]}"
                IFS='|' read -r name desc type timestamp <<< "$metadata"
                
                # Get checkpoint size
                local size="0"
                if [ -e "$checkpoint_path" ]; then
                    size=$(du -sh "$checkpoint_path" 2>/dev/null | cut -f1 || echo "?")
                fi
                
                # Format timestamp
                local created=$(date -d "@$timestamp" +"%Y-%m-%d %H:%M" 2>/dev/null || date -r "$timestamp" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$timestamp")
                
                rows+=("$checkpoint_id|$name|$type|$created|$size")
            done
            
            # Sort by timestamp (newest first)
            IFS=$'\n' sorted=($(sort -t'|' -k4 -r <<<"${rows[*]}"))
            
            show_table headers sorted
            ;;
            
        json)
            echo "{"
            echo "  \"checkpoints\": ["
            local first=true
            for checkpoint_id in "${!CHECKPOINTS[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo ","
                fi
                
                local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
                local metadata="${CHECKPOINT_METADATA[$checkpoint_id]}"
                IFS='|' read -r name desc type timestamp <<< "$metadata"
                
                echo "    {"
                echo "      \"id\": \"$checkpoint_id\","
                echo "      \"name\": \"$name\","
                echo "      \"description\": \"$desc\","
                echo "      \"type\": \"$type\","
                echo "      \"created\": $timestamp,"
                echo "      \"path\": \"$checkpoint_path\""
                echo -n "    }"
            done
            echo ""
            echo "  ]"
            echo "}"
            ;;
            
        simple)
            for checkpoint_id in "${!CHECKPOINTS[@]}"; do
                local metadata="${CHECKPOINT_METADATA[$checkpoint_id]}"
                IFS='|' read -r name desc type timestamp <<< "$metadata"
                echo "$checkpoint_id - $name ($type)"
            done
            ;;
    esac
}

# Restore from checkpoint
restore_from_checkpoint() {
    local checkpoint_id="${1:-$CURRENT_CHECKPOINT}"
    local partial="${2:-false}"  # Full or partial restore
    local components="${3:-}"     # Space-separated list for partial restore
    
    if [ -z "$checkpoint_id" ]; then
        log_error "No checkpoint specified" "RECOVERY"
        return 1
    fi
    
    if [ -z "${CHECKPOINTS[$checkpoint_id]}" ]; then
        log_error "Checkpoint not found: $checkpoint_id" "RECOVERY"
        return 1
    fi
    
    local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
    
    # Set recovery mode
    RECOVERY_MODE=true
    
    log_info "Starting recovery from checkpoint: $checkpoint_id" "RECOVERY"
    show_notification "info" "Recovery Started" "Restoring from checkpoint: $checkpoint_id"
    
    # Extract checkpoint if compressed
    local working_dir="$checkpoint_path"
    if [[ "$checkpoint_path" =~ \.tar\.gz$ ]]; then
        working_dir="$RECOVERY_BASE/restore-$$"
        mkdir -p "$working_dir"
        tar -xzf "$checkpoint_path" -C "$working_dir" --strip-components=1
        if [ $? -ne 0 ]; then
            log_error "Failed to extract checkpoint" "RECOVERY"
            rm -rf "$working_dir"
            RECOVERY_MODE=false
            return 1
        fi
    fi
    
    # Perform recovery
    local recovery_result=0
    if [ "$partial" = true ]; then
        _restore_partial "$working_dir" "$components"
        recovery_result=$?
    else
        _restore_full "$working_dir"
        recovery_result=$?
    fi
    
    # Cleanup extracted checkpoint
    if [[ "$checkpoint_path" =~ \.tar\.gz$ ]]; then
        rm -rf "$working_dir"
    fi
    
    # Verify recovery
    if [ $recovery_result -eq 0 ]; then
        log_info "Recovery completed successfully" "RECOVERY"
        show_notification "success" "Recovery Complete" "Successfully restored from checkpoint"
        
        # Run integrity check
        if command -v perform_complete_check >/dev/null 2>&1; then
            log_info "Running integrity check after recovery" "RECOVERY"
            perform_complete_check
        fi
    else
        log_error "Recovery failed or partially completed" "RECOVERY"
        show_notification "error" "Recovery Failed" "Failed to restore from checkpoint"
    fi
    
    RECOVERY_MODE=false
    return $recovery_result
}

# Delete checkpoint
delete_checkpoint() {
    local checkpoint_id="$1"
    
    if [ -z "$checkpoint_id" ]; then
        log_error "No checkpoint specified" "RECOVERY"
        return 1
    fi
    
    if [ -z "${CHECKPOINTS[$checkpoint_id]}" ]; then
        log_error "Checkpoint not found: $checkpoint_id" "RECOVERY"
        return 1
    fi
    
    local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
    
    # Confirm deletion
    if ! confirm_action "Delete checkpoint $checkpoint_id?"; then
        return 0
    fi
    
    # Remove checkpoint
    rm -rf "$checkpoint_path"
    
    # Update registry
    unset CHECKPOINTS["$checkpoint_id"]
    unset CHECKPOINT_METADATA["$checkpoint_id"]
    _save_checkpoint_registry
    
    log_info "Checkpoint deleted: $checkpoint_id" "RECOVERY"
    show_status "success" "Checkpoint deleted"
    
    return 0
}

# Compare checkpoints
compare_checkpoints() {
    local checkpoint1="$1"
    local checkpoint2="$2"
    
    if [ -z "$checkpoint1" ] || [ -z "$checkpoint2" ]; then
        log_error "Two checkpoints required for comparison" "RECOVERY"
        return 1
    fi
    
    # Extract checkpoints for comparison
    local dir1="$RECOVERY_BASE/compare-1-$$"
    local dir2="$RECOVERY_BASE/compare-2-$$"
    
    mkdir -p "$dir1" "$dir2"
    
    # Extract first checkpoint
    if ! _extract_checkpoint "$checkpoint1" "$dir1"; then
        rm -rf "$dir1" "$dir2"
        return 1
    fi
    
    # Extract second checkpoint
    if ! _extract_checkpoint "$checkpoint2" "$dir2"; then
        rm -rf "$dir1" "$dir2"
        return 1
    fi
    
    echo "Comparing checkpoints:"
    echo "  1: $checkpoint1"
    echo "  2: $checkpoint2"
    echo ""
    
    # Compare file lists
    echo "File differences:"
    diff -rq "$dir1" "$dir2" 2>/dev/null | grep -E "^Only in|^Files" | head -20
    
    # Compare configurations
    if [ -f "$dir1/.claude/settings.json" ] && [ -f "$dir2/.claude/settings.json" ]; then
        echo ""
        echo "Configuration differences:"
        diff -u "$dir1/.claude/settings.json" "$dir2/.claude/settings.json" 2>/dev/null | head -20
    fi
    
    # Cleanup
    rm -rf "$dir1" "$dir2"
    
    return 0
}

# Verify checkpoint integrity
verify_checkpoint() {
    local checkpoint_id="${1:-$CURRENT_CHECKPOINT}"
    
    if [ -z "$checkpoint_id" ]; then
        log_error "No checkpoint specified" "RECOVERY"
        return 1
    fi
    
    if [ -z "${CHECKPOINTS[$checkpoint_id]}" ]; then
        log_error "Checkpoint not found: $checkpoint_id" "RECOVERY"
        return 1
    fi
    
    local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
    
    log_info "Verifying checkpoint: $checkpoint_id" "RECOVERY"
    
    # Check if checkpoint exists
    if [ ! -e "$checkpoint_path" ]; then
        log_error "Checkpoint file missing: $checkpoint_path" "RECOVERY"
        return 1
    fi
    
    # Verify compressed checkpoint
    if [[ "$checkpoint_path" =~ \.tar\.gz$ ]]; then
        if ! tar -tzf "$checkpoint_path" >/dev/null 2>&1; then
            log_error "Checkpoint archive corrupted" "RECOVERY"
            return 1
        fi
    fi
    
    # Extract and verify metadata
    local temp_dir="$RECOVERY_BASE/verify-$$"
    mkdir -p "$temp_dir"
    
    if ! _extract_checkpoint "$checkpoint_id" "$temp_dir"; then
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check metadata file
    if [ ! -f "$temp_dir/metadata.json" ]; then
        log_error "Checkpoint metadata missing" "RECOVERY"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify metadata is valid JSON
    if ! jq empty "$temp_dir/metadata.json" 2>/dev/null; then
        log_error "Checkpoint metadata corrupted" "RECOVERY"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check manifest if exists
    if [ -f "$temp_dir/manifest.json" ]; then
        if ! jq empty "$temp_dir/manifest.json" 2>/dev/null; then
            log_error "Checkpoint manifest corrupted" "RECOVERY"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    rm -rf "$temp_dir"
    
    log_info "Checkpoint verified successfully" "RECOVERY"
    show_status "success" "Checkpoint is valid"
    
    return 0
}

# Private functions

# Save checkpoint state
_save_checkpoint_state() {
    local checkpoint_dir="$1"
    
    # Save project files
    if [ -n "$PROJECT_ROOT" ] && [ -d "$PROJECT_ROOT" ]; then
        # Create manifest of current state
        if command -v create_manifest >/dev/null 2>&1; then
            create_manifest "$PROJECT_ROOT" "$checkpoint_dir/manifest.json" >/dev/null 2>&1
        fi
        
        # Save critical directories
        local dirs_to_save=(
            ".claude"
            ".ap-install"
            "docs"
            "logs"
        )
        
        for dir in "${dirs_to_save[@]}"; do
            if [ -d "$PROJECT_ROOT/$dir" ]; then
                cp -r "$PROJECT_ROOT/$dir" "$checkpoint_dir/" 2>/dev/null
            fi
        done
        
        # Save environment variables
        (
            echo "# Environment snapshot"
            echo "PROJECT_ROOT=\"$PROJECT_ROOT\""
            echo "PROJECT_NAME=\"$PROJECT_NAME\""
            echo "AP_ROOT=\"$AP_ROOT\""
            echo "INSTALLER_VERSION=\"$INSTALLER_VERSION\""
            env | grep -E "^(AP_|PROJECT_)" | sort
        ) > "$checkpoint_dir/environment.sh"
        
        # Save installation state
        if [ -f "$PROJECT_ROOT/.ap-install/installation-state.json" ]; then
            cp "$PROJECT_ROOT/.ap-install/installation-state.json" "$checkpoint_dir/"
        fi
    fi
    
    return 0
}

# Restore full checkpoint
_restore_full() {
    local checkpoint_dir="$1"
    
    log_info "Performing full system restore" "RECOVERY"
    
    # Show progress
    show_progress_bar "Restoring checkpoint" 0 100 "restore"
    
    # Restore environment
    if [ -f "$checkpoint_dir/environment.sh" ]; then
        source "$checkpoint_dir/environment.sh"
        show_progress_bar "Restoring checkpoint" 20 100 "restore"
    fi
    
    # Restore directories
    local progress=20
    local dirs=($(find "$checkpoint_dir" -maxdepth 1 -type d -not -name "." | grep -v metadata))
    local dir_count=${#dirs[@]}
    
    for dir in "${dirs[@]}"; do
        local basename=$(basename "$dir")
        if [ -n "$PROJECT_ROOT" ]; then
            # Backup current state
            if [ -d "$PROJECT_ROOT/$basename" ]; then
                mv "$PROJECT_ROOT/$basename" "$PROJECT_ROOT/$basename.pre-restore" 2>/dev/null
            fi
            
            # Restore
            cp -r "$dir" "$PROJECT_ROOT/" 2>/dev/null
            
            progress=$((progress + 60 / dir_count))
            show_progress_bar "Restoring checkpoint" $progress 100 "restore"
        fi
    done
    
    # Restore installation state
    if [ -f "$checkpoint_dir/installation-state.json" ] && [ -n "$PROJECT_ROOT" ]; then
        mkdir -p "$PROJECT_ROOT/.ap-install"
        cp "$checkpoint_dir/installation-state.json" "$PROJECT_ROOT/.ap-install/"
        show_progress_bar "Restoring checkpoint" 90 100 "restore"
    fi
    
    show_progress_bar "Restoring checkpoint" 100 100 "restore"
    
    return 0
}

# Restore partial checkpoint
_restore_partial() {
    local checkpoint_dir="$1"
    local components="$2"
    
    log_info "Performing partial restore: $components" "RECOVERY"
    
    for component in $components; do
        case "$component" in
            config|settings)
                if [ -d "$checkpoint_dir/.claude" ] && [ -n "$PROJECT_ROOT" ]; then
                    log_info "Restoring configuration" "RECOVERY"
                    cp -r "$checkpoint_dir/.claude" "$PROJECT_ROOT/" 2>/dev/null
                fi
                ;;
            docs|documentation)
                if [ -d "$checkpoint_dir/docs" ] && [ -n "$PROJECT_ROOT" ]; then
                    log_info "Restoring documentation" "RECOVERY"
                    cp -r "$checkpoint_dir/docs" "$PROJECT_ROOT/" 2>/dev/null
                fi
                ;;
            state)
                if [ -f "$checkpoint_dir/installation-state.json" ] && [ -n "$PROJECT_ROOT" ]; then
                    log_info "Restoring installation state" "RECOVERY"
                    mkdir -p "$PROJECT_ROOT/.ap-install"
                    cp "$checkpoint_dir/installation-state.json" "$PROJECT_ROOT/.ap-install/"
                fi
                ;;
            env|environment)
                if [ -f "$checkpoint_dir/environment.sh" ]; then
                    log_info "Restoring environment" "RECOVERY"
                    source "$checkpoint_dir/environment.sh"
                fi
                ;;
            *)
                log_warn "Unknown component: $component" "RECOVERY"
                ;;
        esac
    done
    
    return 0
}

# Load checkpoint registry
_load_checkpoint_registry() {
    CHECKPOINTS=()
    CHECKPOINT_METADATA=()
    
    if [ -f "$RECOVERY_BASE/$RECOVERY_MANIFEST" ]; then
        # Load from JSON manifest
        while IFS= read -r line; do
            local id=$(echo "$line" | cut -d: -f1)
            local path=$(echo "$line" | cut -d: -f2)
            local metadata=$(echo "$line" | cut -d: -f3-)
            
            if [ -n "$id" ] && [ -n "$path" ]; then
                CHECKPOINTS["$id"]="$path"
                CHECKPOINT_METADATA["$id"]="$metadata"
            fi
        done < <(jq -r '.checkpoints[] | "\(.id):\(.path):\(.name)|\(.description)|\(.type)|\(.timestamp)"' "$RECOVERY_BASE/$RECOVERY_MANIFEST" 2>/dev/null)
    else
        # Scan directory for checkpoints
        for checkpoint in "$RECOVERY_BASE"/$CHECKPOINT_PREFIX-*; do
            if [ -e "$checkpoint" ]; then
                local id=$(basename "$checkpoint" | sed 's/\.tar\.gz$//')
                CHECKPOINTS["$id"]="$checkpoint"
                
                # Try to load metadata
                local metadata="unknown|Discovered checkpoint|unknown|$(stat -c %Y "$checkpoint" 2>/dev/null || stat -f %m "$checkpoint" 2>/dev/null || echo 0)"
                CHECKPOINT_METADATA["$id"]="$metadata"
            fi
        done
    fi
}

# Save checkpoint registry
_save_checkpoint_registry() {
    cat > "$RECOVERY_BASE/$RECOVERY_MANIFEST" << EOF
{
    "version": "$RECOVERY_SYSTEM_VERSION",
    "updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "checkpoints": [
EOF
    
    local first=true
    for id in "${!CHECKPOINTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$RECOVERY_BASE/$RECOVERY_MANIFEST"
        fi
        
        local path="${CHECKPOINTS[$id]}"
        local metadata="${CHECKPOINT_METADATA[$id]}"
        IFS='|' read -r name desc type timestamp <<< "$metadata"
        
        cat >> "$RECOVERY_BASE/$RECOVERY_MANIFEST" << EOF
        {
            "id": "$id",
            "path": "$path",
            "name": "$name",
            "description": "$desc",
            "type": "$type",
            "timestamp": $timestamp
        }
EOF
    done
    
    echo "    ]" >> "$RECOVERY_BASE/$RECOVERY_MANIFEST"
    echo "}" >> "$RECOVERY_BASE/$RECOVERY_MANIFEST"
}

# Clean up old checkpoints
_cleanup_old_checkpoints() {
    local checkpoint_count=${#CHECKPOINTS[@]}
    
    if [ $checkpoint_count -le $MAX_CHECKPOINTS ]; then
        return
    fi
    
    log_info "Cleaning up old checkpoints (max: $MAX_CHECKPOINTS)" "RECOVERY"
    
    # Sort checkpoints by timestamp
    local sorted_checkpoints=()
    while IFS= read -r line; do
        sorted_checkpoints+=("$line")
    done < <(
        for id in "${!CHECKPOINTS[@]}"; do
            local metadata="${CHECKPOINT_METADATA[$id]}"
            IFS='|' read -r name desc type timestamp <<< "$metadata"
            echo "$timestamp:$id"
        done | sort -n
    )
    
    # Remove oldest checkpoints
    local to_remove=$((checkpoint_count - MAX_CHECKPOINTS))
    for ((i=0; i<to_remove; i++)); do
        local checkpoint_info="${sorted_checkpoints[$i]}"
        local id="${checkpoint_info#*:}"
        
        # Don't remove manual checkpoints
        local metadata="${CHECKPOINT_METADATA[$id]}"
        IFS='|' read -r name desc type timestamp <<< "$metadata"
        
        if [ "$type" != "manual" ]; then
            log_debug "Removing old checkpoint: $id" "RECOVERY"
            rm -rf "${CHECKPOINTS[$id]}"
            unset CHECKPOINTS["$id"]
            unset CHECKPOINT_METADATA["$id"]
        fi
    done
    
    _save_checkpoint_registry
}

# Extract checkpoint
_extract_checkpoint() {
    local checkpoint_id="$1"
    local target_dir="$2"
    
    local checkpoint_path="${CHECKPOINTS[$checkpoint_id]}"
    
    if [[ "$checkpoint_path" =~ \.tar\.gz$ ]]; then
        tar -xzf "$checkpoint_path" -C "$target_dir" --strip-components=1 2>/dev/null
    else
        cp -r "$checkpoint_path"/* "$target_dir/" 2>/dev/null
    fi
}

# Set up auto checkpoint
_setup_auto_checkpoint() {
    # Create checkpoint before critical operations
    export -f create_checkpoint
    
    # Hook into error handler if available
    if declare -f handle_error >/dev/null 2>&1; then
        log_debug "Integrating with error handler for auto-checkpoint" "RECOVERY"
    fi
}

# Export recovery functions
export -f create_checkpoint
export -f list_checkpoints
export -f restore_from_checkpoint
export -f delete_checkpoint
export -f verify_checkpoint

# Initialize if sourced directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "Recovery System v$RECOVERY_SYSTEM_VERSION"
    echo "This script should be sourced, not executed directly"
    exit 1
fi