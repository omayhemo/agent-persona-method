#!/bin/bash
#
# AP Mapping Task Query Functions
# Provides grep-based queries for filtering tasks in tasks.md
#
# Usage: query-tasks.sh <command> [options]
# Commands:
#   status <status>     - Find tasks by status (pending, in-progress, blocked, review, completed)
#   epic <epic-id>      - Find tasks by epic (e.g., EPIC-001)
#   story <story-id>    - Find tasks by story (e.g., STORY-002)
#   persona <persona>   - Find tasks by assigned persona
#   priority <level>    - Find tasks by priority (high, medium, low)
#   type <type>        - Find tasks by type (development, testing, documentation, etc.)
#   blocked            - Find all blocked tasks
#   ready              - Find tasks ready to start (no blocking dependencies)
#   overdue <date>     - Find tasks past their estimate
#   today              - Find tasks started or completed today
#   search <pattern>   - Search task titles and descriptions
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
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status <status>     Find tasks by status (pending, in-progress, blocked, review, completed)"
    echo "  epic <epic-id>      Find tasks by epic (e.g., EPIC-001)"
    echo "  story <story-id>    Find tasks by story (e.g., STORY-002)"
    echo "  persona <persona>   Find tasks by assigned persona"
    echo "  priority <level>    Find tasks by priority (high, medium, low)"
    echo "  type <type>        Find tasks by type (development, testing, documentation)"
    echo "  blocked            Find all blocked tasks"
    echo "  ready              Find tasks ready to start (no blocking dependencies)"
    echo "  overdue <date>     Find tasks past their estimate"
    echo "  today              Find tasks started or completed today"
    echo "  search <pattern>   Search task titles and descriptions"
    echo "  count <field>      Count tasks by field (status, epic, story, persona, priority, type)"
    echo ""
    echo "Options:"
    echo "  --format <fmt>     Output format: full (default), summary, id, count"
    echo "  --no-color         Disable colored output"
    echo ""
    echo "Examples:"
    echo "  $0 status pending"
    echo "  $0 epic EPIC-001 --format summary"
    echo "  $0 persona developer"
    echo "  $0 blocked"
    echo "  $0 search 'unit test' --format id"
    exit 1
}

# Initialize variables
FORMAT="full"
USE_COLOR=true
COMMAND=""
ARGS=()

# First pass: extract command and options
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --no-color)
            USE_COLOR=false
            shift
            ;;
        *)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            else
                ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# Disable colors if requested
if [ "$USE_COLOR" = false ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    NC=""
fi

# Validate tasks file exists
if [ ! -f "$TASKS_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Tasks file not found: $TASKS_FILE" >&2
    exit 1
fi

# Validate command
if [ -z "$COMMAND" ]; then
    usage
fi

# Function to extract task block
extract_task_block() {
    local task_id="$1"
    awk -v id="$task_id" '
        /^### \[/ {
            if (match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)) {
                if (arr[1] == id) {
                    in_task = 1
                } else if (in_task) {
                    exit
                }
            }
        }
        in_task { print }
        /^---$/ && in_task { exit }
    ' "$TASKS_FILE"
}

# Function to format output
format_output() {
    local format="$1"
    local input="$(cat)"
    
    # If no input, handle count format specially
    if [ -z "$input" ]; then
        case "$format" in
            count) echo "0" ;;
            *) ;;
        esac
        return
    fi
    
    case "$format" in
        full)
            echo "$input"
            ;;
        summary)
            echo "$input" | awk '
                /^### \[/ {
                    match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\](.*)/, arr)
                    id = arr[1]
                    title = arr[2]
                    gsub(/^ +| +$/, "", title)
                }
                /^\- \*\*Status\*\*:/ { match($0, /: (.+)$/, arr); status = arr[1] }
                /^\- \*\*Persona\*\*:/ { match($0, /: (.+)$/, arr); persona = arr[1] }
                /^\- \*\*Priority\*\*:/ { match($0, /: (.+)$/, arr); priority = arr[1] }
                /^---$/ && id {
                    printf "[%s] %-50s %s/%s/%s\n", id, substr(title, 0, 50), status, persona, priority
                    id = ""
                }
            '
            ;;
        id)
            echo "$input" | grep "^### \[TASK-" | sed 's/^### \[\(TASK-[0-9]\+-[0-9]\+-[0-9]\+\)\].*/\1/'
            ;;
        count)
            echo "$input" | grep -c "^### \[TASK-" || echo "0"
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown format: $format" >&2
            exit 1
            ;;
    esac
}

# Function to find tasks by field value
find_by_field() {
    local field="$1"
    local value="$2"
    
    # Use AWK to properly extract tasks matching the field
    awk -v field="$field" -v value="$value" '
    BEGIN {
        in_task = 0
        task_block = ""
        matches = 0
    }
    
    /^### \[TASK-/ {
        if (in_task && matches) {
            print task_block
        }
        in_task = 1
        task_block = $0 "\n"
        matches = 0
        next
    }
    
    in_task && match($0, "^- \\*\\*" field "\\*\\*: " value "$") {
        matches = 1
    }
    
    in_task && /^---$/ {
        if (matches) {
            print task_block $0
        }
        in_task = 0
        task_block = ""
        matches = 0
        next
    }
    
    in_task {
        task_block = task_block $0 "\n"
    }
    
    END {
        if (in_task && matches) {
            print task_block
        }
    }
    ' "$TASKS_FILE"
}

# Function to count tasks by field
count_by_field() {
    local field="$1"
    echo -e "${BLUE}Task count by $field:${NC}"
    
    case "$field" in
        status)
            for status in pending in-progress blocked review completed cancelled; do
                count=$(grep -c "^- \\*\\*Status\\*\\*: $status" "$TASKS_FILE" 2>/dev/null || true)
                [ -z "$count" ] && count=0
                printf "  %-15s: %3d\n" "$status" "$count"
            done
            ;;
        epic)
            grep "^- \\*\\*Epic\\*\\*:" "$TASKS_FILE" | sed 's/^- \*\*Epic\*\*: //' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
            ;;
        story)
            grep "^- \\*\\*Story\\*\\*:" "$TASKS_FILE" | sed 's/^- \*\*Story\*\*: //' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
            ;;
        persona)
            grep "^- \\*\\*Persona\\*\\*:" "$TASKS_FILE" | sed 's/^- \*\*Persona\*\*: //' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
            ;;
        priority)
            for priority in high medium low; do
                count=$(grep -c "^- \\*\\*Priority\\*\\*: $priority" "$TASKS_FILE" || echo "0")
                printf "  %-15s: %3d\n" "$priority" "$count"
            done
            ;;
        type)
            grep "^- \\*\\*Type\\*\\*:" "$TASKS_FILE" | sed 's/^- \*\*Type\*\*: //' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown field: $field" >&2
            exit 1
            ;;
    esac
}

# Main command processing
case "$COMMAND" in
    status)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 status <status>" >&2
            exit 1
        fi
        find_by_field "Status" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    epic)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 epic <epic-id>" >&2
            exit 1
        fi
        find_by_field "Epic" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    story)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 story <story-id>" >&2
            exit 1
        fi
        find_by_field "Story" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    persona)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 persona <persona>" >&2
            exit 1
        fi
        find_by_field "Persona" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    priority)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 priority <level>" >&2
            exit 1
        fi
        find_by_field "Priority" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    type)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 type <type>" >&2
            exit 1
        fi
        find_by_field "Type" "${ARGS[0]}" | format_output "$FORMAT"
        ;;
        
    blocked)
        # Find tasks with status = blocked OR tasks with unmet dependencies
        # Use a temporary file to collect unique task IDs first
        TEMP_BLOCKED=$(mktemp)
        
        # Tasks explicitly marked as blocked
        grep -B20 "^- \*\*Status\*\*: blocked" "$TASKS_FILE" | grep "^### \[TASK-" | sed 's/^### \[\(TASK-[0-9]\+-[0-9]\+-[0-9]\+\)\].*/\1/' >> "$TEMP_BLOCKED"
        
        # Tasks with dependencies on incomplete tasks
        grep -A20 "^### \[TASK-" "$TASKS_FILE" | awk '
            /^### \[/ {
                match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)
                current_task = arr[1]
                in_task = 1
                has_deps = 0
                deps = ""
            }
            /^\- \*\*Dependencies\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                if (arr[1] != "none") {
                    has_deps = 1
                    deps = arr[1]
                }
            }
            /^---$/ && in_task {
                if (has_deps) {
                    print current_task ":" deps
                }
                in_task = 0
            }
        ' | while IFS=: read -r task_id deps; do
            # Skip empty lines
            [ -z "$task_id" ] && continue
            
            # Check if any dependency is not completed
            blocked=false
            for dep in $(echo "$deps" | tr ',' ' '); do
                dep=$(echo "$dep" | xargs)  # trim whitespace
                [ -z "$dep" ] && continue
                if ! grep -A5 "^### \[$dep\]" "$TASKS_FILE" | grep -q "^- \*\*Status\*\*: completed"; then
                    blocked=true
                    break
                fi
            done
            if [ "$blocked" = true ]; then
                echo "$task_id" >> "$TEMP_BLOCKED"
            fi
        done
        
        # Get unique task IDs and extract their blocks
        if [ -s "$TEMP_BLOCKED" ]; then
            sort -u "$TEMP_BLOCKED" | while read -r task_id; do
                extract_task_block "$task_id"
            done | format_output "$FORMAT"
        else
            # No blocked tasks - handle format
            case "$FORMAT" in
                count) echo "0" ;;
                *) ;;
            esac
        fi
        
        rm -f "$TEMP_BLOCKED"
        ;;
        
    ready)
        # Find tasks with status=pending and all dependencies completed
        grep -A20 "^### \[TASK-" "$TASKS_FILE" | awk '
            /^### \[/ {
                match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)
                current_task = arr[1]
                in_task = 1
                status = ""
                deps = ""
            }
            /^\- \*\*Status\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                status = arr[1]
            }
            /^\- \*\*Dependencies\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                deps = arr[1]
            }
            /^---$/ && in_task {
                if (status == "pending") {
                    print current_task ":" deps
                }
                in_task = 0
            }
        ' | while IFS=: read -r task_id deps; do
            # Check if all dependencies are completed
            ready=true
            if [ "$deps" != "none" ] && [ -n "$deps" ]; then
                for dep in $(echo "$deps" | tr ',' ' '); do
                    dep=$(echo "$dep" | xargs)  # trim whitespace
                    if ! grep -A5 "^### \[$dep\]" "$TASKS_FILE" | grep -q "^- \\*\\*Status\\*\\*: completed"; then
                        ready=false
                        break
                    fi
                done
            fi
            if [ "$ready" = true ]; then
                extract_task_block "$task_id"
            fi
        done | format_output "$FORMAT"
        ;;
        
    overdue)
        if [ ${#ARGS[@]} -eq 0 ]; then
            TODAY=$(date +%Y-%m-%d)
        else
            TODAY="${ARGS[0]}"
        fi
        
        # Find tasks that are in-progress and started before the given date
        grep -A20 "^### \[TASK-" "$TASKS_FILE" | awk -v today="$TODAY" '
            /^### \[/ {
                match($0, /\[(TASK-[0-9]+-[0-9]+-[0-9]+)\]/, arr)
                current_task = arr[1]
                in_task = 1
                status = ""
                started = ""
                estimate = ""
            }
            /^\- \*\*Status\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                status = arr[1]
            }
            /^\- \*\*Started\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                started = arr[1]
            }
            /^\- \*\*Estimate\*\*:/ && in_task {
                match($0, /: (.+)$/, arr)
                estimate = arr[1]
            }
            /^---$/ && in_task {
                if (status == "in-progress" && started < today) {
                    print current_task
                }
                in_task = 0
            }
        ' | while read -r task_id; do
            extract_task_block "$task_id"
        done | format_output "$FORMAT"
        ;;
        
    today)
        TODAY=$(date +%Y-%m-%d)
        
        # Find tasks started or completed today
        grep -B5 -A15 "\\(Started\\|Completed\\): $TODAY" "$TASKS_FILE" | grep -A20 "^### \[TASK-" | awk '
            BEGIN { RS = "---" }
            /^### \[/ { print $0 "---" }
        ' | format_output "$FORMAT"
        ;;
        
    search)
        if [ ${#ARGS[@]} -eq 0 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 search <pattern>" >&2
            exit 1
        fi
        PATTERN="${ARGS[*]}"
        
        # Search in task titles and descriptions
        grep -A30 "^### \[TASK-" "$TASKS_FILE" | awk -v pattern="$PATTERN" '
            BEGIN { IGNORECASE = 1 }
            /^### \[/ {
                in_task = 1
                task_block = $0 "\n"
                found = 0
                if ($0 ~ pattern) found = 1
            }
            in_task && !/^### \[/ {
                task_block = task_block $0 "\n"
                if ($0 ~ pattern) found = 1
            }
            /^---$/ && in_task {
                if (found) {
                    printf "%s", task_block
                }
                in_task = 0
            }
        ' | format_output "$FORMAT"
        ;;
        
    count)
        if [ ${#ARGS[@]} -ne 1 ]; then
            echo -e "${RED}[ERROR]${NC} Usage: $0 count <field>" >&2
            exit 1
        fi
        count_by_field "${ARGS[0]}"
        ;;
        
    *)
        echo -e "${RED}[ERROR]${NC} Unknown command: $COMMAND" >&2
        usage
        ;;
esac