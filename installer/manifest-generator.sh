#!/bin/bash

# AP Mapping Manifest Generator
# Creates and manages installation manifests for tracking and verification

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source logging framework
source "$SCRIPT_DIR/logging-framework.sh"

# Initialize logging
init_logging "MANIFEST" 

# Manifest generator configuration
GENERATOR_VERSION="1.0.0"
PROJECT_ROOT=""
MANIFEST_FILE=""
MANIFEST_FORMAT="json"
INCLUDE_CHECKSUMS=true
INCLUDE_PERMISSIONS=true
INCLUDE_TIMESTAMPS=true
CALCULATE_SIZES=true

# File tracking
FILES_TRACKED=0
DIRS_TRACKED=0
TOTAL_SIZE=0

# Initialize manifest generator
init_manifest_generator() {
    local project_root="${1:-$PWD}"
    local manifest_file="${2:-}"
    
    log_info "Initializing manifest generator v$GENERATOR_VERSION" "INIT"
    start_timer "manifest_init"
    
    PROJECT_ROOT="$project_root"
    
    # Determine manifest file location
    if [ -n "$manifest_file" ]; then
        MANIFEST_FILE="$manifest_file"
    else
        # Create timestamped manifest
        local manifest_dir="$PROJECT_ROOT/.ap-install"
        mkdir -p "$manifest_dir"
        MANIFEST_FILE="$manifest_dir/installation-manifest-$(date +%Y%m%d-%H%M%S).json"
    fi
    
    log_debug "Project root: $PROJECT_ROOT" "INIT"
    log_debug "Manifest file: $MANIFEST_FILE" "INIT"
    
    stop_timer "manifest_init"
    return 0
}

# Get file metadata
get_file_metadata() {
    local file_path="$1"
    local relative_path="${2:-$file_path}"
    
    log_trace "Getting metadata for: $file_path" "METADATA"
    
    if [ ! -e "$file_path" ]; then
        log_warn "File not found: $file_path" "METADATA"
        return 1
    fi
    
    local metadata=""
    
    # Get file type
    local file_type="file"
    if [ -d "$file_path" ]; then
        file_type="directory"
    elif [ -L "$file_path" ]; then
        file_type="symlink"
    fi
    
    # Start JSON object
    metadata='{'
    metadata+='"path":"'$(echo "$relative_path" | sed 's/"/\\"/g')'"'
    metadata+=',"type":"'$file_type'"'
    
    # Add file-specific metadata
    if [ "$file_type" = "file" ]; then
        # Size
        if [ "$CALCULATE_SIZES" = true ]; then
            local size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo 0)
            metadata+=',"size":'$size
            ((TOTAL_SIZE += size))
        fi
        
        # Checksum
        if [ "$INCLUDE_CHECKSUMS" = true ]; then
            if [ -f "$SCRIPT_DIR/integrity-checker.sh" ]; then
                source "$SCRIPT_DIR/integrity-checker.sh"
                local checksum=$(calculate_checksum "$file_path" 2>/dev/null || echo "")
                if [ -n "$checksum" ] && [ "$checksum" != "FILE_NOT_FOUND" ]; then
                    metadata+=',"checksum":"'$checksum'"'
                fi
            fi
        fi
    fi
    
    # Permissions
    if [ "$INCLUDE_PERMISSIONS" = true ]; then
        local perms=$(stat -c%a "$file_path" 2>/dev/null || stat -f%Lp "$file_path" 2>/dev/null || echo "")
        if [ -n "$perms" ]; then
            metadata+=',"permissions":"'$perms'"'
        fi
        
        # Owner and group (if available)
        local owner=$(stat -c%U "$file_path" 2>/dev/null || stat -f%Su "$file_path" 2>/dev/null || echo "")
        local group=$(stat -c%G "$file_path" 2>/dev/null || stat -f%Sg "$file_path" 2>/dev/null || echo "")
        
        if [ -n "$owner" ]; then
            metadata+=',"owner":"'$owner'"'
        fi
        if [ -n "$group" ]; then
            metadata+=',"group":"'$group'"'
        fi
    fi
    
    # Timestamps
    if [ "$INCLUDE_TIMESTAMPS" = true ]; then
        local mtime=$(stat -c%Y "$file_path" 2>/dev/null || stat -f%m "$file_path" 2>/dev/null || echo "")
        if [ -n "$mtime" ]; then
            metadata+=',"modified":'$mtime
        fi
    fi
    
    # Close JSON object
    metadata+='}'
    
    echo "$metadata"
    return 0
}

# Scan directory recursively
scan_directory() {
    local directory="$1"
    local base_dir="${2:-$directory}"
    local exclude_patterns="${3:-}"
    
    log_debug "Scanning directory: $directory" "SCAN"
    
    local entries=""
    local first_entry=true
    
    # Build find command with exclusions
    local find_cmd="find \"$directory\""
    
    # Add standard exclusions
    find_cmd+=" -not -path '*/\\.git/*'"
    find_cmd+=" -not -path '*/\\.ap-backup/*'"
    find_cmd+=" -not -path '*/node_modules/*'"
    find_cmd+=" -not -path '*/__pycache__/*'"
    find_cmd+=" -not -name '*.pyc'"
    find_cmd+=" -not -name '*.log'"
    find_cmd+=" -not -name '*.tmp'"
    find_cmd+=" -not -name '.DS_Store'"
    # Include parallel subtask files explicitly
    # Note: subtasks directory should be included by default
    
    # Add custom exclusions
    if [ -n "$exclude_patterns" ]; then
        while IFS= read -r pattern; do
            find_cmd+=" -not -path '$pattern'"
        done <<< "$exclude_patterns"
    fi
    
    # Process directories first
    while IFS= read -r dir; do
        if [ "$dir" = "$directory" ]; then
            continue
        fi
        
        local relative_path="${dir#$base_dir/}"
        local metadata=$(get_file_metadata "$dir" "$relative_path")
        
        if [ -n "$metadata" ]; then
            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                entries+=","
            fi
            entries+=$'\n'"  $metadata"
            ((DIRS_TRACKED++))
            
            # Show progress
            if [ $((DIRS_TRACKED % 100)) -eq 0 ]; then
                log_debug "Processed $DIRS_TRACKED directories..." "SCAN"
            fi
        fi
    done < <(eval "$find_cmd -type d" | sort)
    
    # Process files
    while IFS= read -r file; do
        local relative_path="${file#$base_dir/}"
        local metadata=$(get_file_metadata "$file" "$relative_path")
        
        if [ -n "$metadata" ]; then
            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                entries+=","
            fi
            entries+=$'\n'"  $metadata"
            ((FILES_TRACKED++))
            
            # Show progress
            if [ $((FILES_TRACKED % 100)) -eq 0 ]; then
                log_debug "Processed $FILES_TRACKED files..." "SCAN"
            fi
        fi
    done < <(eval "$find_cmd -type f" | sort)
    
    echo "$entries"
}

# Create installation manifest
create_manifest() {
    local scan_dir="${1:-$PROJECT_ROOT}"
    local output_file="${2:-$MANIFEST_FILE}"
    local exclude_patterns="${3:-}"
    
    log_info "Creating installation manifest" "CREATE"
    start_timer "create_manifest"
    
    # Reset counters
    FILES_TRACKED=0
    DIRS_TRACKED=0
    TOTAL_SIZE=0
    
    # Get installation metadata
    local install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local username=$(whoami 2>/dev/null || echo "unknown")
    local os_info=$(uname -a 2>/dev/null || echo "unknown")
    
    # Load project info if available
    local project_name="Unknown Project"
    local project_version="1.0.0"
    local installer_version="${INSTALLER_VERSION:-unknown}"
    
    if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
        project_name=$(jq -r '.PROJECT_NAME // "Unknown Project"' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null || echo "Unknown Project")
    fi
    
    log_info "Scanning installation directory..." "CREATE"
    
    # Start building manifest
    local manifest='{'
    manifest+=$'\n'"  \"manifest_version\": \"$GENERATOR_VERSION\","
    manifest+=$'\n'"  \"creation_date\": \"$install_date\","
    manifest+=$'\n'"  \"project\": {"
    manifest+=$'\n'"    \"name\": \"$project_name\","
    manifest+=$'\n'"    \"version\": \"$project_version\","
    manifest+=$'\n'"    \"root\": \"$scan_dir\""
    manifest+=$'\n'"  },"
    manifest+=$'\n'"  \"installation\": {"
    manifest+=$'\n'"    \"installer_version\": \"$installer_version\","
    manifest+=$'\n'"    \"date\": \"$install_date\","
    manifest+=$'\n'"    \"hostname\": \"$hostname\","
    manifest+=$'\n'"    \"username\": \"$username\","
    manifest+=$'\n'"    \"os\": \"$os_info\""
    manifest+=$'\n'"  },"
    
    # Add configuration snapshot
    manifest+=$'\n'"  \"configuration\": {"
    
    if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
        manifest+=$'\n'"    \"settings\": "
        manifest+=$(jq -c '.' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null | sed 's/^/    /')
    else
        manifest+=$'\n'"    \"settings\": {}"
    fi
    
    manifest+=$'\n'"  },"
    
    # Scan files and directories
    manifest+=$'\n'"  \"files\": ["
    
    local file_entries=$(scan_directory "$scan_dir" "$scan_dir" "$exclude_patterns")
    manifest+="$file_entries"
    
    manifest+=$'\n'"  ],"
    
    # Add summary
    manifest+=$'\n'"  \"summary\": {"
    manifest+=$'\n'"    \"total_files\": '$FILES_TRACKED','
    manifest+=$'\n'"    \"total_directories\": '$DIRS_TRACKED','
    manifest+=$'\n'"    \"total_size\": '$TOTAL_SIZE','
    manifest+=$'\n'"    \"checksum_algorithm\": \"sha256\""
    manifest+=$'\n'"  }"
    manifest+=$'\n'"}"
    
    # Write manifest to file
    echo "$manifest" > "$output_file"
    
    # Format JSON if jq is available
    if command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        jq '.' "$output_file" > "$temp_file" 2>/dev/null && mv "$temp_file" "$output_file"
    fi
    
    stop_timer "create_manifest"
    
    log_info "Manifest created: $output_file" "CREATE"
    log_info "Tracked: $FILES_TRACKED files, $DIRS_TRACKED directories, $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "${TOTAL_SIZE} bytes")" "CREATE"
    
    return 0
}

# Update existing manifest
update_manifest() {
    local manifest_file="${1:-$MANIFEST_FILE}"
    local updates_file="${2:-}"
    
    log_info "Updating manifest: $manifest_file" "UPDATE"
    start_timer "update_manifest"
    
    if [ ! -f "$manifest_file" ]; then
        log_error "Manifest file not found: $manifest_file" "UPDATE"
        stop_timer "update_manifest"
        return 1
    fi
    
    # Create backup
    cp "$manifest_file" "${manifest_file}.backup"
    
    # Update timestamp
    local update_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    if command -v jq >/dev/null 2>&1; then
        # Update using jq
        local temp_file=$(mktemp)
        
        jq --arg date "$update_date" \
           '.last_updated = $date' "$manifest_file" > "$temp_file"
        
        # Apply specific updates if provided
        if [ -n "$updates_file" ] && [ -f "$updates_file" ]; then
            jq -s '.[0] * .[1]' "$temp_file" "$updates_file" > "${temp_file}.2"
            mv "${temp_file}.2" "$temp_file"
        fi
        
        mv "$temp_file" "$manifest_file"
    else
        log_warn "jq not available, limited update functionality" "UPDATE"
        # Add update timestamp manually
        sed -i.bak '2i\  "last_updated": "'$update_date'",' "$manifest_file"
    fi
    
    stop_timer "update_manifest"
    
    log_info "Manifest updated successfully" "UPDATE"
    return 0
}

# Verify manifest integrity
verify_manifest_integrity() {
    local manifest_file="${1:-$MANIFEST_FILE}"
    
    log_info "Verifying manifest integrity: $manifest_file" "VERIFY"
    start_timer "verify_manifest"
    
    if [ ! -f "$manifest_file" ]; then
        log_error "Manifest file not found: $manifest_file" "VERIFY"
        stop_timer "verify_manifest"
        return 1
    fi
    
    # Check JSON validity
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$manifest_file" 2>/dev/null; then
            log_error "Invalid JSON in manifest file" "VERIFY"
            stop_timer "verify_manifest"
            return 1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if ! python3 -m json.tool "$manifest_file" >/dev/null 2>&1; then
            log_error "Invalid JSON in manifest file" "VERIFY"
            stop_timer "verify_manifest"
            return 1
        fi
    fi
    
    # Verify required fields
    local required_fields=(
        ".manifest_version"
        ".creation_date"
        ".project"
        ".files"
        ".summary"
    )
    
    for field in "${required_fields[@]}"; do
        if command -v jq >/dev/null 2>&1; then
            if ! jq -e "$field" "$manifest_file" >/dev/null 2>&1; then
                log_error "Missing required field: $field" "VERIFY"
                stop_timer "verify_manifest"
                return 1
            fi
        fi
    done
    
    stop_timer "verify_manifest"
    
    log_info "Manifest integrity verified" "VERIFY"
    return 0
}

# Export manifest to different formats
export_manifest() {
    local manifest_file="${1:-$MANIFEST_FILE}"
    local output_format="${2:-yaml}"
    local output_file="${3:-}"
    
    log_info "Exporting manifest to $output_format format" "EXPORT"
    start_timer "export_manifest"
    
    if [ ! -f "$manifest_file" ]; then
        log_error "Manifest file not found: $manifest_file" "EXPORT"
        stop_timer "export_manifest"
        return 1
    fi
    
    # Determine output file
    if [ -z "$output_file" ]; then
        output_file="${manifest_file%.json}.$output_format"
    fi
    
    case "$output_format" in
        yaml|yml)
            export_to_yaml "$manifest_file" "$output_file"
            ;;
        txt|text)
            export_to_text "$manifest_file" "$output_file"
            ;;
        html)
            export_to_html "$manifest_file" "$output_file"
            ;;
        csv)
            export_to_csv "$manifest_file" "$output_file"
            ;;
        *)
            log_error "Unsupported export format: $output_format" "EXPORT"
            stop_timer "export_manifest"
            return 1
            ;;
    esac
    
    stop_timer "export_manifest"
    
    log_info "Manifest exported to: $output_file" "EXPORT"
    return 0
}

# Export to YAML format
export_to_yaml() {
    local input_file="$1"
    local output_file="$2"
    
    log_debug "Exporting to YAML: $output_file" "EXPORT-YAML"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
import yaml
import sys

with open('$input_file') as f:
    data = json.load(f)

with open('$output_file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False)
" 2>/dev/null || {
            # Fallback without yaml module
            log_warn "Python yaml module not available, using basic conversion" "EXPORT-YAML"
            echo "# Generated from $input_file" > "$output_file"
            echo "# Note: This is a simplified YAML representation" >> "$output_file"
            echo "" >> "$output_file"
            
            jq -r 'to_entries | .[] | "\\(.key): \\(.value)"' "$input_file" >> "$output_file" 2>/dev/null
        }
    else
        log_error "Python not available for YAML export" "EXPORT-YAML"
        return 1
    fi
}

# Export to text format
export_to_text() {
    local input_file="$1"
    local output_file="$2"
    
    log_debug "Exporting to text: $output_file" "EXPORT-TEXT"
    
    {
        echo "AP Mapping Installation Manifest"
        echo "==============================="
        echo ""
        
        if command -v jq >/dev/null 2>&1; then
            echo "Project: $(jq -r '.project.name' "$input_file")"
            echo "Created: $(jq -r '.creation_date' "$input_file")"
            echo "Installer: $(jq -r '.installation.installer_version' "$input_file")"
            echo ""
            echo "Summary:"
            echo "--------"
            echo "Files: $(jq -r '.summary.total_files' "$input_file")"
            echo "Directories: $(jq -r '.summary.total_directories' "$input_file")"
            echo "Total Size: $(jq -r '.summary.total_size' "$input_file" | numfmt --to=iec-i --suffix=B 2>/dev/null || jq -r '.summary.total_size' "$input_file") bytes"
            echo ""
            echo "File List:"
            echo "----------"
            jq -r '.files[] | select(.type == "file") | .path' "$input_file" | sort
        else
            # Basic text export without jq
            grep -E '"path"|"total_files"|"total_directories"' "$input_file" | sed 's/[",]//g' | sed 's/^ *//'
        fi
    } > "$output_file"
}

# Export to HTML format
export_to_html() {
    local input_file="$1"
    local output_file="$2"
    
    log_debug "Exporting to HTML: $output_file" "EXPORT-HTML"
    
    {
        echo '<!DOCTYPE html>'
        echo '<html><head>'
        echo '<title>Installation Manifest</title>'
        echo '<style>'
        echo 'body { font-family: Arial, sans-serif; margin: 20px; }'
        echo 'table { border-collapse: collapse; width: 100%; }'
        echo 'th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }'
        echo 'th { background-color: #f2f2f2; }'
        echo '.summary { background-color: #e7f3ff; padding: 15px; margin-bottom: 20px; }'
        echo '</style>'
        echo '</head><body>'
        echo '<h1>AP Mapping Installation Manifest</h1>'
        
        if command -v jq >/dev/null 2>&1; then
            echo '<div class="summary">'
            echo "<p><strong>Project:</strong> $(jq -r '.project.name' "$input_file")</p>"
            echo "<p><strong>Created:</strong> $(jq -r '.creation_date' "$input_file")</p>"
            echo "<p><strong>Files:</strong> $(jq -r '.summary.total_files' "$input_file")</p>"
            echo "<p><strong>Directories:</strong> $(jq -r '.summary.total_directories' "$input_file")</p>"
            echo "<p><strong>Total Size:</strong> $(jq -r '.summary.total_size' "$input_file" | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "$(jq -r '.summary.total_size' "$input_file") bytes")</p>"
            echo '</div>'
            
            echo '<h2>File List</h2>'
            echo '<table>'
            echo '<tr><th>Path</th><th>Type</th><th>Size</th><th>Permissions</th></tr>'
            
            jq -r '.files[] | "<tr><td>\\(.path)</td><td>\\(.type)</td><td>\\(.size // "N/A")</td><td>\\(.permissions // "N/A")</td></tr>"' "$input_file"
            
            echo '</table>'
        fi
        
        echo '</body></html>'
    } > "$output_file"
}

# Export to CSV format
export_to_csv() {
    local input_file="$1"
    local output_file="$2"
    
    log_debug "Exporting to CSV: $output_file" "EXPORT-CSV"
    
    {
        echo "path,type,size,permissions,checksum"
        
        if command -v jq >/dev/null 2>&1; then
            jq -r '.files[] | [.path, .type, (.size // ""), (.permissions // ""), (.checksum // "")] | @csv' "$input_file"
        else
            # Basic CSV export without jq
            grep -E '"path"' "$input_file" | sed 's/[{}"]//g' | sed 's/,/|/g' | sed 's/|/,/g'
        fi
    } > "$output_file"
}

# Compare two manifests
compare_manifests() {
    local manifest1="$1"
    local manifest2="$2"
    local output_file="${3:-}"
    
    log_info "Comparing manifests" "COMPARE"
    start_timer "compare_manifests"
    
    if [ ! -f "$manifest1" ] || [ ! -f "$manifest2" ]; then
        log_error "One or both manifest files not found" "COMPARE"
        stop_timer "compare_manifests"
        return 1
    fi
    
    local comparison_result=""
    
    if command -v jq >/dev/null 2>&1; then
        # Extract file lists
        local files1=$(mktemp)
        local files2=$(mktemp)
        
        jq -r '.files[] | .path' "$manifest1" | sort > "$files1"
        jq -r '.files[] | .path' "$manifest2" | sort > "$files2"
        
        comparison_result+="Files Added:\n"
        comparison_result+=$(comm -13 "$files1" "$files2" | sed 's/^/  + /')
        comparison_result+="\n\nFiles Removed:\n"
        comparison_result+=$(comm -23 "$files1" "$files2" | sed 's/^/  - /')
        
        # Check for modified files (by checksum if available)
        comparison_result+="\n\nFiles Modified:\n"
        
        while IFS= read -r file; do
            local checksum1=$(jq -r --arg f "$file" '.files[] | select(.path == $f) | .checksum // empty' "$manifest1")
            local checksum2=$(jq -r --arg f "$file" '.files[] | select(.path == $f) | .checksum // empty' "$manifest2")
            
            if [ -n "$checksum1" ] && [ -n "$checksum2" ] && [ "$checksum1" != "$checksum2" ]; then
                comparison_result+="  * $file\n"
            fi
        done < <(comm -12 "$files1" "$files2")
        
        rm -f "$files1" "$files2"
    else
        comparison_result="Comparison requires jq to be installed"
    fi
    
    if [ -n "$output_file" ]; then
        echo -e "$comparison_result" > "$output_file"
        log_info "Comparison saved to: $output_file" "COMPARE"
    else
        echo -e "$comparison_result"
    fi
    
    stop_timer "compare_manifests"
    return 0
}

# Create manifest for specific components
create_component_manifest() {
    local component_name="$1"
    local component_path="$2"
    local output_file="${3:-}"
    
    log_info "Creating component manifest for: $component_name" "COMPONENT"
    start_timer "component_manifest"
    
    if [ -z "$output_file" ]; then
        output_file="$PROJECT_ROOT/.ap-install/component-$component_name-manifest.json"
    fi
    
    # Create minimal manifest for component
    local manifest='{'
    manifest+='"component_name":"'$component_name'",'
    manifest+='"component_path":"'$component_path'",'
    manifest+='"creation_date":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
    manifest+='"files":['
    
    # Scan component files
    local file_entries=$(scan_directory "$component_path" "$component_path")
    manifest+="$file_entries"
    
    manifest+=']}'
    
    echo "$manifest" > "$output_file"
    
    # Format if possible
    if command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        jq '.' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
    fi
    
    stop_timer "component_manifest"
    
    log_info "Component manifest created: $output_file" "COMPONENT"
    return 0
}

# Export functions
export -f init_manifest_generator
export -f create_manifest
export -f update_manifest
export -f verify_manifest_integrity
export -f export_manifest
export -f compare_manifests
export -f create_component_manifest

# Main execution (if run directly)
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Parse command line arguments
    PROJECT_ROOT=""
    MANIFEST_FILE=""
    COMMAND="create"
    OUTPUT_FORMAT="json"
    OUTPUT_FILE=""
    EXCLUDE_PATTERNS=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project-root)
                PROJECT_ROOT="$2"
                shift 2
                ;;
            --manifest)
                MANIFEST_FILE="$2"
                shift 2
                ;;
            --output|-o)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --format|-f)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --exclude)
                EXCLUDE_PATTERNS="$2"
                shift 2
                ;;
            --no-checksums)
                INCLUDE_CHECKSUMS=false
                shift
                ;;
            --no-permissions)
                INCLUDE_PERMISSIONS=false
                shift
                ;;
            --no-timestamps)
                INCLUDE_TIMESTAMPS=false
                shift
                ;;
            create)
                COMMAND="create"
                shift
                ;;
            update)
                COMMAND="update"
                shift
                ;;
            verify)
                COMMAND="verify"
                shift
                ;;
            export)
                COMMAND="export"
                shift
                ;;
            compare)
                COMMAND="compare"
                MANIFEST_FILE="$2"
                MANIFEST2="$3"
                shift 3
                ;;
            -h|--help)
                echo "Usage: $0 [COMMAND] [OPTIONS]"
                echo ""
                echo "Commands:"
                echo "  create              Create new manifest (default)"
                echo "  update             Update existing manifest"
                echo "  verify             Verify manifest integrity"
                echo "  export             Export manifest to different format"
                echo "  compare M1 M2      Compare two manifests"
                echo ""
                echo "Options:"
                echo "  --project-root DIR  Project root directory"
                echo "  --manifest FILE    Manifest file path"
                echo "  --output FILE      Output file path"
                echo "  --format FORMAT    Export format (yaml, text, html, csv)"
                echo "  --exclude PATTERN  Exclude patterns (one per line)"
                echo "  --no-checksums     Skip checksum calculation"
                echo "  --no-permissions   Skip permission tracking"
                echo "  --no-timestamps    Skip timestamp tracking"
                echo "  -h, --help        Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Set defaults
    PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
    
    # Initialize
    init_manifest_generator "$PROJECT_ROOT" "$MANIFEST_FILE"
    
    # Execute command
    case "$COMMAND" in
        create)
            create_manifest "$PROJECT_ROOT" "$OUTPUT_FILE" "$EXCLUDE_PATTERNS"
            ;;
        update)
            update_manifest "$MANIFEST_FILE"
            ;;
        verify)
            verify_manifest_integrity "$MANIFEST_FILE"
            ;;
        export)
            export_manifest "$MANIFEST_FILE" "$OUTPUT_FORMAT" "$OUTPUT_FILE"
            ;;
        compare)
            compare_manifests "$MANIFEST_FILE" "$MANIFEST2" "$OUTPUT_FILE"
            ;;
    esac
fi