#!/bin/bash
#
# AP Mapping Task Management Test Suite
# Comprehensive unit tests for all task management functions
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results array
declare -a TEST_RESULTS

# Function to run a test
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}Running:${NC} $test_name"
    
    # Create test directory
    TEST_DIR="/tmp/ap-test-$$-$RANDOM"
    mkdir -p "$TEST_DIR/session-notes/tasks"
    mkdir -p "$TEST_DIR/stories"
    export PROJECT_DOCS="$TEST_DIR"
    
    # Run test in subshell to isolate environment
    if (
        set -e
        cd "$SCRIPT_DIR"
        $test_func "$TEST_DIR"
    ); then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("$test_name:PASSED")
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("$test_name:FAILED")
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR"
}

# Function to assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [ "$expected" != "$actual" ]; then
        echo -e "${RED}ASSERTION FAILED:${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
}

# Function to assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}ASSERTION FAILED:${NC} $message: $file"
        return 1
    fi
}

# Function to assert file contains
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-File should contain pattern}"
    
    if ! grep -q "$pattern" "$file"; then
        echo -e "${RED}ASSERTION FAILED:${NC} $message"
        echo "  File: $file"
        echo "  Pattern: $pattern"
        return 1
    fi
}

# Initialize test environment
setup_test_env() {
    local test_dir="$1"
    
    # Create initial tasks.md
    cat > "$test_dir/session-notes/tasks/tasks.md" << 'EOF'
# AP Mapping Tasks

## Metadata
last-updated: 2025-01-01T00:00:00Z
total-tasks: 0
active-tasks: 0
completed-today: 0
next-id: TASK-001-001-01

## Task ID Format
- Pattern: TASK-{EPIC}-{STORY}-{SEQUENCE}
- Example: TASK-001-002-01 (Epic 1, Story 2, Task 1)

## Active Tasks

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
}

#
# Unit Tests for extract-tasks.sh
#

test_extract_basic() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Create test story file
    cat > "$test_dir/stories/STORY-001.md" << 'EOF'
# Story: Basic Feature

## Story ID: STORY-001
## Epic: EPIC-001 - Initial Development

## Tasks

<!-- AP-TASKS-START -->

### [TASK-XXX] Test Task One
- **Type**: development
- **Priority**: high
- **Persona**: developer
- **Estimate**: 2h
- **Dependencies**: none
- **Description**: First test task

### [TASK-XXX] Test Task Two
- **Type**: testing
- **Priority**: medium
- **Persona**: qa
- **Estimate**: 1h
- **Dependencies**: TASK-1
- **Description**: Second test task

<!-- AP-TASKS-END -->
EOF

    # Run extraction
    ./extract-tasks.sh "$test_dir/stories/STORY-001.md"
    
    # Verify tasks were added
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "TASK-001-001-01" "First task should be extracted"
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "TASK-001-001-02" "Second task should be extracted"
    
    # Verify dependencies were updated
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Dependencies.*TASK-001-001-01" "Dependencies should be updated"
    
    # Verify blocks field was calculated
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Blocks.*TASK-001-001-02" "Blocks field should be set"
}

test_extract_empty() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Create story without tasks
    cat > "$test_dir/stories/STORY-002.md" << 'EOF'
# Story: Empty Story

## Story ID: STORY-002
## Epic: EPIC-001 - Initial Development

## Tasks

No tasks defined yet.
EOF

    # Run extraction - should succeed with warning
    ./extract-tasks.sh "$test_dir/stories/STORY-002.md"
    
    # Verify no tasks were added (beyond what setup_test_env created)
    local task_count
    if grep -q "^### \[TASK-" "$test_dir/session-notes/tasks/tasks.md" 2>/dev/null; then
        task_count=1
    else
        task_count=0
    fi
    assert_equals "0" "$task_count" "No tasks should be added from empty story"
}

#
# Unit Tests for query-tasks.sh
#

test_query_by_status() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Add test tasks
    cat >> "$test_dir/session-notes/tasks/tasks.md" << 'EOF'

### [TASK-001-001-01] Pending Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: pending
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 2h
- **Dependencies**: none
- **Blocks**: none

#### Description
A pending task

---

### [TASK-001-001-02] Active Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: in-progress
- **Priority**: medium
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Started**: 2025-01-01 10:00
- **Estimate**: 3h
- **Dependencies**: none
- **Blocks**: none

#### Description
An active task

---

### [TASK-001-001-03] Completed Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: testing
- **Status**: completed
- **Priority**: low
- **Persona**: qa
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Started**: 2025-01-01 14:00
- **Completed**: 2025-01-01 15:00
- **Estimate**: 1h
- **Actual**: 1h
- **Dependencies**: none
- **Blocks**: none

#### Description
A completed task

---
EOF

    # Test status queries
    local pending_count=$(./query-tasks.sh status pending --format count)
    assert_equals "1" "$pending_count" "Should find 1 pending task"
    
    local active_count=$(./query-tasks.sh status in-progress --format count)
    assert_equals "1" "$active_count" "Should find 1 in-progress task"
    
    local completed_count=$(./query-tasks.sh status completed --format count)
    assert_equals "1" "$completed_count" "Should find 1 completed task"
}

test_query_by_persona() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Use tasks from previous test
    test_query_by_status "$test_dir" > /dev/null 2>&1
    
    # Test persona queries
    local dev_tasks=$(./query-tasks.sh persona developer --format id)
    local dev_count=$(echo "$dev_tasks" | grep -c "TASK-" || echo "0")
    assert_equals "2" "$dev_count" "Should find 2 developer tasks"
    
    local qa_tasks=$(./query-tasks.sh persona qa --format id)
    local qa_count=$(echo "$qa_tasks" | grep -c "TASK-" || echo "0")
    assert_equals "1" "$qa_count" "Should find 1 qa task"
}

test_query_ready_tasks() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Add tasks with dependencies
    cat >> "$test_dir/session-notes/tasks/tasks.md" << 'EOF'

### [TASK-001-001-01] Base Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: completed
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 2h
- **Dependencies**: none
- **Blocks**: TASK-001-001-02

#### Description
Base task

---

### [TASK-001-001-02] Dependent Task Ready
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: pending
- **Priority**: medium
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 3h
- **Dependencies**: TASK-001-001-01
- **Blocks**: TASK-001-001-03

#### Description
Task with completed dependency

---

### [TASK-001-001-03] Dependent Task Blocked
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: testing
- **Status**: pending
- **Priority**: low
- **Persona**: qa
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 1h
- **Dependencies**: TASK-001-001-02
- **Blocks**: none

#### Description
Task with pending dependency

---
EOF

    # Test ready tasks
    local ready_tasks=$(./query-tasks.sh ready --format id)
    assert_file_contains <(echo "$ready_tasks") "TASK-001-001-02" "Task with completed deps should be ready"
    
    # Task 3 should not be ready
    if echo "$ready_tasks" | grep -q "TASK-001-001-03"; then
        echo -e "${RED}ASSERTION FAILED:${NC} Task with pending deps should not be ready"
        return 1
    fi
}

#
# Unit Tests for update-task.sh
#

test_update_status() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Add test task
    cat >> "$test_dir/session-notes/tasks/tasks.md" << 'EOF'

### [TASK-001-001-01] Test Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: pending
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 2h
- **Dependencies**: none
- **Blocks**: none

#### Description
Test task for updates

---
EOF

    # Update status
    ./update-task.sh TASK-001-001-01 status in-progress
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Status.*in-progress" "Status should be updated"
    
    # Test start action
    ./update-task.sh TASK-001-001-01 start
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Started.*:" "Started field should be added"
    
    # Test complete action
    ./update-task.sh TASK-001-001-01 complete
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Status.*completed" "Status should be completed"
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Completed.*:" "Completed field should be added"
}

test_update_notes() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Add test task
    cat >> "$test_dir/session-notes/tasks/tasks.md" << 'EOF'

### [TASK-001-001-01] Test Task
- **Epic**: EPIC-001
- **Story**: STORY-001
- **Type**: development
- **Status**: pending
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-01
- **Updated**: 2025-01-01
- **Estimate**: 2h
- **Dependencies**: none
- **Blocks**: none

#### Description
Test task for notes

---
EOF

    # Add notes
    ./update-task.sh TASK-001-001-01 notes "First note added"
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "#### Notes" "Notes section should be added"
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "First note added" "Note content should be present"
    
    # Add second note
    ./update-task.sh TASK-001-001-01 notes "Second note added"
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "Second note added" "Second note should be appended"
}

#
# Unit Tests for archive-tasks.sh
#

test_archive_by_month() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Need to update metadata for tasks we're adding
    sed -i.bak 's/total-tasks: 0/total-tasks: 3/' "$test_dir/session-notes/tasks/tasks.md"
    sed -i.bak 's/active-tasks: 0/active-tasks: 3/' "$test_dir/session-notes/tasks/tasks.md"
    
    # Add tasks to the Active Tasks section
    awk '
    /^## Active Tasks/ {
        print
        print ""
        print "### [TASK-001-001-01] January Task"
        print "- **Epic**: EPIC-001"
        print "- **Story**: STORY-001"
        print "- **Type**: development"
        print "- **Status**: completed"
        print "- **Priority**: high"
        print "- **Persona**: developer"
        print "- **Created**: 2025-01-01"
        print "- **Updated**: 2025-01-31"
        print "- **Started**: 2025-01-01 10:00"
        print "- **Completed**: 2025-01-31 16:00"
        print "- **Estimate**: 2h"
        print "- **Actual**: 2h"
        print "- **Dependencies**: none"
        print "- **Blocks**: none"
        print ""
        print "#### Description"
        print "January completed task"
        print ""
        print "---"
        print ""
        print "### [TASK-001-001-02] February Task"
        print "- **Epic**: EPIC-001"
        print "- **Story**: STORY-001"
        print "- **Type**: testing"
        print "- **Status**: completed"
        print "- **Priority**: medium"
        print "- **Persona**: qa"
        print "- **Created**: 2025-02-01"
        print "- **Updated**: 2025-02-15"
        print "- **Started**: 2025-02-01 09:00"
        print "- **Completed**: 2025-02-15 11:00"
        print "- **Estimate**: 3h"
        print "- **Actual**: 2.5h"
        print "- **Dependencies**: none"
        print "- **Blocks**: none"
        print ""
        print "#### Description"
        print "February completed task"
        print ""
        print "---"
        print ""
        print "### [TASK-001-001-03] Active Task"
        print "- **Epic**: EPIC-001"
        print "- **Story**: STORY-001"
        print "- **Type**: development"
        print "- **Status**: in-progress"
        print "- **Priority**: low"
        print "- **Persona**: developer"
        print "- **Created**: 2025-03-01"
        print "- **Updated**: 2025-03-01"
        print "- **Started**: 2025-03-01 14:00"
        print "- **Estimate**: 1h"
        print "- **Dependencies**: none"
        print "- **Blocks**: none"
        print ""
        print "#### Description"
        print "Still active task"
        print ""
        print "---"
        next
    }
    { print }
    ' "$test_dir/session-notes/tasks/tasks.md.bak" > "$test_dir/session-notes/tasks/tasks.md"
    
    # Archive January tasks
    ./archive-tasks.sh --month 2025-01
    
    # Verify archive created
    assert_file_exists "$test_dir/session-notes/tasks/archive/2025-01.md" "January archive should be created"
    assert_file_contains "$test_dir/session-notes/tasks/archive/2025-01.md" "TASK-001-001-01" "January task should be archived"
    
    # Verify February task not archived
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "TASK-001-001-02" "February task should remain"
    
    # Verify active task remains
    assert_file_contains "$test_dir/session-notes/tasks/tasks.md" "TASK-001-001-03" "Active task should remain"
}

test_archive_all() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Update metadata
    sed -i.bak 's/total-tasks: 0/total-tasks: 2/' "$test_dir/session-notes/tasks/tasks.md"
    sed -i.bak 's/active-tasks: 0/active-tasks: 2/' "$test_dir/session-notes/tasks/tasks.md"
    
    # Add tasks to the Active Tasks section
    awk '
    /^## Active Tasks/ {
        print
        print ""
        print "### [TASK-001-001-01] First Completed Task"
        print "- **Epic**: EPIC-001"
        print "- **Story**: STORY-001"
        print "- **Type**: development"
        print "- **Status**: completed"
        print "- **Priority**: high"
        print "- **Persona**: developer"
        print "- **Created**: 2025-01-01"
        print "- **Updated**: 2025-01-31"
        print "- **Started**: 2025-01-01 10:00"
        print "- **Completed**: 2025-01-31 16:00"
        print "- **Estimate**: 2h"
        print "- **Actual**: 2h"
        print "- **Dependencies**: none"
        print "- **Blocks**: none"
        print ""
        print "#### Description"
        print "First completed task"
        print ""
        print "---"
        print ""
        print "### [TASK-001-001-02] Second Completed Task"
        print "- **Epic**: EPIC-001"
        print "- **Story**: STORY-001"
        print "- **Type**: testing"
        print "- **Status**: completed"
        print "- **Priority**: medium"
        print "- **Persona**: qa"
        print "- **Created**: 2025-02-01"
        print "- **Updated**: 2025-02-15"
        print "- **Started**: 2025-02-01 09:00"
        print "- **Completed**: 2025-02-15 11:00"
        print "- **Estimate**: 3h"
        print "- **Actual**: 2.5h"
        print "- **Dependencies**: none"
        print "- **Blocks**: none"
        print ""
        print "#### Description"
        print "Second completed task"
        print ""
        print "---"
        next
    }
    { print }
    ' "$test_dir/session-notes/tasks/tasks.md.bak" > "$test_dir/session-notes/tasks/tasks.md"
    
    # Archive all completed tasks
    ./archive-tasks.sh --all
    
    # Verify all archive created
    assert_file_exists "$test_dir/session-notes/tasks/archive/all-completed-tasks.md" "All tasks archive should be created"
    
    # Verify no completed tasks remain
    local completed_count
    if grep -q "Status.*completed" "$test_dir/session-notes/tasks/tasks.md" 2>/dev/null; then
        completed_count=1
    else
        completed_count=0
    fi
    assert_equals "0" "$completed_count" "No completed tasks should remain"
}

#
# Integration Tests
#

test_integration_full_workflow() {
    local test_dir="$1"
    
    setup_test_env "$test_dir"
    
    # Create story with tasks
    cat > "$test_dir/stories/STORY-001.md" << 'EOF'
# Story: Integration Test

## Story ID: STORY-001
## Epic: EPIC-001 - Test Epic

## Tasks

<!-- AP-TASKS-START -->

### [TASK-XXX] Setup Environment
- **Type**: setup
- **Priority**: high
- **Persona**: developer
- **Estimate**: 1h
- **Dependencies**: none
- **Description**: Setup test environment

### [TASK-XXX] Implement Feature
- **Type**: development
- **Priority**: high
- **Persona**: developer
- **Estimate**: 4h
- **Dependencies**: TASK-1
- **Description**: Implement main feature

### [TASK-XXX] Write Tests
- **Type**: testing
- **Priority**: medium
- **Persona**: qa
- **Estimate**: 2h
- **Dependencies**: TASK-2
- **Description**: Write comprehensive tests

<!-- AP-TASKS-END -->
EOF

    # Extract tasks
    ./extract-tasks.sh "$test_dir/stories/STORY-001.md"
    
    # Query pending tasks
    local pending_count=$(./query-tasks.sh status pending --format count)
    assert_equals "3" "$pending_count" "Should have 3 pending tasks"
    
    # Start first task
    ./update-task.sh TASK-001-001-01 start
    
    # Complete first task
    ./update-task.sh TASK-001-001-01 complete
    
    # Check ready tasks
    local ready_tasks=$(./query-tasks.sh ready --format id)
    assert_file_contains <(echo "$ready_tasks") "TASK-001-001-02" "Second task should be ready"
    
    # Start and complete second task
    ./update-task.sh TASK-001-001-02 start
    ./update-task.sh TASK-001-001-02 notes "Feature implemented successfully"
    ./update-task.sh TASK-001-001-02 complete
    
    # Verify blocks updated
    local task2_info=$(./query-tasks.sh epic EPIC-001 | grep -A20 "TASK-001-001-02")
    assert_file_contains <(echo "$task2_info") "Blocks.*TASK-001-001-03" "Task 2 should block task 3"
    
    # Archive completed tasks
    ./archive-tasks.sh --all
    
    # Verify only one task remains
    local remaining_count=$(grep -c "^### \[TASK-" "$test_dir/session-notes/tasks/tasks.md" || echo "0")
    assert_equals "1" "$remaining_count" "Only one task should remain"
}

#
# Main Test Runner
#

echo -e "${GREEN}AP Mapping Task Management Test Suite${NC}"
echo "======================================"
echo ""

# Run all tests
run_test "Extract: Basic extraction" test_extract_basic
run_test "Extract: Empty story" test_extract_empty
run_test "Query: By status" test_query_by_status
run_test "Query: By persona" test_query_by_persona
run_test "Query: Ready tasks" test_query_ready_tasks
run_test "Update: Status changes" test_update_status
run_test "Update: Add notes" test_update_notes
run_test "Archive: By month" test_archive_by_month
run_test "Archive: All completed" test_archive_all
run_test "Integration: Full workflow" test_integration_full_workflow

# Print summary
echo ""
echo "======================================"
echo -e "${GREEN}Test Summary${NC}"
echo "======================================"
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    echo ""
    echo "Failed tests:"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ "$result" == *":FAILED" ]]; then
            echo -e "  ${RED}✗${NC} ${result%:FAILED}"
        fi
    done
    exit 1
fi