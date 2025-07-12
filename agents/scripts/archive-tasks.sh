#!/bin/bash
#
# AP Mapping Task Archive Script
# Archives completed tasks to monthly archive files
#
# Usage: archive-tasks.sh [--month YYYY-MM]
# Example: archive-tasks.sh --month 2025-01
#
# Archives all completed tasks to $PROJECT_DOCS/session-notes/tasks/archive/YYYY-MM.md
# If no month specified, archives tasks completed in previous month

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
TASKS_FILE="${PROJECT_DOCS:-$PROJECT_ROOT/project_documentation}/session-notes/tasks/tasks.md"
ARCHIVE_DIR="${PROJECT_DOCS:-$PROJECT_ROOT/project_documentation}/session-notes/tasks/archive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [--month YYYY-MM] [--dry-run]"
    echo ""
    echo "Archives completed tasks to monthly archive files"
    echo ""
    echo "Options:"
    echo "  --month YYYY-MM    Archive tasks completed in specified month (default: previous month)"
    echo "  --dry-run          Show what would be archived without making changes"
    echo "  --all              Archive all completed tasks regardless of completion date"
    echo ""
    echo "Examples:"
    echo "  $0                      # Archive previous month's completed tasks"
    echo "  $0 --month 2025-01      # Archive tasks completed in January 2025"
    echo "  $0 --dry-run            # Preview what would be archived"
    echo "  $0 --all                # Archive all completed tasks"
    exit 1
}

# Function to log messages
log() {
    echo -e "${GREEN}[ARCHIVE]${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Parse arguments
ARCHIVE_MONTH=""
DRY_RUN=false
ARCHIVE_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --month)
            ARCHIVE_MONTH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --all)
            ARCHIVE_ALL=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate tasks file exists
if [ ! -f "$TASKS_FILE" ]; then
    error "Tasks file not found: $TASKS_FILE"
    exit 1
fi

# Determine archive month if not specified
if [ -z "$ARCHIVE_MONTH" ] && [ "$ARCHIVE_ALL" = false ]; then
    # Default to previous month
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        ARCHIVE_MONTH=$(date -v-1m +%Y-%m)
    else
        # GNU date command
        ARCHIVE_MONTH=$(date -d "1 month ago" +%Y-%m)
    fi
fi

# Create archive directory if it doesn't exist
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$ARCHIVE_DIR"
fi

# Determine archive file path
if [ "$ARCHIVE_ALL" = true ]; then
    ARCHIVE_FILE="$ARCHIVE_DIR/all-completed-tasks.md"
    log "Archiving all completed tasks"
else
    ARCHIVE_FILE="$ARCHIVE_DIR/$ARCHIVE_MONTH.md"
    log "Archiving tasks completed in $ARCHIVE_MONTH"
fi

if [ "$DRY_RUN" = true ]; then
    log "DRY RUN MODE - No changes will be made"
fi

# Extract completed tasks
TEMP_TASKS=$(mktemp)
TEMP_ARCHIVE=$(mktemp)
TEMP_REMAINING=$(mktemp)

# Process tasks file to separate completed and remaining tasks
awk -v month="$ARCHIVE_MONTH" -v archive_all="$ARCHIVE_ALL" '
BEGIN {
    in_task = 0
    in_completed_section = 0
    task_block = ""
    is_completed = 0
    completed_date = ""
    tasks_to_archive = 0
    archived_count = 0
}

/^## Completed Tasks/ {
    in_completed_section = 1
    print > remaining_file
    next
}

/^### \[TASK-/ && !in_completed_section {
    # Start of a new task
    if (in_task && task_block != "") {
        # Process previous task
        if (is_completed && should_archive(completed_date, month, archive_all)) {
            print task_block > archive_file
            archived_count++
        } else {
            print task_block > remaining_file
        }
    }
    
    # Reset for new task
    in_task = 1
    task_block = $0 "\n"
    is_completed = 0
    completed_date = ""
    next
}

/^- \*\*Status\*\*: completed/ && in_task {
    is_completed = 1
}

/^- \*\*Completed\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    completed_date = arr[1]
}

/^---$/ && in_task && !in_completed_section {
    # End of task
    task_block = task_block $0 "\n"
    
    # Process the task
    if (is_completed && should_archive(completed_date, month, archive_all)) {
        print task_block > archive_file
        archived_count++
    } else {
        print task_block > remaining_file
    }
    
    in_task = 0
    task_block = ""
    next
}

in_task && !in_completed_section {
    task_block = task_block $0 "\n"
    next
}

# Pass through everything else
{
    print > remaining_file
}

function should_archive(completed_date, target_month, archive_all) {
    if (archive_all == "true") {
        return 1
    }
    
    if (completed_date == "") {
        return 0
    }
    
    # Extract YYYY-MM from completed date
    if (match(completed_date, /^([0-9]{4}-[0-9]{2})/, arr)) {
        completed_month = arr[1]
        return completed_month == target_month
    }
    
    return 0
}

END {
    # Process last task if any
    if (in_task && task_block != "") {
        if (is_completed && should_archive(completed_date, month, archive_all)) {
            print task_block > archive_file
            archived_count++
        } else {
            print task_block > remaining_file
        }
    }
    
    print archived_count > "/dev/stderr"
}
' remaining_file="$TEMP_REMAINING" archive_file="$TEMP_ARCHIVE" "$TASKS_FILE" 2> >(read archived_count; echo "$archived_count" > "$TEMP_TASKS.count")

# Get the count of archived tasks
ARCHIVED_COUNT=$(cat "$TEMP_TASKS.count" 2>/dev/null || echo "0")
rm -f "$TEMP_TASKS.count"

if [ "$ARCHIVED_COUNT" -eq 0 ]; then
    warn "No tasks found to archive"
    rm -f "$TEMP_TASKS" "$TEMP_ARCHIVE" "$TEMP_REMAINING"
    exit 0
fi

log "Found $ARCHIVED_COUNT completed tasks to archive"

# Create or update archive file
if [ "$DRY_RUN" = false ]; then
    if [ -f "$ARCHIVE_FILE" ]; then
        # Append to existing archive
        log "Appending to existing archive: $(basename "$ARCHIVE_FILE")"
        
        # Create temporary file with merged content
        {
            # Copy existing archive without trailing lines
            head -n -2 "$ARCHIVE_FILE" 2>/dev/null || cat "$ARCHIVE_FILE"
            echo ""
            # Add new archived tasks
            cat "$TEMP_ARCHIVE"
        } > "$ARCHIVE_FILE.new"
        
        mv "$ARCHIVE_FILE.new" "$ARCHIVE_FILE"
    else
        # Create new archive file
        log "Creating new archive: $(basename "$ARCHIVE_FILE")"
        
        {
            echo "# Task Archive - ${ARCHIVE_MONTH:-All Completed Tasks}"
            echo ""
            echo "Archived on: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            echo ""
            echo "---"
            echo ""
            cat "$TEMP_ARCHIVE"
        } > "$ARCHIVE_FILE"
    fi
    
    # Update tasks.md with remaining tasks
    # First, update metadata
    CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ACTIVE_TASKS=$(grep -c "^### \[TASK-" "$TEMP_REMAINING" || echo "0")
    TOTAL_TASKS=$(grep "^total-tasks:" "$TASKS_FILE" | awk '{print $2}')
    
    # Create new tasks.md
    {
        # Update metadata
        awk -v updated="$CURRENT_DATE" -v active="$ACTIVE_TASKS" '
        /^last-updated:/ { print "last-updated: " updated; next }
        /^active-tasks:/ { print "active-tasks: " active; next }
        /^## Task ID Format/ { 
            print
            getline
            while (getline && !/^## /) print
            print "## Active Tasks"
            print ""
            # Skip to end of metadata
            exit
        }
        { print }
        ' "$TASKS_FILE"
        
        # Add remaining tasks
        cat "$TEMP_REMAINING"
    } > "$TASKS_FILE.new"
    
    # Backup and replace
    cp "$TASKS_FILE" "$TASKS_FILE.bak"
    mv "$TASKS_FILE.new" "$TASKS_FILE"
    
    log "Archive complete!"
    echo -e "${GREEN}Summary:${NC}"
    echo "  - Archived: $ARCHIVED_COUNT tasks"
    echo "  - Archive file: $ARCHIVE_FILE"
    echo "  - Active tasks remaining: $ACTIVE_TASKS"
    
else
    # Dry run - just show what would happen
    echo -e "\n${BLUE}Tasks that would be archived:${NC}"
    grep "^### \[TASK-" "$TEMP_ARCHIVE" | sed 's/^### /  /'
    
    echo -e "\n${BLUE}Archive would be saved to:${NC} $ARCHIVE_FILE"
fi

# Cleanup
rm -f "$TEMP_TASKS" "$TEMP_ARCHIVE" "$TEMP_REMAINING"

if [ "$DRY_RUN" = false ]; then
    echo ""
    echo "Next steps:"
    echo "  1. Review the archive: less \"$ARCHIVE_FILE\""
    echo "  2. Commit changes: git add \"$TASKS_FILE\" \"$ARCHIVE_FILE\""
fi