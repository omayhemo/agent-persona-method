# Claude Commands Directory

This directory contains command definitions for Claude Code that enable the AP Method's agent persona system.

## Command Structure

Each command file follows this structure:
```yaml
---
name: command-name
description: Brief description
---

# Command documentation and implementation
```

## Initialization Protocol

All persona activation commands follow a standardized initialization protocol:

### 1. Parallel Context Loading
Each persona loads 5 critical context sources in parallel using the Task tool:
- Persona configuration file
- Communication standards
- Relevant project documentation
- Templates and checklists
- Task definitions or existing work

### 2. Task Execution Pattern
```
*Executing parallel initialization tasks:*
[Use Task tool - ALL in single function_calls block]
- Task 1: Load persona configuration
- Task 2: Load communication standards
- Task 3: Check project documentation
- Task 4: Load relevant templates
- Task 5: Load checklists/tasks
```

### 3. Post-Initialization
- Voice announcement using persona-specific script
- Confirmation message with capabilities summary
- Present quick start options

## Command Categories

### Core Commands
- `ap.md` - AP Orchestrator activation
- `handoff.md` - Direct persona transfer
- `switch.md` - Session compaction and switch
- `wrap.md` - Session conclusion
- `session-note-setup.md` - Configure session notes

### Persona Activation Commands
- `analyst.md` - Analyst agent
- `pm.md` - Product Manager agent
- `architect.md` - System Architect agent
- `design-architect.md` - Design Architect agent
- `po.md` - Product Owner agent
- `sm.md` - Scrum Master agent
- `dev.md` - Developer agent
- `qa.md` - QA agent

### Utility Commands
- `personas.md` - List all available personas
- `buildit.md` - Build and test implementation
- `release.md` - Release management

## Best Practices

1. **Consistency**: All persona commands follow the same initialization pattern
2. **Performance**: Use parallel Task execution for faster activation
3. **Context**: Always load communication standards for consistent behavior
4. **Feedback**: Provide voice announcements and visual confirmation
5. **Guidance**: Present clear options after initialization

## Adding New Commands

When adding a new persona command:
1. Copy the initialization protocol from an existing persona
2. Update the 5 task paths to match the new persona
3. Modify the voice script path
4. Update the confirmation message
5. Add to `personas.md` list
6. Update CLAUDE.md documentation

## Technical Notes

- Commands are loaded by Claude Code automatically
- File paths in initialization must be absolute
- Voice scripts expect text as command line arguments
- Task tool calls must be in a single function_calls block for parallelism