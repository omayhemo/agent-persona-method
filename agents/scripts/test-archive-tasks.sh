#!/bin/bash
#
# Test script for archive-tasks.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/ap-archive-test-$$"
mkdir -p "$TEST_DIR/session-notes/tasks/archive"

# Set environment for test
export PROJECT_DOCS="$TEST_DIR"

echo -e "${GREEN}Testing Task Archive Script${NC}"
echo "Test directory: $TEST_DIR"
echo ""

# Create test tasks.md with various completed tasks
cat > "$TEST_DIR/session-notes/tasks/tasks.md" << 'EOF'
# AP Mapping Tasks

## Metadata
last-updated: 2025-07-11T02:00:00Z
total-tasks: 8
active-tasks: 4
completed-today: 2
next-id: TASK-001-003-01

## Task ID Format
- Pattern: TASK-{EPIC}-{STORY}-{SEQUENCE}
- Example: TASK-001-002-01 (Epic 1, Story 2, Task 1)

## Active Tasks

### [TASK-001-001-01] Setup Project
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: setup
- **Status**: completed
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-05
- **Updated**: 2025-01-05
- **Started**: 2025-01-05 10:00
- **Completed**: 2025-01-05 11:00
- **Estimate**: 2h
- **Actual**: 1h
- **Dependencies**: none
- **Blocks**: TASK-001-001-02

#### Description
Initial project setup

---

### [TASK-001-001-02] Create Documentation
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: documentation
- **Status**: completed
- **Priority**: medium
- **Persona**: developer
- **Created**: 2025-01-05
- **Updated**: 2025-01-06
- **Started**: 2025-01-06 09:00
- **Completed**: 2025-01-06 10:30
- **Estimate**: 2h
- **Actual**: 1.5h
- **Dependencies**: TASK-001-001-01
- **Blocks**: none

#### Description
Create initial documentation

---

### [TASK-001-002-01] Design Architecture
- **Epic**: EPIC-001
- **Story**: STORY-002
- **Type**: design
- **Status**: completed
- **Priority**: high
- **Persona**: architect
- **Created**: 2025-06-01
- **Updated**: 2025-06-02
- **Started**: 2025-06-01 14:00
- **Completed**: 2025-06-02 16:00
- **Estimate**: 4h
- **Actual**: 3h
- **Dependencies**: none
- **Blocks**: TASK-001-002-02

#### Description
Design system architecture

---

### [TASK-001-002-02] Implement Core
- **Epic**: EPIC-001
- **Story**: STORY-002
- **Type**: development
- **Status**: in-progress
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-06-03
- **Updated**: 2025-06-05
- **Started**: 2025-06-05 10:00
- **Estimate**: 8h
- **Dependencies**: TASK-001-002-01
- **Blocks**: TASK-001-002-03

#### Description
Implement core functionality

---

### [TASK-001-002-03] Write Tests
- **Epic**: EPIC-001
- **Story**: STORY-002
- **Type**: testing
- **Status**: pending
- **Priority**: medium
- **Persona**: qa
- **Created**: 2025-06-03
- **Updated**: 2025-06-03
- **Estimate**: 4h
- **Dependencies**: TASK-001-002-02
- **Blocks**: none

#### Description
Write comprehensive tests

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

ARCHIVE_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/archive-tasks.sh"

# Test 1: Dry run for specific month
echo -e "${YELLOW}Test 1: Dry run for January 2025${NC}"
"$ARCHIVE_SCRIPT" --month 2025-01 --dry-run
echo ""

# Test 2: Archive January 2025 tasks
echo -e "${YELLOW}Test 2: Archive January 2025 tasks${NC}"
"$ARCHIVE_SCRIPT" --month 2025-01
echo ""

# Verify archive file
if [ -f "$TEST_DIR/session-notes/tasks/archive/2025-01.md" ]; then
    echo -e "${GREEN}✓ Archive file created${NC}"
    echo "Archive contents:"
    cat "$TEST_DIR/session-notes/tasks/archive/2025-01.md"
else
    echo -e "${RED}✗ Archive file not created${NC}"
fi
echo ""

# Verify tasks.md updated
echo -e "${YELLOW}Test 3: Verify tasks.md updated${NC}"
REMAINING_COMPLETED=$(grep -c "Status\*\*: completed" "$TEST_DIR/session-notes/tasks/tasks.md" || echo "0")
echo "Completed tasks remaining in tasks.md: $REMAINING_COMPLETED"
echo ""

# Test 4: Archive all completed tasks
echo -e "${YELLOW}Test 4: Archive all completed tasks${NC}"
"$ARCHIVE_SCRIPT" --all
echo ""

# Verify all archive
if [ -f "$TEST_DIR/session-notes/tasks/archive/all-completed-tasks.md" ]; then
    echo -e "${GREEN}✓ All tasks archive created${NC}"
    TOTAL_ARCHIVED=$(grep -c "^### \[TASK-" "$TEST_DIR/session-notes/tasks/archive/all-completed-tasks.md" || echo "0")
    echo "Total tasks archived: $TOTAL_ARCHIVED"
else
    echo -e "${RED}✗ All tasks archive not created${NC}"
fi
echo ""

# Test 5: Verify no completed tasks remain
echo -e "${YELLOW}Test 5: Verify no completed tasks remain${NC}"
REMAINING_COMPLETED=$(grep -c "Status\*\*: completed" "$TEST_DIR/session-notes/tasks/tasks.md" || echo "0")
if [ "$REMAINING_COMPLETED" -eq "0" ]; then
    echo -e "${GREEN}✓ No completed tasks remain in tasks.md${NC}"
else
    echo -e "${RED}✗ Still have $REMAINING_COMPLETED completed tasks in tasks.md${NC}"
fi

# Show active tasks count
ACTIVE_COUNT=$(grep -c "^### \[TASK-" "$TEST_DIR/session-notes/tasks/tasks.md" || echo "0")
echo "Active tasks remaining: $ACTIVE_COUNT"
echo ""

# Test 6: Try archiving when no tasks to archive
echo -e "${YELLOW}Test 6: Archive with no tasks to archive${NC}"
"$ARCHIVE_SCRIPT" --month 2024-12
echo ""

# Cleanup
echo -e "${GREEN}Cleaning up test directory${NC}"
rm -rf "$TEST_DIR"

echo -e "${GREEN}All tests completed!${NC}"