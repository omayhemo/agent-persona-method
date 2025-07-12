#!/bin/bash

set -euo pipefail

# Test directory
TEST_DIR="/tmp/ap-archive-debug-$$"
mkdir -p "$TEST_DIR/session-notes/tasks/archive"

# Set environment for test
export PROJECT_DOCS="$TEST_DIR"

echo "Debug test for archive script"
echo "Test directory: $TEST_DIR"
echo ""

# Create test tasks.md
cat > "$TEST_DIR/session-notes/tasks/tasks.md" << 'EOF'
# AP Mapping Tasks

## Metadata
last-updated: 2025-01-01T00:00:00Z
total-tasks: 2
active-tasks: 2
completed-today: 0
next-id: TASK-001-001-03

## Task ID Format
- Pattern: TASK-{EPIC}-{STORY}-{SEQUENCE}
- Example: TASK-001-002-01 (Epic 1, Story 2, Task 1)

## Active Tasks

### [TASK-001-001-01] January Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: completed
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-31
- **Started**: 2025-01-01 10:00
- **Completed**: 2025-01-31 16:00
- **Estimate**: 2h
- **Actual**: 2h
- **Dependencies**: none
- **Blocks**: none

#### Description
January completed task

---

### [TASK-001-001-02] Active Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: in-progress
- **Priority**: low
- **Persona**: developer
- **Created**: 2025-03-01
- **Updated**: 2025-03-01
- **Started**: 2025-03-01 14:00
- **Estimate**: 1h
- **Dependencies**: none
- **Blocks**: none

#### Description
Still active task

---

## Completed Tasks

_Completed tasks will be moved here._

---

## Task States
- **pending** - Not started
- **in-progress** - Currently being worked on  
- **blocked** - Waiting on dependency
- **review** - Completed, awaiting review
- **completed** - Done and verified
- **cancelled** - Will not be completed
EOF

echo "Initial task count:"
echo "  Total tasks: $(grep -c "^### \[TASK-" "$TEST_DIR/session-notes/tasks/tasks.md")"
echo "  Completed tasks: $(grep -c "Status.*completed" "$TEST_DIR/session-notes/tasks/tasks.md")"
echo ""

# Run archive with debug
echo "Running archive for January 2025..."
./archive-tasks.sh --month 2025-01

echo ""
echo "After archive:"
echo "  Tasks in tasks.md: $(grep -c "^### \[TASK-" "$TEST_DIR/session-notes/tasks/tasks.md" || echo "0")"
echo "  Archive exists: $([ -f "$TEST_DIR/session-notes/tasks/archive/2025-01.md" ] && echo "YES" || echo "NO")"

if [ -f "$TEST_DIR/session-notes/tasks/archive/2025-01.md" ]; then
    echo "  Tasks in archive: $(grep -c "^### \[TASK-" "$TEST_DIR/session-notes/tasks/archive/2025-01.md" || echo "0")"
fi

# Cleanup
rm -rf "$TEST_DIR"