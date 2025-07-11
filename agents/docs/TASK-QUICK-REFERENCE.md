# Task Management Quick Reference

## Essential Commands

### Daily Workflow
```bash
# What can I work on?
./query-tasks.sh ready

# Start working
./update-task.sh TASK-001-002-03 start

# Add notes
./update-task.sh TASK-001-002-03 notes "Implemented feature X"

# Complete task
./update-task.sh TASK-001-002-03 complete
```

### Status Checks
```bash
# My active tasks
./query-tasks.sh persona developer | grep in-progress

# Team status
./query-tasks.sh status in-progress --format summary

# Blocked tasks
./query-tasks.sh status blocked

# Today's progress
./query-tasks.sh status completed | grep "$(date +%Y-%m-%d)"
```

### Task Extraction
```bash
# Extract from story
./extract-tasks.sh stories/STORY-001.md

# View extracted tasks
./query-tasks.sh story STORY-001
```

### Queries by Field
```bash
# By status
./query-tasks.sh status pending|in-progress|blocked|completed

# By epic/story
./query-tasks.sh epic EPIC-001
./query-tasks.sh story STORY-002

# By persona
./query-tasks.sh persona developer|qa|architect

# By priority
./query-tasks.sh priority high|medium|low

# Count tasks
./query-tasks.sh status pending --format count
```

### Archive Management
```bash
# Preview archive
./archive-tasks.sh --month 2025-01 --dry-run

# Archive month
./archive-tasks.sh --month 2025-01

# Archive all completed
./archive-tasks.sh --all
```

## Task ID Format
```
TASK-{EPIC}-{STORY}-{SEQUENCE}
TASK-001-002-03 = Epic 1, Story 2, Task 3
```

## Task States
- **pending** - Not started
- **in-progress** - Being worked on
- **blocked** - Waiting on dependencies
- **review** - Awaiting review
- **completed** - Done
- **cancelled** - Won't complete

## Output Formats
```bash
--format full     # Complete task details (default)
--format summary  # One-line summaries  
--format id       # Just task IDs
--format count    # Count only
```

## Quick Recipes

### Morning Standup
```bash
# What I completed yesterday
./query-tasks.sh status completed | grep "$(date -d yesterday +%Y-%m-%d)"

# What I'm working on today
./query-tasks.sh persona $USER | grep in-progress

# Any blockers
./query-tasks.sh status blocked
```

### Sprint Planning
```bash
# Available high-priority tasks
./query-tasks.sh priority high | grep pending

# Story point totals
./query-tasks.sh story STORY-001 --format full | grep Estimate

# Dependencies check
./query-tasks.sh ready --format summary
```

### End of Sprint
```bash
# Completed this sprint
./query-tasks.sh status completed | grep "2025-01-"

# Remaining work
./query-tasks.sh status pending --format count
./query-tasks.sh status in-progress --format count

# Archive completed
./archive-tasks.sh --month 2025-01
```