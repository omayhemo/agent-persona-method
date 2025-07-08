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

## Setup Process

The `agentic-setup` script will guide you through:

1. **Project Configuration**
   - Project name
   - Documentation paths
   - Claude commands directory

2. **Session Notes System**
   - Choose between Obsidian MCP or Markdown files
   - Configure session note paths
   - Set up archive structure

3. **Environment Setup**
   - Creates `.env.ap` with all configuration
   - Sets up voice script paths
   - Configures project-specific variables

4. **Git Configuration**
   - Automatically updates `.gitignore`
   - Excludes session notes from version control
   - Excludes AP environment files
   - Creates new `.gitignore` if none exists

## Environment Variables

After setup, the following variables are available:

- `$AP_ROOT` - Path to agents directory
- `$PROJECT_DOCS` - Path to project documentation
- `$SPEAK_ORCHESTRATOR` - Orchestrator voice script
- `$SPEAK_DEVELOPER` - Developer voice script
- `$SPEAK_ARCHITECT` - Architect voice script
- `$SPEAK_ANALYST` - Analyst voice script
- `$SPEAK_QA` - QA voice script
- `$SPEAK_PM` - Product Manager voice script
- `$SPEAK_PO` - Product Owner voice script
- `$SPEAK_SM` - Scrum Master voice script

## Available Commands

After setup, these commands are available in Claude:

- `/ap` - Launch AP Orchestrator
- `/wrap` - Wrap up current session
- `/harmonize-epics` - Harmonize epic files
- `/harmonize-stories` - Harmonize story files
- `/session-note-setup` - Set up session structure

## Agent Personas

- **AP Orchestrator** - Central coordinator and method expert
- **Developer** - Implementation specialist
- **Architect** - System design expert
- **Design Architect** - UI/UX specialist
- **Analyst** - Requirements and research expert
- **QA** - Quality assurance specialist
- **Product Manager** - Market and strategy expert
- **Product Owner** - Business requirements expert
- **Scrum Master** - Process and story management

## Voice Scripts

All voice scripts are located in `agents/voice/`:
- Each agent has a dedicated voice script
- Scripts use text-to-speech for audio notifications
- Configured via environment variables for portability

## Session Management

### With Obsidian MCP
- Sessions stored in configured Obsidian vault
- Automatic archiving on wrap
- Cross-session memory via Obsidian links
- Automatic fallback to local files if Obsidian unavailable
- Fallback location: `$PROJECT_DOCS/session_notes/`

### With Markdown Files
- Sessions stored in local markdown files
- Manual archiving process
- Structured format for consistency

## Troubleshooting

1. **Script not found**: Ensure you've sourced `.env.ap`
2. **Voice scripts not working**: Check that scripts are executable
3. **Commands not available**: Verify `.claude/commands` directory exists
4. **Path issues**: All paths use environment variables for portability

## Making AP Method Portable

To use the AP method in another project:

1. Copy the entire `agents/` directory
2. Run `./agents/agentic-setup` in the new project
3. Configure for your specific needs
4. Source the generated `.env.ap`

The system is designed to be completely project-agnostic and portable across different codebases.