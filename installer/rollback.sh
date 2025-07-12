#!/bin/bash

# AP Mapping Rollback Utility
# Standalone script to rollback AP Mapping installations

set -e

# Configuration
BACKUP_DIR_NAME=".ap-backup"
BACKUP_MANIFEST="manifest.json"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_section() {
    echo ""
    print_color "$BLUE" "=========================================="
    print_color "$BLUE" "$1"
    print_color "$BLUE" "=========================================="
    echo ""
}

# Function to display backup details
display_backup_details() {
    local manifest_file=$1
    
    python3 << EOF
import json
import sys
from datetime import datetime

try:
    with open('$manifest_file', 'r') as f:
        manifest = json.load(f)
    
    print(f"Backup ID: {manifest['backup_id']}")
    print(f"Installer Version: {manifest['installer_version']}")
    print(f"Timestamp: {manifest['timestamp']}")
    print(f"Installation State: {manifest['installation_state']}")
    print(f"Completed: {manifest['completed']}")
    print(f"Rollback Performed: {manifest.get('rollback_performed', False)}")
    
    # Show statistics
    print(f"\nStatistics:")
    print(f"  Files backed up: {len(manifest.get('files_backed_up', []))}")
    print(f"  Files created: {len(manifest.get('files_created', []))}")
    print(f"  Directories created: {len(manifest.get('directories_created', []))}")
    print(f"  Operations performed: {len(manifest.get('operations', []))}")
    
    # Show last few operations
    operations = manifest.get('operations', [])
    if operations:
        print(f"\nLast operations:")
        for op in operations[-5:]:
            print(f"  - {op['operation']}: {op['status']} ({op.get('details', 'No details')})")
    
except Exception as e:
    print(f"Error reading manifest: {e}")
    sys.exit(1)
EOF
}

# Function to list backups with details
list_backups_detailed() {
    local project_root=$1
    local backup_base="$project_root/$BACKUP_DIR_NAME"
    
    if [ ! -d "$backup_base" ]; then
        print_color "$YELLOW" "No backups found in this directory"
        return 1
    fi
    
    print_section "Available Backups"
    
    local backup_count=0
    local backup_dirs=()
    
    # Find and sort backup directories by timestamp
    for backup_dir in "$backup_base"/*; do
        if [ -d "$backup_dir" ] && [ -f "$backup_dir/$BACKUP_MANIFEST" ]; then
            backup_dirs+=("$backup_dir")
        fi
    done
    
    # Sort by directory name (which includes timestamp)
    IFS=$'\n' sorted_dirs=($(sort -r <<<"${backup_dirs[*]}"))
    unset IFS
    
    for backup_dir in "${sorted_dirs[@]}"; do
        ((backup_count++))
        
        echo ""
        print_color "$CYAN" "[$backup_count] $(basename "$backup_dir")"
        echo "    Path: $backup_dir"
        
        # Display details using Python
        python3 << EOF 2>/dev/null || echo "    Error reading manifest"
import json
import os

manifest_file = os.path.join('$backup_dir', '$BACKUP_MANIFEST')
with open(manifest_file, 'r') as f:
    manifest = json.load(f)

print(f"    Date: {manifest['timestamp']}")
print(f"    State: {manifest['installation_state']}")
print(f"    Completed: {manifest['completed']}")
print(f"    Rollback performed: {manifest.get('rollback_performed', False)}")

# Show size of backup
total_size = 0
for root, dirs, files in os.walk('$backup_dir'):
    for f in files:
        fp = os.path.join(root, f)
        if os.path.exists(fp):
            total_size += os.path.getsize(fp)

size_mb = total_size / (1024 * 1024)
print(f"    Backup size: {size_mb:.2f} MB")

# Show file counts
print(f"    Files: {len(manifest.get('files_backed_up', []))} backed up, {len(manifest.get('files_created', []))} created")
EOF
    done
    
    if [ $backup_count -eq 0 ]; then
        print_color "$YELLOW" "No valid backups found"
        return 1
    fi
    
    echo ""
    return 0
}

# Function to perform rollback
perform_rollback() {
    local backup_dir=$1
    local project_root=$2
    local dry_run=${3:-false}
    
    if [ ! -d "$backup_dir" ]; then
        print_color "$RED" "Error: Backup directory not found: $backup_dir"
        return 1
    fi
    
    local manifest_file="$backup_dir/$BACKUP_MANIFEST"
    if [ ! -f "$manifest_file" ]; then
        print_color "$RED" "Error: Manifest file not found in backup"
        return 1
    fi
    
    if [ "$dry_run" = true ]; then
        print_section "Rollback Preview (Dry Run)"
    else
        print_section "Performing Rollback"
    fi
    
    # Show backup details first
    display_backup_details "$manifest_file"
    echo ""
    
    # Perform rollback using Python
    python3 << EOF
import json
import os
import shutil
import sys
from datetime import datetime

manifest_file = "$manifest_file"
backup_dir = "$backup_dir"
project_root = "$project_root"
dry_run = $dry_run

try:
    with open(manifest_file, 'r') as f:
        manifest = json.load(f)
    
    if manifest.get('rollback_performed', False) and not dry_run:
        print("⚠ WARNING: This backup has already been rolled back.")
        response = input("Continue anyway? (y/N): ")
        if response.lower() != 'y':
            print("Rollback cancelled.")
            sys.exit(0)
    
    errors = 0
    warnings = 0
    
    # Step 1: Remove created files
    created_files = manifest.get('files_created', [])
    if created_files:
        print("Step 1: Removing created files...")
        for rel_path in reversed(created_files):
            file_path = os.path.join(project_root, rel_path)
            if os.path.exists(file_path):
                try:
                    if dry_run:
                        print(f"  [DRY RUN] Would remove: {rel_path}")
                    else:
                        os.remove(file_path)
                        print(f"  ✓ Removed: {rel_path}")
                except Exception as e:
                    print(f"  ✗ Failed to remove {rel_path}: {e}")
                    errors += 1
            else:
                print(f"  ⚠ File not found (already removed?): {rel_path}")
                warnings += 1
    
    # Step 2: Restore backed up files
    backed_up_files = manifest.get('files_backed_up', [])
    if backed_up_files:
        print("\nStep 2: Restoring backed up files...")
        for rel_path in backed_up_files:
            backup_file_path = os.path.join(backup_dir, 'files', rel_path)
            restore_path = os.path.join(project_root, rel_path)
            
            if os.path.exists(backup_file_path):
                try:
                    if dry_run:
                        print(f"  [DRY RUN] Would restore: {rel_path}")
                    else:
                        # Ensure directory exists
                        os.makedirs(os.path.dirname(restore_path), exist_ok=True)
                        shutil.copy2(backup_file_path, restore_path)
                        print(f"  ✓ Restored: {rel_path}")
                except Exception as e:
                    print(f"  ✗ Failed to restore {rel_path}: {e}")
                    errors += 1
            else:
                print(f"  ⚠ Backup file not found: {rel_path}")
                warnings += 1
    
    # Step 3: Remove created directories (in reverse order)
    created_dirs = manifest.get('directories_created', [])
    if created_dirs:
        print("\nStep 3: Removing created directories...")
        for rel_path in reversed(created_dirs):
            dir_path = os.path.join(project_root, rel_path)
            if os.path.exists(dir_path):
                try:
                    # Only remove if empty
                    if not os.listdir(dir_path):
                        if dry_run:
                            print(f"  [DRY RUN] Would remove empty directory: {rel_path}")
                        else:
                            os.rmdir(dir_path)
                            print(f"  ✓ Removed empty directory: {rel_path}")
                    else:
                        contents = os.listdir(dir_path)
                        print(f"  ⚠ Directory not empty, skipping: {rel_path} (contains {len(contents)} items)")
                        warnings += 1
                except Exception as e:
                    print(f"  ✗ Failed to remove directory {rel_path}: {e}")
                    errors += 1
    
    # Update manifest to mark rollback as performed (if not dry run)
    if not dry_run:
        manifest['rollback_performed'] = True
        manifest['rollback_timestamp'] = datetime.now().isoformat()
        manifest['rollback_errors'] = errors
        manifest['rollback_warnings'] = warnings
        
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)
    
    # Summary
    print(f"\n{'='*50}")
    if dry_run:
        print("DRY RUN SUMMARY:")
    else:
        print("ROLLBACK SUMMARY:")
    print(f"  Files to remove: {len(created_files)}")
    print(f"  Files to restore: {len(backed_up_files)}")
    print(f"  Directories to remove: {len(created_dirs)}")
    
    if errors > 0 or warnings > 0:
        print(f"\n  Errors: {errors}")
        print(f"  Warnings: {warnings}")
        
        if not dry_run:
            print(f"\n⚠ Rollback completed with {errors} error(s) and {warnings} warning(s)")
    else:
        if dry_run:
            print(f"\n✓ Dry run completed successfully. No issues detected.")
        else:
            print(f"\n✓ Rollback completed successfully!")
    
    sys.exit(0 if errors == 0 else 1)

except Exception as e:
    print(f"✗ Rollback failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF
    
    return $?
}

# Function to clean old backups
clean_old_backups() {
    local project_root=$1
    local keep_count=${2:-5}
    local backup_base="$project_root/$BACKUP_DIR_NAME"
    
    if [ ! -d "$backup_base" ]; then
        print_color "$YELLOW" "No backups found"
        return 0
    fi
    
    print_section "Cleaning Old Backups"
    
    echo "Keeping the $keep_count most recent backups..."
    
    # Get all backup directories sorted by name (timestamp)
    local backup_dirs=()
    for backup_dir in "$backup_base"/*; do
        if [ -d "$backup_dir" ] && [ -f "$backup_dir/$BACKUP_MANIFEST" ]; then
            backup_dirs+=("$backup_dir")
        fi
    done
    
    # Sort in reverse order (newest first)
    IFS=$'\n' sorted_dirs=($(sort -r <<<"${backup_dirs[*]}"))
    unset IFS
    
    # Remove old backups
    local removed_count=0
    local index=0
    
    for backup_dir in "${sorted_dirs[@]}"; do
        ((index++))
        
        if [ $index -gt $keep_count ]; then
            # Check if rollback was performed
            local rollback_performed=$(python3 -c "import json; print(json.load(open('$backup_dir/$BACKUP_MANIFEST')).get('rollback_performed', False))" 2>/dev/null || echo "unknown")
            
            if [ "$rollback_performed" = "True" ]; then
                echo "Keeping $(basename "$backup_dir") (rollback was performed)"
            else
                echo "Removing old backup: $(basename "$backup_dir")"
                rm -rf "$backup_dir"
                ((removed_count++))
            fi
        fi
    done
    
    if [ $removed_count -eq 0 ]; then
        print_color "$GREEN" "No old backups to remove"
    else
        print_color "$GREEN" "Removed $removed_count old backup(s)"
    fi
}

# Main script logic
print_section "AP Mapping Rollback Utility"

# Parse command line arguments
COMMAND=""
PROJECT_ROOT=""
DRY_RUN=false
KEEP_COUNT=5

while [[ $# -gt 0 ]]; do
    case $1 in
        list|rollback|clean|details)
            COMMAND=$1
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --keep|-k)
            KEEP_COUNT=$2
            shift 2
            ;;
        --help|-h)
            print_color "$CYAN" "Usage: $0 [COMMAND] [OPTIONS] [PROJECT_DIR]"
            echo ""
            echo "Commands:"
            echo "  list              List all available backups"
            echo "  rollback          Perform rollback (interactive)"
            echo "  clean             Remove old backups"
            echo "  details           Show detailed backup information"
            echo ""
            echo "Options:"
            echo "  --dry-run, -n     Preview changes without applying them"
            echo "  --keep, -k NUM    Keep NUM most recent backups (default: 5)"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 list                    List backups in current directory"
            echo "  $0 rollback /path/to/proj  Rollback installation interactively"
            echo "  $0 rollback --dry-run      Preview rollback changes"
            echo "  $0 clean --keep 3          Keep only 3 most recent backups"
            exit 0
            ;;
        *)
            PROJECT_ROOT=$1
            shift
            ;;
    esac
done

# Default to current directory if not specified
PROJECT_ROOT="${PROJECT_ROOT:-.}"

# Resolve to absolute path
PROJECT_ROOT="$(cd "$PROJECT_ROOT" 2>/dev/null && pwd)" || {
    print_color "$RED" "Error: Project directory '$PROJECT_ROOT' does not exist"
    exit 1
}

# Default command if none specified
if [ -z "$COMMAND" ]; then
    COMMAND="list"
fi

# Execute command
case $COMMAND in
    list)
        list_backups_detailed "$PROJECT_ROOT"
        ;;
        
    rollback)
        if ! list_backups_detailed "$PROJECT_ROOT"; then
            exit 1
        fi
        
        echo ""
        read -p "Enter backup number to rollback (or 'q' to quit): " BACKUP_CHOICE
        
        if [ "$BACKUP_CHOICE" = "q" ]; then
            exit 0
        fi
        
        # Find the selected backup
        BACKUP_BASE="$PROJECT_ROOT/$BACKUP_DIR_NAME"
        BACKUP_INDEX=0
        SELECTED_BACKUP=""
        
        # Get sorted list again
        backup_dirs=()
        for backup_dir in "$BACKUP_BASE"/*; do
            if [ -d "$backup_dir" ] && [ -f "$backup_dir/$BACKUP_MANIFEST" ]; then
                backup_dirs+=("$backup_dir")
            fi
        done
        
        IFS=$'\n' sorted_dirs=($(sort -r <<<"${backup_dirs[*]}"))
        unset IFS
        
        for backup_dir in "${sorted_dirs[@]}"; do
            ((BACKUP_INDEX++))
            if [ "$BACKUP_INDEX" -eq "$BACKUP_CHOICE" ]; then
                SELECTED_BACKUP="$backup_dir"
                break
            fi
        done
        
        if [ -z "$SELECTED_BACKUP" ]; then
            print_color "$RED" "Invalid backup selection"
            exit 1
        fi
        
        echo ""
        print_color "$CYAN" "Selected backup: $(basename "$SELECTED_BACKUP")"
        
        if [ "$DRY_RUN" = true ]; then
            perform_rollback "$SELECTED_BACKUP" "$PROJECT_ROOT" true
        else
            echo ""
            read -p "Are you sure you want to rollback? This cannot be undone. (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                perform_rollback "$SELECTED_BACKUP" "$PROJECT_ROOT" false
            else
                print_color "$YELLOW" "Rollback cancelled"
            fi
        fi
        ;;
        
    clean)
        clean_old_backups "$PROJECT_ROOT" "$KEEP_COUNT"
        ;;
        
    details)
        if ! list_backups_detailed "$PROJECT_ROOT"; then
            exit 1
        fi
        
        echo ""
        read -p "Enter backup number for details (or 'q' to quit): " BACKUP_CHOICE
        
        if [ "$BACKUP_CHOICE" = "q" ]; then
            exit 0
        fi
        
        # Find the selected backup
        BACKUP_BASE="$PROJECT_ROOT/$BACKUP_DIR_NAME"
        BACKUP_INDEX=0
        SELECTED_BACKUP=""
        
        # Get sorted list again
        backup_dirs=()
        for backup_dir in "$BACKUP_BASE"/*; do
            if [ -d "$backup_dir" ] && [ -f "$backup_dir/$BACKUP_MANIFEST" ]; then
                backup_dirs+=("$backup_dir")
            fi
        done
        
        IFS=$'\n' sorted_dirs=($(sort -r <<<"${backup_dirs[*]}"))
        unset IFS
        
        for backup_dir in "${sorted_dirs[@]}"; do
            ((BACKUP_INDEX++))
            if [ "$BACKUP_INDEX" -eq "$BACKUP_CHOICE" ]; then
                SELECTED_BACKUP="$backup_dir"
                break
            fi
        done
        
        if [ -z "$SELECTED_BACKUP" ]; then
            print_color "$RED" "Invalid backup selection"
            exit 1
        fi
        
        print_section "Backup Details: $(basename "$SELECTED_BACKUP")"
        display_backup_details "$SELECTED_BACKUP/$BACKUP_MANIFEST"
        
        echo ""
        echo "Backup contents:"
        echo "  Files directory: $SELECTED_BACKUP/files/"
        echo "  Manifest: $SELECTED_BACKUP/$BACKUP_MANIFEST"
        
        # Show directory tree if available
        if command -v tree >/dev/null 2>&1; then
            echo ""
            echo "Backup structure:"
            tree -L 3 "$SELECTED_BACKUP"
        fi
        ;;
        
    *)
        print_color "$RED" "Unknown command: $COMMAND"
        echo "Run '$0 --help' for usage information"
        exit 1
        ;;
esac