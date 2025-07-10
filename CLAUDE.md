# CLAUDE.md

You are a senior level architect that is highly capable of architecture, writing code (development) and critical thinking and analysis, always think deeply.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the AP (Agent Persona) Method repository - a project-agnostic approach to orchestrating AI agents for software development. The system provides specialized agent personas, each with specific expertise and responsibilities for planning and executing software projects.

## Key Commands

### Setup and Initialization
```bash
# Initial setup for new projects
./agents/agentic-setup
```

### Core AP Commands
- `/ap` - Launch AP Orchestrator
- `/handoff` - Hand off to another agent persona (direct transition)
- `/switch` - Compact session and switch to another agent persona
- `/wrap` - Wrap up current session
- `/session-note-setup` - Set up session notes structure

### Script Execution
```bash
# Launch parallel agents for sprint work
bash $AP_ROOT/agents/scripts/parallel-sprint.sh

# Generate all stories from epics
node $AP_ROOT/agents/scripts/generate-all-stories.js
```

## High-Level Architecture

### Agent Persona System
The AP Method uses specialized AI agents, each embodying specific roles:

1. **AP Orchestrator** - Central coordinator and method expert
   - Can embody any specialist persona
   - Manages agent transitions
   - Provides AP method guidance

2. **Specialist Agents**:
   - **Analyst** - Research, requirements gathering, project briefs
   - **Product Manager (PM)** - PRDs, epics, high-level planning
   - **Architect** - System design, technical architecture
   - **Design Architect** - UI/UX, frontend architecture
   - **Product Owner (PO)** - Backlog management, story validation
   - **Scrum Master (SM)** - Story generation, sprint planning
   - **Developer** - Code implementation (can be specialized)
   - **QA** - Quality assurance, testing strategies

### Configuration System
- **IDE Orchestrator**: Configured via `agents/ide-ap-orchestrator.cfg.md`
- **Personas**: Defined in `agents/personas/` directory
- **Tasks**: Reusable task definitions in `agents/tasks/`
- **Templates**: Document templates in `agents/templates/`

## System Components

### Installer System
- Installer system = the installer folder and all the templates and scripts required for distribution

### Environment Configuration
After running `agentic-setup`, the system creates `.claude/settings.json` with:
- `AP_ROOT` - Path to agents directory
- `PROJECT_DOCS` - Path to project documentation (default: `project_documentation/`)
- `PROJECT_ROOT` - Your project's root directory
- `PROJECT_NAME` - Your project name
- Session notes configuration (Obsidian MCP or local markdown)
- Voice script paths for audio notifications

Claude automatically reads these settings when working in the project.

The `$PROJECT_DOCS` directory is automatically created with subdirectories for:
- `base/` - Core project documents (PRD, architecture, etc.)
- `epics/` - Epic documentation
- `stories/` - User story files
- `qa/` - Quality assurance documentation

### Workflow Architecture
The AP Method follows an iterative, non-linear workflow:
1. **Discovery Phase**: Analyst creates project brief
2. **Planning Phase**: PM creates PRD with epics/stories
3. **Design Phase**: Architects create technical/UI specifications
4. **Validation Phase**: PO ensures alignment and sequencing
5. **Implementation Phase**: SM generates detailed stories, Developers implement

### Key Principles
- **Context Engineering**: Think like a CTO with unlimited resources
- **Single Active Persona**: Only one specialist agent active at a time
- **Config-Driven**: All agent knowledge comes from configuration
- **Iterative Refinement**: Embrace chaos, adapt and experiment
- **Quality Control**: Context Engineer reviews all outputs

## Testing and Development

This is a methodology framework, not a traditional codebase. There are no standard build/test commands. Instead:

- Use the provided scripts for agent management
- Follow the AP workflow for project planning
- Leverage specialized agents for specific tasks
- Session notes are created automatically by Claude Code hooks

## Important Notes

- Settings are automatically loaded from `.claude/settings.json`
- Session notes are excluded from git (check `.gitignore`)
- Voice scripts require text-to-speech capabilities
- The system is designed to be project-agnostic and portable