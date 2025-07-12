#!/bin/bash
#
# Test script for task extraction
# Creates a test story file and validates extraction

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/ap-task-test-$$"
mkdir -p "$TEST_DIR/session-notes/tasks"
mkdir -p "$TEST_DIR/stories"

echo -e "${GREEN}[TEST]${NC} Task Extraction Test Suite"
echo "Test directory: $TEST_DIR"

# Create test story file
cat > "$TEST_DIR/stories/STORY-999-test-extraction.md" << 'EOF'
# Story 99.1: Test Task Extraction

## Story ID: STORY-999
## Epic Link: [EPIC-099 - Test Epic](../epics/epic-test.md)
## Phase: 1 - Testing
## Epic: EPIC-099 - Test Epic
## Priority: High
## Story Points: 3

---

## User Story

**As a** Developer  
**I want** to test task extraction  
**So that** I can verify the extraction logic works correctly

---

## Tasks
<!-- AP-TASKS-START -->
### [TASK-XXX] Implement Core Feature
- **Type**: development
- **Priority**: high
- **Persona**: developer
- **Estimate**: 4h
- **Dependencies**: none
- **Description**: Implement the core feature with full test coverage

### [TASK-XXX] Write Unit Tests
- **Type**: testing
- **Priority**: high
- **Persona**: qa
- **Estimate**: 2h
- **Dependencies**: TASK-1
- **Description**: Create comprehensive unit tests for the feature

### [TASK-XXX] Update Documentation
- **Type**: documentation
- **Priority**: medium
- **Persona**: developer
- **Estimate**: 1h
- **Dependencies**: TASK-1, TASK-2
- **Description**: Update all relevant documentation
<!-- AP-TASKS-END -->

---
EOF

# Create test tasks.md
cat > "$TEST_DIR/session-notes/tasks/tasks.md" << 'EOF'
# AP Mapping Tasks

## Metadata
last-updated: 2025-01-11T10:00:00Z
total-tasks: 5
active-tasks: 5
completed-today: 0
next-id: TASK-001-001-01
version: 1.0.0

## Task ID Format
- Pattern: TASK-{EPIC}-{STORY}-{SEQUENCE}
- Example: TASK-001-002-01 (Epic 1, Story 2, Task 1)

## Active Tasks

### [TASK-001-001-01] Existing Task
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
An existing task for testing

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

# Set environment variables for test
export PROJECT_DOCS="$TEST_DIR"

# Copy extraction script to test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/extract-tasks.sh" "$TEST_DIR/"

echo -e "\n${GREEN}[TEST]${NC} Running extraction..."

# Run extraction
cd "$TEST_DIR"
if ./extract-tasks.sh "STORY-999-test-extraction.md" > extraction.log 2>&1; then
    echo -e "${GREEN}✓${NC} Extraction completed successfully"
else
    echo -e "${RED}✗${NC} Extraction failed"
    cat extraction.log
    exit 1
fi

echo -e "\n${GREEN}[TEST]${NC} Validating results..."

# Test 1: Check if tasks were added
TASK_COUNT=$(grep -c "^### \[TASK-099-999-" session-notes/tasks/tasks.md || true)
if [ "$TASK_COUNT" -eq 3 ]; then
    echo -e "${GREEN}✓${NC} Correct number of tasks extracted: 3"
else
    echo -e "${RED}✗${NC} Expected 3 tasks, found $TASK_COUNT"
    exit 1
fi

# Test 2: Check task IDs were assigned
if grep -q "TASK-099-999-01" session-notes/tasks/tasks.md && \
   grep -q "TASK-099-999-02" session-notes/tasks/tasks.md && \
   grep -q "TASK-099-999-03" session-notes/tasks/tasks.md; then
    echo -e "${GREEN}✓${NC} Task IDs assigned correctly"
else
    echo -e "${RED}✗${NC} Task IDs not assigned correctly"
    exit 1
fi

# Test 3: Check dependencies were updated
if grep -q "\*\*Dependencies\*\*:.*TASK-099-999-01" session-notes/tasks/tasks.md; then
    echo -e "${GREEN}✓${NC} Dependencies updated with real IDs"
else
    echo -e "${RED}✗${NC} Dependencies not updated correctly"
    exit 1
fi

# Test 4: Check story file was updated
if grep -q "\[TASK-099-999-01\]" stories/STORY-999-test-extraction.md && \
   grep -q "\[TASK-099-999-02\]" stories/STORY-999-test-extraction.md && \
   grep -q "\[TASK-099-999-03\]" stories/STORY-999-test-extraction.md; then
    echo -e "${GREEN}✓${NC} Story file updated with real IDs"
else
    echo -e "${RED}✗${NC} Story file not updated correctly"
    exit 1
fi

# Test 5: Check metadata was updated
TOTAL_TASKS=$(grep "^total-tasks:" session-notes/tasks/tasks.md | awk '{print $2}')
ACTIVE_TASKS=$(grep "^active-tasks:" session-notes/tasks/tasks.md | awk '{print $2}')
NEXT_ID=$(grep "^next-id:" session-notes/tasks/tasks.md | awk '{print $2}')

if [ -n "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -eq 8 ] && [ -n "$ACTIVE_TASKS" ] && [ "$ACTIVE_TASKS" -eq 8 ] && [ "$NEXT_ID" = "TASK-099-999-04" ]; then
    echo -e "${GREEN}✓${NC} Metadata updated correctly"
else
    echo -e "${RED}✗${NC} Metadata not updated correctly"
    echo "  Total tasks: $TOTAL_TASKS (expected 8)"
    echo "  Active tasks: $ACTIVE_TASKS (expected 8)"
    echo "  Next ID: $NEXT_ID (expected TASK-099-999-04)"
    exit 1
fi

# Test 6: Check blocks field was calculated
# TASK-099-999-01 should block tasks that depend on it
# Note: This is a future enhancement - blocks calculation happens in a separate pass
echo -e "${YELLOW}⚠${NC} Blocks field calculation - future enhancement"

echo -e "\n${GREEN}[TEST]${NC} All tests passed! ✨"

# Show sample output
echo -e "\n${GREEN}[TEST]${NC} Sample extracted task:"
echo "----------------------------------------"
awk '/### \[TASK-099-999-01\]/,/^---$/' session-notes/tasks/tasks.md | head -20
echo "----------------------------------------"

# Cleanup
echo -e "\n${YELLOW}[TEST]${NC} Test files preserved in: $TEST_DIR"
echo "To clean up: rm -rf $TEST_DIR"