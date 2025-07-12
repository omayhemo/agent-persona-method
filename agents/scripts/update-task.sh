#!/bin/bash
#
# AP Mapping Task Update Script
# Updates task fields in tasks.md
#
# Usage: update-task.sh <task-id> <field> <value>
# Examples:
#   update-task.sh TASK-001-002-01 status completed
#   update-task.sh TASK-001-002-01 actual 2.5h
#   update-task.sh TASK-001-002-01 notes "Added new feature"
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
TASKS_FILE="${PROJECT_DOCS:-$PROJECT_ROOT/project_documentation}/session-notes/tasks/tasks.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <task-id> <field> <value>"
    echo ""
    echo "Updates a task field in tasks.md"
    echo ""
    echo "Arguments:"
    echo "  task-id    Task identifier (e.g., TASK-001-002-01)"
    echo "  field      Field to update (see below)"
    echo "  value      New value for the field"
    echo ""
    echo "Updateable fields:"
    echo "  status     - pending, in-progress, blocked, review, completed, cancelled"
    echo "  priority   - high, medium, low"
    echo "  persona    - developer, qa, architect, etc."
    echo "  estimate   - Time estimate (e.g., 2h, 1.5h)"
    echo "  actual     - Actual time spent"
    echo "  notes      - Task notes (appends to existing)"
    echo ""
    echo "Special updates:"
    echo "  start      - Mark task as started (sets status=in-progress, started=now)"
    echo "  complete   - Mark task as completed (sets status=completed, completed=now)"
    echo "  block      - Mark task as blocked (sets status=blocked)"
    echo "  unblock    - Unblock task (sets status=pending or in-progress)"
    echo ""
    echo "Examples:"
    echo "  $0 TASK-001-002-01 status completed"
    echo "  $0 TASK-001-002-01 actual 2.5h"
    echo "  $0 TASK-001-002-01 start"
    echo "  $0 TASK-001-002-01 notes \"Fixed bug in query logic\""
    exit 1
}

# Function to log messages
log() {
    echo -e "${GREEN}[UPDATE]${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Validate arguments
if [ $# -lt 2 ]; then
    usage
fi

TASK_ID="$1"
FIELD="$2"
VALUE="${3:-}"

# Validate task ID format
if ! [[ "$TASK_ID" =~ ^TASK-[0-9]{3}-[0-9]{3}-[0-9]{2}$ ]]; then
    error "Invalid task ID format: $TASK_ID"
    error "Expected format: TASK-XXX-XXX-XX"
    exit 1
fi

# Validate tasks file exists
if [ ! -f "$TASKS_FILE" ]; then
    error "Tasks file not found: $TASKS_FILE"
    exit 1
fi

# Check if task exists
if ! grep -q "^### \[$TASK_ID\]" "$TASKS_FILE"; then
    error "Task not found: $TASK_ID"
    exit 1
fi

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TODAY=$(date +"%Y-%m-%d")
NOW_TIME=$(date +"%Y-%m-%d %H:%M")

# Create backup
cp "$TASKS_FILE" "$TASKS_FILE.bak"

# Function to update a simple field
update_field() {
    local task_id="$1"
    local field="$2"
    local value="$3"
    
    # Create temporary file
    TEMP_FILE=$(mktemp)
    
    awk -v id="$task_id" -v field="$field" -v value="$value" -v timestamp="$TIMESTAMP" '
        BEGIN { in_task = 0; updated = 0 }
        
        /^### \[/ {
            if (match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)) {
                if (arr[1] == id) {
                    in_task = 1
                } else {
                    in_task = 0
                }
            }
        }
        
        in_task && /^- \*\*'"$field"'\*\*:/ {
            print "- **" field "**: " value
            updated = 1
            next
        }
        
        in_task && /^- \*\*Updated\*\*:/ {
            print "- **Updated**: " timestamp
            next
        }
        
        { print }
        
    ' "$TASKS_FILE" > "$TEMP_FILE"
    
    # Check if field was updated
    if grep -q "^- \*\*$field\*\*:" "$TEMP_FILE"; then
        mv "$TEMP_FILE" "$TASKS_FILE"
        return 0
    else
        rm -f "$TEMP_FILE"
        return 1
    fi
}

# Function to add a new field
add_field() {
    local task_id="$1"
    local field="$2"
    local value="$3"
    local after_field="$4"
    
    TEMP_FILE=$(mktemp)
    
    awk -v id="$task_id" -v field="$field" -v value="$value" -v after="$after_field" '
        BEGIN { in_task = 0; added = 0 }
        
        /^### \[/ {
            if (match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)) {
                if (arr[1] == id) {
                    in_task = 1
                } else {
                    in_task = 0
                }
            }
        }
        
        { print }
        
        in_task && !added && /^- \*\*'"$after_field"'\*\*:/ {
            print "- **" field "**: " value
            added = 1
        }
        
    ' "$TASKS_FILE" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$TASKS_FILE"
}

# Function to update task metadata
update_metadata() {
    local action="$1"
    
    case "$action" in
        complete)
            # Decrement active tasks, increment completed today
            awk '
                /^active-tasks:/ { 
                    match($0, /: ([0-9]+)/, arr)
                    print "active-tasks: " (arr[1] - 1)
                    next
                }
                /^completed-today:/ {
                    match($0, /: ([0-9]+)/, arr)
                    print "completed-today: " (arr[1] + 1)
                    next
                }
                /^last-updated:/ {
                    print "last-updated: " timestamp
                    next
                }
                { print }
            ' timestamp="$TIMESTAMP" "$TASKS_FILE" > "$TASKS_FILE.tmp"
            mv "$TASKS_FILE.tmp" "$TASKS_FILE"
            ;;
            
        start)
            # Just update last-updated
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^last-updated:.*/last-updated: $TIMESTAMP/" "$TASKS_FILE"
            else
                sed -i "s/^last-updated:.*/last-updated: $TIMESTAMP/" "$TASKS_FILE"
            fi
            ;;
    esac
}

# Function to append to notes
append_notes() {
    local task_id="$1"
    local new_note="$2"
    
    TEMP_FILE=$(mktemp)
    
    awk -v id="$task_id" -v note="$new_note" -v date="$TODAY" '
        BEGIN { in_task = 0; in_notes = 0; has_notes = 0 }
        
        /^### \[/ {
            if (match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)) {
                if (arr[1] == id) {
                    in_task = 1
                } else {
                    if (in_task && !has_notes) {
                        # Add notes section before next task
                        print "#### Notes"
                        print date ": " note
                        print ""
                    }
                    in_task = 0
                    in_notes = 0
                }
            }
        }
        
        /^#### Notes/ && in_task {
            has_notes = 1
            in_notes = 1
            print
            next
        }
        
        /^---$/ && in_task {
            if (!has_notes) {
                # Add notes section before separator
                print "#### Notes"
                print date ": " note
                print ""
            } else if (in_notes) {
                # Append to existing notes
                print date ": " note
                print ""
            }
            in_task = 0
            in_notes = 0
        }
        
        { print }
        
    ' "$TASKS_FILE" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$TASKS_FILE"
}

# Process the update based on field
case "$FIELD" in
    status)
        if [ -z "$VALUE" ]; then
            error "Status value required"
            exit 1
        fi
        
        # Validate status value
        case "$VALUE" in
            pending|in-progress|blocked|review|completed|cancelled)
                log "Updating status to: $VALUE"
                update_field "$TASK_ID" "Status" "$VALUE"
                
                # Update metadata for completed tasks
                if [ "$VALUE" = "completed" ]; then
                    update_metadata complete
                fi
                ;;
            *)
                error "Invalid status: $VALUE"
                error "Valid values: pending, in-progress, blocked, review, completed, cancelled"
                exit 1
                ;;
        esac
        ;;
        
    priority)
        if [ -z "$VALUE" ]; then
            error "Priority value required"
            exit 1
        fi
        
        # Validate priority value
        case "$VALUE" in
            high|medium|low)
                log "Updating priority to: $VALUE"
                update_field "$TASK_ID" "Priority" "$VALUE"
                ;;
            *)
                error "Invalid priority: $VALUE"
                error "Valid values: high, medium, low"
                exit 1
                ;;
        esac
        ;;
        
    persona)
        if [ -z "$VALUE" ]; then
            error "Persona value required"
            exit 1
        fi
        
        log "Updating persona to: $VALUE"
        update_field "$TASK_ID" "Persona" "$VALUE"
        ;;
        
    estimate)
        if [ -z "$VALUE" ]; then
            error "Estimate value required"
            exit 1
        fi
        
        log "Updating estimate to: $VALUE"
        update_field "$TASK_ID" "Estimate" "$VALUE"
        ;;
        
    actual)
        if [ -z "$VALUE" ]; then
            error "Actual time value required"
            exit 1
        fi
        
        log "Updating actual time to: $VALUE"
        
        # Check if Actual field exists
        if grep -A20 "^### \[$TASK_ID\]" "$TASKS_FILE" | grep -q "^- \*\*Actual\*\*:"; then
            update_field "$TASK_ID" "Actual" "$VALUE"
        else
            # Add Actual field after Estimate
            add_field "$TASK_ID" "Actual" "$VALUE" "Estimate"
        fi
        ;;
        
    notes)
        if [ -z "$VALUE" ]; then
            error "Notes value required"
            exit 1
        fi
        
        log "Appending note to task"
        append_notes "$TASK_ID" "$VALUE"
        ;;
        
    start)
        log "Starting task $TASK_ID"
        
        # Update status to in-progress
        update_field "$TASK_ID" "Status" "in-progress"
        
        # Add Started field if not exists
        if ! grep -A20 "^### \[$TASK_ID\]" "$TASKS_FILE" | grep -q "^- \*\*Started\*\*:"; then
            add_field "$TASK_ID" "Started" "$NOW_TIME" "Updated"
        else
            update_field "$TASK_ID" "Started" "$NOW_TIME"
        fi
        
        update_metadata start
        log "Task started at $NOW_TIME"
        ;;
        
    complete)
        log "Completing task $TASK_ID"
        
        # Update status to completed
        update_field "$TASK_ID" "Status" "completed"
        
        # Add Completed field if not exists
        if ! grep -A20 "^### \[$TASK_ID\]" "$TASKS_FILE" | grep -q "^- \*\*Completed\*\*:"; then
            add_field "$TASK_ID" "Completed" "$NOW_TIME" "Started"
        else
            update_field "$TASK_ID" "Completed" "$NOW_TIME"
        fi
        
        # Calculate actual time if started time exists
        STARTED=$(grep -A20 "^### \[$TASK_ID\]" "$TASKS_FILE" | grep "^- \*\*Started\*\*:" | sed 's/^- \*\*Started\*\*: *//')
        if [ -n "$STARTED" ]; then
            # Simple time calculation (would need more complex logic for accurate hours)
            log "Task completed at $NOW_TIME"
        fi
        
        update_metadata complete
        ;;
        
    block)
        log "Blocking task $TASK_ID"
        update_field "$TASK_ID" "Status" "blocked"
        
        # Optionally add a note about why it's blocked
        if [ -n "$VALUE" ]; then
            append_notes "$TASK_ID" "Blocked: $VALUE"
        fi
        ;;
        
    unblock)
        log "Unblocking task $TASK_ID"
        
        # Check if task has Started field to determine new status
        if grep -A20 "^### \[$TASK_ID\]" "$TASKS_FILE" | grep -q "^- \*\*Started\*\*:"; then
            update_field "$TASK_ID" "Status" "in-progress"
            log "Task unblocked, status set to in-progress"
        else
            update_field "$TASK_ID" "Status" "pending"
            log "Task unblocked, status set to pending"
        fi
        ;;
        
    *)
        error "Unknown field or action: $FIELD"
        echo ""
        usage
        ;;
esac

# Verify update
if [ -f "$TASKS_FILE.bak" ]; then
    if diff -q "$TASKS_FILE" "$TASKS_FILE.bak" > /dev/null; then
        warn "No changes were made"
    else
        log "Task $TASK_ID updated successfully"
        
        # Show what changed
        echo -e "\n${BLUE}Changes made:${NC}"
        diff --color=always -U1 "$TASKS_FILE.bak" "$TASKS_FILE" | grep -E "^[+-]" | grep -v "^[+-]{3}" | head -10 || true
    fi
fi

log "Update complete"