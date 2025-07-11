# AP Method - Agent Persona Methodology

The AP (Agent Persona) method is a project-agnostic approach to orchestrating AI agents for software development. This system provides specialized agent personas, each with specific expertise and responsibilities.

## Quick Start

### Install from GitHub Release (Recommended)

```bash
# Download and extract in one command
curl -L https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz | tar -xz

# Run the installer
./installer/install.sh
```

### Silent Install Option

```bash
# Download, extract, and install with defaults in one command
curl -L https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz | tar -xz && ./installer/install.sh -d
```

### Update Management

After installation, use the built-in manager for updates and maintenance:

```bash
# Check for updates
agents/scripts/ap-manager.sh update

# Verify installation
agents/scripts/ap-manager.sh verify

# Show version
agents/scripts/ap-manager.sh version
```

### Install from Source

1. **Clone and build:**
   ```bash
   git clone https://github.com/omayhemo/agent-persona-method.git
   cd agent-persona-method
   ./build-distribution.sh
   cd dist
   tar -xzf ap-method-v*.tar.gz
   ./installer/install.sh
   ```

2. **Launch the orchestrator in Claude:**
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

- Bash shell
- Git (recommended)
- Node.js (for some utilities)
- Claude Code CLI or compatible AI interface
- (Optional) Obsidian for enhanced session management

### Option 1: Install from Release (Easiest)

```bash
# Download and install in your project directory
cd /path/to/your/project
curl -L https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz | tar -xz
./installer/install.sh

# Or download first, then extract
curl -LO https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz
tar -xzf ap-method-v1.0.0.tar.gz
./installer/install.sh
```

**Note:** The installer is preserved in `agents/.installer/` for future updates and management.

### Option 2: Install from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/omayhemo/agent-persona-method.git
   cd agent-persona-method
   ```

2. Build and run installer:
   ```bash
   ./build-distribution.sh
   cd dist
   tar -xzf ap-method-v*.tar.gz
   ./installer/install.sh
   ```

3. Follow the prompts to configure:
   - Project name and paths
   - Session notes system (Obsidian or markdown)
   - Documentation structure

### Unattended Installation

For automated deployments:
```bash
# Install with all defaults - no prompts
./installer/install.sh --defaults
# or
./installer/install.sh -d
```

### Voice Setup (Optional)

To enable voice notifications:

```bash
./installer/templates/scripts/tts-setup/setup-piper-chat.sh
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

3. **Architecture**
   ```
   Select: Architect
   Task: Create a Architectural Documentation
   ```

3. **Design Architecture**
   ```
   Select: Design Architect
   Task: Create a Design Document, Generate Prompts for Lovable
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
- `/handoff` - Hand off to another agent persona (direct transition)
- `/switch` - Compact session and switch to another agent persona
- `/wrap` - Wrap up current session
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