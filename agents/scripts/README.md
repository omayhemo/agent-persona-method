# AP Agent Scripts

This directory contains project-agnostic scripts for managing parallel agent execution using Git worktrees.

## Prerequisites

Before using these scripts, set the following environment variables:

```bash
export AP_ROOT="/path/to/your/ap/setup"          # Where agents folder is located
export PROJECT_ROOT="/path/to/your/project"       # Your project's root directory
export PROJECT_NAME="YourProject"                 # Your project name
export OBSIDIAN_VAULT="YourVault"                # Obsidian vault name for coordination
```

## Available Scripts

### ap-env.sh
Sets up the AP environment with all necessary variables and paths.

```bash
source $AP_ROOT/agents/scripts/ap-env.sh
```

### setup-agent-worktrees.sh
Creates Git worktrees for all agents to enable parallel development.

```bash
# After sourcing ap-env.sh
bash $AP_ROOT/agents/scripts/setup-agent-worktrees.sh
```

### agent-switch.sh
Switches between different agent contexts with audio announcements.

```bash
# Switch to frontend developer agent
bash $AP_ROOT/agents/scripts/agent-switch.sh dev-frontend

# Switch to QA agent
bash $AP_ROOT/agents/scripts/agent-switch.sh qa

# Return to orchestrator (main repo)
bash $AP_ROOT/agents/scripts/agent-switch.sh orchestrator
```

### parallel-sprint.sh
Launches multiple agents in parallel using tmux for sprint work.

```bash
# Launch default agents (dev-frontend, dev-backend, qa)
bash $AP_ROOT/agents/scripts/parallel-sprint.sh

# Launch specific agents
bash $AP_ROOT/agents/scripts/parallel-sprint.sh --agents dev-frontend,dev-backend,architect

# Launch with custom sprint name
bash $AP_ROOT/agents/scripts/parallel-sprint.sh --sprint feature-auth --agents dev-frontend,dev-backend
```

## Customization

### Custom Agent Configuration

Create `.ap-agents` in your project root to define custom agents:

```bash
# .ap-agents
create_worktree "dev-api" "agent/dev/api-main"
create_worktree "dev-ui" "agent/dev/ui-main"
create_worktree "dev-services" "agent/dev/services-main"
```

### Default Sprint Agents

Create `.ap-default-agents` in your project root:

```bash
# .ap-default-agents
AGENTS_TO_LAUNCH=("dev-api" "dev-ui" "qa" "architect")
```

### Agent-Specific Instructions

Create `.agent-instructions.md` in any worktree to provide agent-specific guidance:

```markdown
# Frontend Developer Agent

## Focus Areas
- React components
- State management
- UI/UX implementation

## Key Commands
- `npm run dev` - Start development server
- `npm test` - Run tests
- `npm run build` - Build for production
```

## Integration with Claude Code

These scripts are designed to work seamlessly with Claude Code:

1. Each worktree can run its own Claude instance
2. Agents share memory through Obsidian vault
3. Audio notifications announce agent activities
4. Session notes track work across agents

## Troubleshooting

### tmux not found
Install tmux:
- Ubuntu/Debian: `sudo apt-get install tmux`
- macOS: `brew install tmux`
- RHEL/CentOS: `sudo yum install tmux`

### Worktree already exists
Remove the worktree:
```bash
git worktree remove $PROJECT_ROOT/$PROJECT_NAME-agent-name
```

### Port conflicts
Each worktree automatically gets unique ports. Check `.env` files if conflicts occur.

### Voice scripts not working
Ensure the voice scripts are executable:
```bash
chmod +x $AP_ROOT/agents/voice/*.sh
```