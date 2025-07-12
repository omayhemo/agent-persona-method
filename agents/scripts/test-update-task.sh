#!/bin/bash
#
# Test script for task update functionality
# Tests all update commands and edge cases
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/update-task.sh"
QUERY_SCRIPT="$SCRIPT_DIR/query-tasks.sh"
TEST_DIR="/tmp/ap-update-test-$$"

echo -e "${BLUE}[TEST]${NC} Task Update Functions Test Suite"
echo "Update script: $UPDATE_SCRIPT"
echo "Test directory: $TEST_DIR"

# Check scripts exist
if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo -e "${RED}✗${NC} Update script not found"
    exit 1
fi

if [ ! -f "$QUERY_SCRIPT" ]; then
    echo -e "${RED}✗${NC} Query script not found"
    exit 1
fi

# Make executable
chmod +x "$UPDATE_SCRIPT" "$QUERY_SCRIPT"

# Create test environment
mkdir -p "$TEST_DIR/session-notes/tasks"
export PROJECT_DOCS="$TEST_DIR"

# Create test tasks.md with a variety of tasks
cat > "$TEST_DIR/session-notes/tasks/tasks.md" << 'EOF'
# AP Mapping Tasks

## Metadata
last-updated: 2025-01-11T10:00:00Z
total-tasks: 3
active-tasks: 3
completed-today: 0
next-id: TASK-001-001-04

## Task ID Format
- Pattern: TASK-{EPIC}-{STORY}-{SEQUENCE}
- Example: TASK-001-002-01 (Epic 1, Story 2, Task 1)

## Active Tasks

### [TASK-001-001-01] Test Pending Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: pending
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-11
- **Updated**: 2025-01-11
- **Estimate**: 2h
- **Dependencies**: none
- **Blocks**: none

#### Description
A test task in pending status

---

### [TASK-001-001-02] Test In-Progress Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: testing
- **Status**: in-progress
- **Priority**: medium
- **Persona**: qa
- **Created**: 2025-01-11
- **Updated**: 2025-01-11
- **Started**: 2025-01-11 09:00
- **Estimate**: 3h
- **Dependencies**: TASK-001-001-01
- **Blocks**: TASK-001-001-03

#### Description
A test task already in progress

---

### [TASK-001-001-03] Test Blocked Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: documentation
- **Status**: pending
- **Priority**: low
- **Persona**: developer
- **Created**: 2025-01-11
- **Updated**: 2025-01-11
- **Estimate**: 1h
- **Dependencies**: TASK-001-001-02
- **Blocks**: none

#### Description
A test task waiting on dependencies

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

echo -e "\n${BLUE}[TEST]${NC} Running update tests..."

# Test 1: Update status
echo -e "\n${YELLOW}Test 1:${NC} Update status"
if "$UPDATE_SCRIPT" TASK-001-001-01 status in-progress > /dev/null 2>&1; then
    STATUS=$("$QUERY_SCRIPT" status in-progress --format count)
    if [ "$STATUS" = "2" ]; then
        echo -e "${GREEN}✓${NC} Status update works"
    else
        echo -e "${RED}✗${NC} Status not updated correctly"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Status update failed"
    exit 1
fi

# Test 2: Update priority
echo -e "\n${YELLOW}Test 2:${NC} Update priority"
if "$UPDATE_SCRIPT" TASK-001-001-01 priority medium > /dev/null 2>&1; then
    if grep -A10 "TASK-001-001-01" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Priority\\*\\*: medium"; then
        echo -e "${GREEN}✓${NC} Priority update works"
    else
        echo -e "${RED}✗${NC} Priority not updated"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Priority update failed"
    exit 1
fi

# Test 3: Start task
echo -e "\n${YELLOW}Test 3:${NC} Start task"
if "$UPDATE_SCRIPT" TASK-001-001-03 start > /dev/null 2>&1; then
    if grep -A15 "TASK-001-001-03" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Started\\*\\*:"; then
        echo -e "${GREEN}✓${NC} Start task works"
    else
        echo -e "${RED}✗${NC} Started field not added"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Start task failed"
    exit 1
fi

# Test 4: Add actual time
echo -e "\n${YELLOW}Test 4:${NC} Add actual time"
if "$UPDATE_SCRIPT" TASK-001-001-02 actual 2.5h > /dev/null 2>&1; then
    if grep -A15 "TASK-001-001-02" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Actual\\*\\*: 2.5h"; then
        echo -e "${GREEN}✓${NC} Actual time update works"
    else
        echo -e "${RED}✗${NC} Actual time not added"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Actual time update failed"
    exit 1
fi

# Test 5: Complete task
echo -e "\n${YELLOW}Test 5:${NC} Complete task"
ACTIVE_BEFORE=$(grep "^active-tasks:" "$TEST_DIR/session-notes/tasks/tasks.md" | awk '{print $2}')
if "$UPDATE_SCRIPT" TASK-001-001-02 complete > /dev/null 2>&1; then
    ACTIVE_AFTER=$(grep "^active-tasks:" "$TEST_DIR/session-notes/tasks/tasks.md" | awk '{print $2}')
    COMPLETED_TODAY=$(grep "^completed-today:" "$TEST_DIR/session-notes/tasks/tasks.md" | awk '{print $2}')
    
    if [ "$ACTIVE_AFTER" -lt "$ACTIVE_BEFORE" ] && [ "$COMPLETED_TODAY" -eq 1 ]; then
        echo -e "${GREEN}✓${NC} Complete task works (metadata updated)"
    else
        echo -e "${RED}✗${NC} Metadata not updated correctly"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Complete task failed"
    exit 1
fi

# Test 6: Add notes
echo -e "\n${YELLOW}Test 6:${NC} Add notes"
if "$UPDATE_SCRIPT" TASK-001-001-01 notes "Test note added" > /dev/null 2>&1; then
    if grep -A30 "TASK-001-001-01" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Test note added"; then
        echo -e "${GREEN}✓${NC} Notes addition works"
    else
        echo -e "${RED}✗${NC} Note not added"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Notes addition failed"
    exit 1
fi

# Test 7: Block task
echo -e "\n${YELLOW}Test 7:${NC} Block task"
if "$UPDATE_SCRIPT" TASK-001-001-03 block "Waiting for design approval" > /dev/null 2>&1; then
    STATUS=$("$QUERY_SCRIPT" status blocked --format count)
    if [ "$STATUS" = "1" ]; then
        echo -e "${GREEN}✓${NC} Block task works"
    else
        echo -e "${RED}✗${NC} Task not blocked"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Block task failed"
    exit 1
fi

# Test 8: Unblock task
echo -e "\n${YELLOW}Test 8:${NC} Unblock task"
if "$UPDATE_SCRIPT" TASK-001-001-03 unblock > /dev/null 2>&1; then
    # Should be in-progress since we started it earlier
    if grep -A10 "TASK-001-001-03" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Status\\*\\*: in-progress"; then
        echo -e "${GREEN}✓${NC} Unblock task works"
    else
        echo -e "${RED}✗${NC} Task not unblocked correctly"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Unblock task failed"
    exit 1
fi

# Test 9: Invalid task ID
echo -e "\n${YELLOW}Test 9:${NC} Invalid task ID"
if ! "$UPDATE_SCRIPT" INVALID-ID status pending > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Invalid task ID rejected"
else
    echo -e "${RED}✗${NC} Invalid task ID not caught"
    exit 1
fi

# Test 10: Non-existent task
echo -e "\n${YELLOW}Test 10:${NC} Non-existent task"
if ! "$UPDATE_SCRIPT" TASK-999-999-99 status pending > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Non-existent task rejected"
else
    echo -e "${RED}✗${NC} Non-existent task not caught"
    exit 1
fi

# Test 11: Invalid status value
echo -e "\n${YELLOW}Test 11:${NC} Invalid status value"
if ! "$UPDATE_SCRIPT" TASK-001-001-01 status invalid-status > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Invalid status value rejected"
else
    echo -e "${RED}✗${NC} Invalid status not caught"
    exit 1
fi

# Test 12: Update estimate
echo -e "\n${YELLOW}Test 12:${NC} Update estimate"
if "$UPDATE_SCRIPT" TASK-001-001-01 estimate 4h > /dev/null 2>&1; then
    if grep -A10 "TASK-001-001-01" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Estimate\\*\\*: 4h"; then
        echo -e "${GREEN}✓${NC} Estimate update works"
    else
        echo -e "${RED}✗${NC} Estimate not updated"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Estimate update failed"
    exit 1
fi

# Test 13: Update persona
echo -e "\n${YELLOW}Test 13:${NC} Update persona"
if "$UPDATE_SCRIPT" TASK-001-001-01 persona architect > /dev/null 2>&1; then
    if grep -A10 "TASK-001-001-01" "$TEST_DIR/session-notes/tasks/tasks.md" | grep -q "Persona\\*\\*: architect"; then
        echo -e "${GREEN}✓${NC} Persona update works"
    else
        echo -e "${RED}✗${NC} Persona not updated"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Persona update failed"
    exit 1
fi

echo -e "\n${GREEN}[TEST]${NC} All tests passed! ✨"

# Show sample of updated task
echo -e "\n${BLUE}[TEST]${NC} Sample updated task:"
echo "----------------------------------------"
grep -A20 "TASK-001-001-01" "$TEST_DIR/session-notes/tasks/tasks.md" | head -25
echo "----------------------------------------"

# Performance test
echo -e "\n${BLUE}[TEST]${NC} Performance check..."
START=$(date +%s.%N)
"$UPDATE_SCRIPT" TASK-001-001-01 status pending > /dev/null 2>&1
END=$(date +%s.%N)
ELAPSED=$(echo "$END - $START" | bc)
echo -e "Update execution time: ${ELAPSED}s"

if (( $(echo "$ELAPSED < 0.1" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Performance is excellent (< 0.1s)"
elif (( $(echo "$ELAPSED < 0.5" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Performance is good (< 0.5s)"
else
    echo -e "${YELLOW}⚠${NC} Performance could be improved (> 0.5s)"
fi

# Cleanup
echo -e "\n${YELLOW}[TEST]${NC} Test files preserved in: $TEST_DIR"
echo "To clean up: rm -rf $TEST_DIR"