#!/bin/bash
#
# AP Mapping Task Extraction Script
# Extracts tasks from story files and adds them to tasks.md
#
# Usage: extract-tasks.sh <story-file>
# Example: extract-tasks.sh STORY-002-design-session-notes-tasks.md

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
TASKS_FILE="${PROJECT_DOCS:-$PROJECT_ROOT/project_documentation}/session-notes/tasks/tasks.md"
STORIES_DIR="${PROJECT_DOCS:-$PROJECT_ROOT/project_documentation}/stories"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <story-file>"
    echo "Extract tasks from a story file and add them to tasks.md"
    echo ""
    echo "Arguments:"
    echo "  story-file    Path to the story markdown file"
    echo ""
    echo "Example:"
    echo "  $0 STORY-002-design-session-notes-tasks.md"
    exit 1
}

# Function to log messages
log() {
    echo -e "${GREEN}[EXTRACT]${NC} $1"
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
if [ $# -ne 1 ]; then
    usage
fi

STORY_FILE="$1"

# Resolve story file path
if [[ "$STORY_FILE" == /* ]]; then
    # Absolute path
    STORY_PATH="$STORY_FILE"
elif [[ -f "$STORIES_DIR/$STORY_FILE" ]]; then
    # Relative to stories directory
    STORY_PATH="$STORIES_DIR/$STORY_FILE"
elif [[ -f "$STORY_FILE" ]]; then
    # Relative to current directory
    STORY_PATH="$STORY_FILE"
else
    error "Story file not found: $STORY_FILE"
    exit 1
fi

# Validate story file exists
if [ ! -f "$STORY_PATH" ]; then
    error "Story file does not exist: $STORY_PATH"
    exit 1
fi

# Validate tasks.md exists
if [ ! -f "$TASKS_FILE" ]; then
    error "Tasks file does not exist: $TASKS_FILE"
    exit 1
fi

log "Extracting tasks from: $(basename "$STORY_PATH")"

# Extract story metadata
STORY_ID=$(grep -m1 "^## Story ID:" "$STORY_PATH" | sed 's/^## Story ID: *//')
EPIC_ID=$(grep -m1 "^## Epic:" "$STORY_PATH" | sed 's/^## Epic: *//' | awk '{print $1}')

if [ -z "$STORY_ID" ] || [ -z "$EPIC_ID" ]; then
    error "Could not extract Story ID or Epic ID from story file"
    exit 1
fi

log "Story: $STORY_ID, Epic: $EPIC_ID"

# Extract epic and story numbers
EPIC_NUM=$(echo "$EPIC_ID" | sed 's/EPIC-//')
STORY_NUM=$(echo "$STORY_ID" | sed 's/STORY-//')

# Get next task ID from tasks.md
NEXT_ID=$(grep "^next-id:" "$TASKS_FILE" | sed 's/^next-id: *//')
if [ -z "$NEXT_ID" ]; then
    error "Could not find next-id in tasks.md"
    exit 1
fi

# Extract sequence number from next ID
NEXT_SEQ=$(echo "$NEXT_ID" | awk -F'-' '{print $NF}')
NEXT_SEQ_NUM=$((10#$NEXT_SEQ))

# Extract task block from story
TASK_BLOCK=$(awk '/<!-- AP-TASKS-START -->/,/<!-- AP-TASKS-END -->/' "$STORY_PATH")

if [ -z "$TASK_BLOCK" ]; then
    warn "No task block found in story file"
    exit 0
fi

# Count tasks in block
TASK_COUNT=$(echo "$TASK_BLOCK" | grep -c "^### \[TASK-")

if [ "$TASK_COUNT" -eq 0 ]; then
    warn "No tasks found in task block"
    exit 0
fi

log "Found $TASK_COUNT tasks to extract"

# Create temporary file for processing
TEMP_FILE=$(mktemp)
TEMP_STORY=$(mktemp)

# Process each task
CURRENT_SEQ=$NEXT_SEQ_NUM
EXTRACTED_COUNT=0
TASK_ID_MAP=""

# Extract and process tasks
echo "$TASK_BLOCK" | awk -v epic="$EPIC_NUM" -v story="$STORY_NUM" -v start_seq="$NEXT_SEQ_NUM" '
BEGIN {
    seq = start_seq
    in_task = 0
    task_count = 0
}

/^### \[TASK-XXX\]/ {
    if (in_task) {
        # Output previous task
        print_task()
    }
    
    # Start new task
    in_task = 1
    task_count++
    
    # Generate task ID (force decimal interpretation)
    epic_num = epic + 0
    story_num = story + 0
    task_id = sprintf("TASK-%03d-%03d-%02d", epic_num, story_num, seq)
    seq++
    
    # Extract title
    match($0, /^### \[TASK-XXX\] (.+)$/, arr)
    title = arr[1]
    
    # Initialize task fields
    type = ""
    priority = ""
    persona = ""
    estimate = ""
    dependencies = ""
    description = ""
    
    # Print mapping for story update
    print "MAP:" task_count ":" task_id > "/dev/stderr"
    
    next
}

/^- \*\*Type\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    type = arr[1]
    next
}

/^- \*\*Priority\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    priority = arr[1]
    next
}

/^- \*\*Persona\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    persona = arr[1]
    next
}

/^- \*\*Estimate\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    estimate = arr[1]
    next
}

/^- \*\*Dependencies\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    dependencies = arr[1]
    next
}

/^- \*\*Description\*\*:/ && in_task {
    match($0, /: (.+)$/, arr)
    description = arr[1]
    next
}

/^### \[TASK-/ && in_task {
    # New task starting, print previous
    print_task()
    in_task = 0
}

/<!-- AP-TASKS-END -->/ && in_task {
    # End of block, print last task
    print_task()
    in_task = 0
}

function print_task() {
    if (title == "") return
    
    # Get current date
    "date +%Y-%m-%d" | getline today
    close("date +%Y-%m-%d")
    
    # Output task in tasks.md format
    print "### [" task_id "] " title
    print "- **Epic**: EPIC-" sprintf("%03d", epic_num)
    print "- **Story**: STORY-" sprintf("%03d", story_num)
    print "- **Type**: " type
    print "- **Status**: pending"
    print "- **Priority**: " priority
    print "- **Persona**: " persona
    print "- **Created**: " today
    print "- **Updated**: " today
    print "- **Estimate**: " estimate
    print "- **Dependencies**: " dependencies
    print "- **Blocks**: none"
    print ""
    print "#### Description"
    print description
    print ""
    print "---"
    print ""
}

END {
    if (in_task) {
        print_task()
    }
}
' > "$TEMP_FILE" 2> >(grep "^MAP:" | sed 's/^MAP://' > "$TEMP_FILE.map")

# Read the ID mappings
TASK_ID_MAP=$(cat "$TEMP_FILE.map")
rm -f "$TEMP_FILE.map"

# Count extracted tasks
EXTRACTED_COUNT=$(grep -c "^### \[TASK-" "$TEMP_FILE" || true)

if [ "$EXTRACTED_COUNT" -eq 0 ]; then
    error "Failed to extract tasks"
    rm -f "$TEMP_FILE"
    exit 1
fi

log "Extracted $EXTRACTED_COUNT tasks"

# Update dependencies with real task IDs
cp "$TEMP_FILE" "$TEMP_FILE.orig"

# Replace temporary task references with real IDs
while IFS=: read -r task_num task_id; do
    # Skip empty lines
    [ -z "$task_num" ] || [ -z "$task_id" ] && continue
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/TASK-$task_num\b/$task_id/g" "$TEMP_FILE"
    else
        sed -i "s/TASK-$task_num\b/$task_id/g" "$TEMP_FILE"
    fi
done <<< "$TASK_ID_MAP"

# Calculate blocks field based on dependencies
# This creates a mapping of which tasks block which other tasks
cp "$TEMP_FILE" "$TEMP_FILE.blocks"
while IFS=: read -r task_num task_id; do
    # Skip empty lines
    [ -z "$task_num" ] || [ -z "$task_id" ] && continue
    
    # Find all tasks that depend on this task_id
    BLOCKED_BY=""
    while IFS=: read -r other_num other_id; do
        [ -z "$other_num" ] || [ -z "$other_id" ] && continue
        if [ "$other_id" != "$task_id" ]; then
            # Check if other_id depends on task_id
            if grep -A20 "### \\[$other_id\\]" "$TEMP_FILE.blocks" | grep -q "\*\*Dependencies\*\*:.*$task_id"; then
                if [ -z "$BLOCKED_BY" ]; then
                    BLOCKED_BY="$other_id"
                else
                    BLOCKED_BY="$BLOCKED_BY, $other_id"
                fi
            fi
        fi
    done <<< "$TASK_ID_MAP"
    
    # Update the blocks field for this task
    if [ -n "$BLOCKED_BY" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/### \[$task_id\]/,/^---$/ s/\*\*Blocks\*\*: none/\*\*Blocks\*\*: $BLOCKED_BY/" "$TEMP_FILE"
        else
            sed -i "/### \[$task_id\]/,/^---$/ s/\*\*Blocks\*\*: none/\*\*Blocks\*\*: $BLOCKED_BY/" "$TEMP_FILE"
        fi
    fi
done <<< "$TASK_ID_MAP"
rm -f "$TEMP_FILE.blocks"

# Backup tasks.md
cp "$TASKS_FILE" "$TASKS_FILE.bak"

# Update metadata in tasks.md
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOTAL_TASKS=$(grep "^total-tasks:" "$TASKS_FILE" | awk '{print $2}')
ACTIVE_TASKS=$(grep "^active-tasks:" "$TASKS_FILE" | awk '{print $2}')
NEW_TOTAL=$((TOTAL_TASKS + EXTRACTED_COUNT))
NEW_ACTIVE=$((ACTIVE_TASKS + EXTRACTED_COUNT))
NEW_NEXT_SEQ=$((CURRENT_SEQ + EXTRACTED_COUNT))
NEW_NEXT_ID=$(printf "TASK-%03d-%03d-%02d" $((10#$EPIC_NUM)) $((10#$STORY_NUM)) "$NEW_NEXT_SEQ")

# Create new tasks.md with updated metadata
{
    # Copy header and update metadata
    awk -v updated="$CURRENT_DATE" -v total="$NEW_TOTAL" -v active="$NEW_ACTIVE" -v nextid="$NEW_NEXT_ID" '
    /^last-updated:/ { print "last-updated: " updated; next }
    /^total-tasks:/ { print "total-tasks: " total; next }
    /^active-tasks:/ { print "active-tasks: " active; next }
    /^next-id:/ { print "next-id: " nextid; next }
    /^## Completed Tasks/ { exit }
    { print }
    ' "$TASKS_FILE"
    
    # Append new tasks
    cat "$TEMP_FILE"
    
    # Copy the rest of the file
    awk '/^## Completed Tasks/,0' "$TASKS_FILE"
} > "$TASKS_FILE.new"

# Move new file into place
mv "$TASKS_FILE.new" "$TASKS_FILE"

log "Updated tasks.md with $EXTRACTED_COUNT new tasks"

# Update story file with real task IDs
cp "$STORY_PATH" "$TEMP_STORY"

# Replace each TASK-XXX with the real ID
# First occurrence gets first ID, second gets second ID, etc.
cp "$TEMP_STORY" "$TEMP_STORY.work"
while IFS=: read -r num task_id; do
    # Replace only the first occurrence of [TASK-XXX]
    awk -v id="$task_id" '
        !replaced && /\[TASK-XXX\]/ {
            sub(/\[TASK-XXX\]/, "[" id "]")
            replaced = 1
        }
        { print }
    ' "$TEMP_STORY.work" > "$TEMP_STORY.new"
    mv "$TEMP_STORY.new" "$TEMP_STORY.work"
done <<< "$TASK_ID_MAP"
mv "$TEMP_STORY.work" "$TEMP_STORY"

# Move updated story file into place
mv "$TEMP_STORY" "$STORY_PATH"

log "Updated story file with assigned task IDs"

# Clean up
rm -f "$TEMP_FILE" "$TEMP_FILE.orig"

# Summary
echo ""
log "Task extraction complete!"
echo -e "${GREEN}Summary:${NC}"
echo "  - Extracted: $EXTRACTED_COUNT tasks"
echo "  - Task IDs: $(echo "$TASK_ID_MAP" | awk -F: '{print $2}' | head -1) to $(echo "$TASK_ID_MAP" | awk -F: '{print $2}' | tail -1)"
echo "  - Updated: tasks.md and $(basename "$STORY_PATH")"
echo ""
echo "Next steps:"
echo "  1. Review the extracted tasks in $TASKS_FILE"
echo "  2. Commit both files: git add tasks.md \"$STORY_PATH\""
echo "  3. Start working on the first task"