# AP Method - Agent Persona Methodology

The AP (Agent Persona) method is a project-agnostic approach to orchestrating AI agents for software development. This system provides specialized agent personas, each with specific expertise and responsibilities.

## Quick Start

1. **Run the setup script:**
   ```bash
   ./agents/agentic-setup
   ```

2. **Source the environment:**
   ```bash
   source .env.ap
   ```

3. **Launch the orchestrator:**
   ```
   /ap
   ```

## Overview

The AP Method leverages specialized AI agents to handle different aspects of software development:

- **AP Orchestrator** - Central coordinator and method expert
- **Analyst** - Research, requirements gathering, project briefs
- **Product Manager** - PRDs, epics, high-level planning
- **Architect** - System design, technical architecture
- **Design Architect** - UI/UX, frontend architecture
- **Product Owner** - Backlog management, story validation
- **Scrum Master** - Story generation, sprint planning
- **Developer** - Code implementation
- **QA** - Quality assurance, testing strategies

## Features

- 🎭 **Specialized Agent Personas** - Each agent has specific expertise and responsibilities
- 🎯 **Project-Agnostic** - Works with any software project
- 🔊 **Voice Integration** - Text-to-speech notifications for agent activities
- 📝 **Session Management** - Track work across sessions with Obsidian or markdown
- 🚀 **Parallel Development** - Support for Git worktrees and concurrent agents
- 📋 **Comprehensive Templates** - Pre-built templates for all documentation types

## Installation

### Prerequisites

- Git
- Node.js (for scripts)
- Claude Code CLI or compatible AI interface
- (Optional) Obsidian for enhanced session management

### Setup

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd agentic-persona
   ```

2. Run the setup script:
   ```bash
   ./agents/agentic-setup
   ```

3. Follow the prompts to configure:
   - Project name and paths
   - Session notes system (Obsidian or markdown)
   - Documentation structure

### Voice Setup (Optional)

To enable voice notifications:

```bash
./agents/scripts/setup-piper-chat.sh
```

This installs the Piper TTS system with 9 different US English voices.

## Usage

### Basic Workflow

1. **Start with Analysis**
   ```
   /ap
   Select: Analyst
   Task: Create project brief
   ```

2. **Create PRD**
   ```
   Select: PM
   Task: Create PRD from brief
   ```

3. **Design Architecture**
   ```
   Select: Architect
   Task: Create architecture document
   ```

4. **Generate Stories**
   ```
   Select: SM
   Task: Generate next story
   ```

5. **Implement**
   ```
   Select: Developer
   Task: Implement story
   ```

### Available Commands

After setup, these commands are available in Claude:

- `/ap` - Launch AP Orchestrator
- `/wrap` - Wrap up current session
- `/harmonize-epics` - Harmonize epic files
- `/harmonize-stories` - Harmonize story files
- `/session-note-setup` - Set up session structure

## Project Structure

```
agentic-persona/
├── agents/
│   ├── personas/        # Agent personality definitions
│   ├── tasks/          # Reusable task definitions
│   ├── templates/      # Document templates
│   ├── checklists/     # Quality checklists
│   ├── voice/          # Voice scripts (TTS)
│   ├── scripts/        # Utility scripts
│   └── data/           # Knowledge base and preferences
├── project_documentation/  # Generated during use
│   ├── base/          # Core documents (PRD, architecture)
│   ├── epics/         # Epic documentation
│   ├── stories/       # User stories
│   └── qa/            # Test documentation
└── .env.ap            # Environment configuration (generated)
```

## Advanced Features

### Parallel Development

Set up Git worktrees for parallel agent work:

```bash
bash $AP_ROOT/agents/scripts/setup-agent-worktrees.sh
bash $AP_ROOT/agents/scripts/parallel-sprint.sh
```

### Custom Agents

Create custom agent configurations in `.ap-agents`:

```bash
create_worktree "dev-api" "agent/dev/api-main"
create_worktree "dev-ui" "agent/dev/ui-main"
```

### Session Management

- **Obsidian MCP**: Automatic session tracking and archiving
- **Markdown**: Manual session notes with structured format
- **Fallback**: Automatic fallback to local files if Obsidian unavailable

## Documentation

- [Agent Roles and Responsibilities](agents/data/ap-kb.md)
- [Communication Standards](agents/personas/communication_standards.md)
- [Script Documentation](agents/scripts/README.md)

## Contributing

The AP Method is designed to be extended and customized:

1. Add new agent personas in `agents/personas/`
2. Create new task definitions in `agents/tasks/`
3. Extend templates in `agents/templates/`
4. Add custom checklists in `agents/checklists/`

## License

MIT License - See [ap-kb.md](agents/data/ap-kb.md) for details

## Support

- Create issues for bugs or feature requests
- Check existing documentation in `agents/data/ap-kb.md`
- Review agent-specific instructions in `agents/personas/`

---

The AP Method - Elevating AI-assisted development through specialized agent orchestration.