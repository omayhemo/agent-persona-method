# AP Mapping Task Management System User Guide

## Overview

The AP Mapping Task Management System is a flat-file based task tracking system designed specifically for managing software development tasks within the AP Mapping workflow. It provides scripts for extracting tasks from story files, querying task status, updating tasks, and archiving completed work.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Task File Structure](#task-file-structure)
3. [Core Scripts](#core-scripts)
4. [Common Workflows](#common-workflows)
5. [Task Lifecycle](#task-lifecycle)
6. [Dependencies and Blocks](#dependencies-and-blocks)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

## System Architecture

The task management system consists of:

- **Central Task File**: `$PROJECT_DOCS/session-notes/tasks/tasks.md`
- **Archive Directory**: `$PROJECT_DOCS/session-notes/tasks/archive/`
- **Core Scripts**:
  - `extract-tasks.sh` - Extract tasks from story files
  - `query-tasks.sh` - Query and filter tasks
  - `update-task.sh` - Update task status and fields
  - `archive-tasks.sh` - Archive completed tasks
- **Test Scripts**:
  - `test-suite.sh` - Unit tests
  - `integration-tests.sh` - End-to-end tests

## Task File Structure

### Task ID Format
```
TASK-{EPIC}-{STORY}-{SEQUENCE}
Example: TASK-001-002-03 (Epic 1, Story 2, Task 3)
```

### Task Fields

| Field | Required | Description |
|-------|----------|-------------|
| Epic | Yes | Associated epic ID (e.g., EPIC-001) |
| Story | Yes | Associated story ID (e.g., STORY-002) |
| Type | Yes | Task type: development, testing, documentation, etc. |
| Status | Yes | Current status: pending, in-progress, blocked, review, completed, cancelled |
| Priority | Yes | Priority level: high, medium, low |
| Persona | Yes | Assigned persona: developer, qa, architect, etc. |
| Created | Yes | Creation date (YYYY-MM-DD) |
| Updated | Yes | Last update timestamp (ISO 8601) |
| Started | No | Start timestamp (when status → in-progress) |
| Completed | No | Completion timestamp (when status → completed) |
| Estimate | Yes | Time estimate (e.g., 2h, 1d) |
| Actual | No | Actual time spent |
| Dependencies | Yes | Comma-separated list of task IDs or "none" |
| Blocks | Yes | Auto-calculated list of tasks this blocks |
| Description | Yes | Brief task description |
| Notes | No | Additional notes added during work |

### Example Task Block
```markdown
### [TASK-001-002-03] Implement Query Functions
- **Epic**: EPIC-001
- **Story**: STORY-002
- **Type**: development
- **Status**: in-progress
- **Priority**: high
- **Persona**: developer
- **Created**: 2025-01-10
- **Updated**: 2025-01-11T12:30:45Z
- **Started**: 2025-01-11 11:40
- **Estimate**: 3h
- **Dependencies**: TASK-001-002-01
- **Blocks**: TASK-001-002-06

#### Description
Create grep-based query functions for filtering tasks by status, epic, persona, etc.

#### Notes
2025-01-11: Implemented basic queries, working on performance optimization

---
```

## Core Scripts

### 1. extract-tasks.sh

Extracts tasks from story files and adds them to the central task file.

```bash
# Basic usage
./extract-tasks.sh path/to/STORY-001.md

# What it does:
# - Finds tasks between <!-- AP-TASKS-START --> and <!-- AP-TASKS-END -->
# - Assigns sequential task IDs based on epic and story
# - Updates dependencies from relative (TASK-1) to absolute (TASK-001-002-01)
# - Calculates the "Blocks" field based on dependencies
# - Updates both tasks.md and the story file
```

### 2. query-tasks.sh

Query and filter tasks based on various criteria.

```bash
# Query by status
./query-tasks.sh status pending
./query-tasks.sh status in-progress --format count

# Query by epic or story
./query-tasks.sh epic EPIC-001
./query-tasks.sh story STORY-002 --format id

# Query by persona
./query-tasks.sh persona developer --format full

# Find ready tasks (dependencies met)
./query-tasks.sh ready

# Output formats:
# --format full    : Complete task blocks (default)
# --format summary : One-line summaries
# --format id      : Just task IDs
# --format count   : Count only

# List all tasks
./query-tasks.sh list

# Count by field
./query-tasks.sh count status
./query-tasks.sh count epic
```

### 3. update-task.sh

Update task status and fields.

```bash
# Update status
./update-task.sh TASK-001-002-03 status in-progress
./update-task.sh TASK-001-002-03 status completed

# Convenience commands
./update-task.sh TASK-001-002-03 start     # Sets in-progress + timestamp
./update-task.sh TASK-001-002-03 complete  # Sets completed + timestamp

# Update fields
./update-task.sh TASK-001-002-03 priority high
./update-task.sh TASK-001-002-03 actual 2.5h
./update-task.sh TASK-001-002-03 persona qa

# Add notes (appends with timestamp)
./update-task.sh TASK-001-002-03 notes "Fixed issue with query performance"
```

### 4. archive-tasks.sh

Archive completed tasks to monthly files.

```bash
# Archive previous month's completed tasks
./archive-tasks.sh

# Archive specific month
./archive-tasks.sh --month 2025-01

# Archive all completed tasks
./archive-tasks.sh --all

# Preview without making changes
./archive-tasks.sh --dry-run
./archive-tasks.sh --month 2025-01 --dry-run

# Archives are created in:
# $PROJECT_DOCS/session-notes/tasks/archive/YYYY-MM.md
# $PROJECT_DOCS/session-notes/tasks/archive/all-completed-tasks.md
```

## Common Workflows

### 1. Starting a New Story

```bash
# 1. Create story file with tasks
cat > stories/STORY-003.md << 'EOF'
# Story: User Authentication

## Story ID: STORY-003
## Epic: EPIC-001 - Core Features

## Tasks

<!-- AP-TASKS-START -->

### [TASK-XXX] Design Auth Flow
- **Type**: design
- **Priority**: high
- **Persona**: architect
- **Estimate**: 2h
- **Dependencies**: none
- **Description**: Design authentication architecture

### [TASK-XXX] Implement Login
- **Type**: development
- **Priority**: high
- **Persona**: developer
- **Estimate**: 4h
- **Dependencies**: TASK-1
- **Description**: Create login functionality

<!-- AP-TASKS-END -->
EOF

# 2. Extract tasks
./extract-tasks.sh stories/STORY-003.md

# 3. Review extracted tasks
./query-tasks.sh story STORY-003
```

### 2. Daily Development Flow

```bash
# Check what's ready to work on
./query-tasks.sh ready

# Start a task
./update-task.sh TASK-001-003-02 start

# Add progress notes
./update-task.sh TASK-001-003-02 notes "Implemented basic login form"

# Complete the task
./update-task.sh TASK-001-003-02 complete
./update-task.sh TASK-001-003-02 actual 3.5h

# Check what's ready next
./query-tasks.sh ready
```

### 3. Status Reporting

```bash
# Active tasks by person
./query-tasks.sh persona developer --format summary | grep in-progress
./query-tasks.sh persona qa --format summary | grep in-progress

# Progress by epic
./query-tasks.sh count epic
./query-tasks.sh epic EPIC-001 --format summary

# Today's completions
./query-tasks.sh status completed --format full | grep "Completed.*$(date +%Y-%m-%d)"

# Blocked tasks
./query-tasks.sh status blocked
```

### 4. Monthly Archival

```bash
# At month end, archive completed tasks
./archive-tasks.sh --month $(date +%Y-%m) --dry-run  # Preview
./archive-tasks.sh --month $(date +%Y-%m)             # Execute

# Review archive
less $PROJECT_DOCS/session-notes/tasks/archive/$(date +%Y-%m).md
```

## Task Lifecycle

1. **Pending** → Task created but not started
2. **In-Progress** → Developer actively working (use `start` command)
3. **Blocked** → Waiting on dependencies (automatic based on deps)
4. **Review** → Completed but awaiting review (optional status)
5. **Completed** → Work finished (use `complete` command)
6. **Cancelled** → Will not be completed

## Dependencies and Blocks

### Dependency Resolution
- Tasks can depend on multiple other tasks (comma-separated)
- Use relative references in stories: `TASK-1`, `TASK-2`
- Extract script converts to absolute IDs: `TASK-001-002-01`
- A task is "ready" when all dependencies are completed

### Blocks Calculation
- Automatically calculated during extraction
- Updated when new tasks are added
- Shows which tasks are waiting on this one

### Example Flow
```
TASK-001-002-01 (Setup Database)
  └─ Blocks: TASK-001-002-02, TASK-001-002-03

TASK-001-002-02 (API Development)
  ├─ Dependencies: TASK-001-002-01
  └─ Blocks: TASK-001-002-04

TASK-001-002-03 (Data Migration)
  └─ Dependencies: TASK-001-002-01

TASK-001-002-04 (API Tests)
  └─ Dependencies: TASK-001-002-02
```

## Testing

### Running Tests

```bash
# Run unit tests (fast, ~1 second)
./test-suite.sh

# Run integration tests (slower, ~30 seconds)
./integration-tests.sh

# Test specific functionality
./test-extract-tasks.sh
./test-query-tasks.sh
./test-update-task.sh
./test-archive-tasks.sh
```

### Test Coverage
- **Unit Tests**: 10 tests covering all basic operations
- **Integration Tests**: 6 tests covering end-to-end workflows
- **Performance Tests**: Validated with 50+ task datasets

## Troubleshooting

### Common Issues

1. **"Task not found" error**
   - Verify task ID format: `TASK-XXX-XXX-XX`
   - Check task exists: `./query-tasks.sh list | grep TASK-001-002-03`

2. **Dependencies not resolving**
   - Ensure dependency task IDs are correct
   - Check if dependencies are completed: `./query-tasks.sh ready`

3. **Archive not working**
   - Verify completed date format: `YYYY-MM-DD` or `YYYY-MM-DD HH:MM`
   - Use `--dry-run` to preview what will be archived

4. **Extract not finding tasks**
   - Ensure task markers are present: `<!-- AP-TASKS-START -->` and `<!-- AP-TASKS-END -->`
   - Check task format matches examples

### Debug Mode

Most scripts support verbose output:
```bash
# Add debugging to any script
DEBUG=1 ./extract-tasks.sh story.md
DEBUG=1 ./query-tasks.sh status pending
```

### File Locations

Default paths (can be overridden with environment variables):
- Tasks file: `$PROJECT_DOCS/session-notes/tasks/tasks.md`
- Archives: `$PROJECT_DOCS/session-notes/tasks/archive/`
- Backups: `*.bak` files created before updates

## Best Practices

1. **Regular Archival**: Archive monthly to keep tasks.md manageable
2. **Consistent Updates**: Update task status as work progresses
3. **Clear Dependencies**: Define dependencies during story creation
4. **Time Tracking**: Record actual time for better estimates
5. **Progress Notes**: Add notes for context and handoffs
6. **Test Changes**: Run test suite after modifying scripts

## Integration with AP Mapping

The task management system integrates seamlessly with the AP Mapping workflow:

1. **Product Manager** creates epics
2. **Product Owner** defines stories with task templates
3. **Developers** extract tasks and implement
4. **QA** tracks testing tasks and dependencies
5. **All Personas** query status and update progress

For more information on the AP Mapping, see the main documentation.