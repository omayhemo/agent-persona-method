# Git Worktrees for Parallel Agent Execution

## Overview

This document outlines the implementation of Git worktrees to enable parallel execution of multiple Claude Code agents on any project using the AP (Agent Persona) methodology. This approach transforms the AP methodology from sequential agent switching to true parallel execution, dramatically increasing development velocity.

## Prerequisites

Before implementing parallel agents, ensure these environment variables are set:

```bash
export AP_ROOT="/path/to/your/ap/setup"          # Where agents folder is located
export PROJECT_ROOT="/path/to/your/project"       # Your project's root directory
export PROJECT_NAME="YourProject"                 # Your project name
export OBSIDIAN_VAULT="YourVault"                # Obsidian vault name for coordination

# Voice script paths (relative to AP_ROOT)
export SPEAK_ORCHESTRATOR="$AP_ROOT/agents/voice/speakLessac.sh"
export SPEAK_DEVELOPER="$AP_ROOT/agents/voice/speakJoe.sh"
export SPEAK_ARCHITECT="$AP_ROOT/agents/voice/speakHFCMale.sh"
export SPEAK_QA="$AP_ROOT/agents/voice/speakAmy.sh"
export SPEAK_ANALYST="$AP_ROOT/agents/voice/speakHFCMale.sh"
export SPEAK_SM="$AP_ROOT/agents/voice/speakHFC.sh"
export SPEAK_PO="$AP_ROOT/agents/voice/speakKristin.sh"
```

## Architecture

### Worktree Structure

```
$PROJECT_ROOT/                               # Main repository (Orchestrator)
├── $PROJECT_NAME/                          # Main project directory
├── $PROJECT_NAME-dev-frontend/             # Developer Agent 1: Frontend features
├── $PROJECT_NAME-dev-backend/              # Developer Agent 2: Backend/API work
├── $PROJECT_NAME-dev-feature-{n}/          # Developer Agent N: Feature work
├── $PROJECT_NAME-architect-agent/          # Architect Agent
├── $PROJECT_NAME-qa-agent/                 # QA Agent
├── $PROJECT_NAME-analyst-agent/            # Analyst Agent
└── $PROJECT_NAME-scrum-agent/              # Scrum Master Agent
```

### Key Benefits

1. **Concurrent Development**: Multiple agents working on different features/tasks simultaneously
2. **No Code Conflicts**: Complete file system isolation between agents
3. **Shared Memory**: All agents access the same Obsidian vault for coordination
4. **Unified Git History**: All work merges back to the main repository
5. **10x Velocity**: Multiple developers = multiplied code output

## Branch Strategy

- **Main branch**: `main` or `master` - Production-ready code
- **Agent branches**: 
  - `agent/dev/{feature-name}` - Developer work
  - `agent/architect/{design-name}` - Architecture changes
  - `agent/qa/{test-suite}` - QA test implementations
  - `agent/analyst/{analysis-task}` - Analysis tasks
  - `agent/scrum/{sprint-name}` - Sprint coordination

## Agent Coordination Protocol

### Memory Management (Obsidian MCP)

- All agents share the same Obsidian vault at `$PROJECT_ROOT/$OBSIDIAN_VAULT/`
- Each agent creates session notes: `Sessions/YYYY-MM-DD-{AgentName}-{Task}.md`
- Agents check other agents' session notes before starting work
- Conflict resolution documented in `Rules/Agent-Conflicts.md`

### Communication Flow

```
1. Orchestrator assigns task → Creates Obsidian task note
2. Assigned agent picks up task → Updates task status in Obsidian
3. Agent works in isolated worktree → Documents progress in session notes
4. Agent completes task → Creates PR from worktree branch
5. Other agents review → Add review notes in Obsidian
6. Orchestrator merges → Updates project status
```

### Coordination Document Structure

```markdown
# $OBSIDIAN_VAULT/Coordination/active-agents.md

## Active Developer Agents (YYYY-MM-DD)

### Frontend Team
- **Agent**: dev-frontend
- **Task**: UI Components Implementation
- **Branch**: agent/dev/ui-components
- **Port**: 3001
- **Status**: 🚧 In Progress
- **Session**: Sessions/YYYY-MM-DD-DevFrontend-UI.md

### Backend Team  
- **Agent**: dev-backend
- **Task**: API Development
- **Branch**: agent/dev/api-endpoints
- **Port**: 3002
- **Status**: ✅ Testing
- **Session**: Sessions/YYYY-MM-DD-DevBackend-API.md
```

## Parallel Development Patterns

### Feature Team Approach

Multiple developer agents work on related features:

```bash
# Frontend Developer Agent
cd $PROJECT_ROOT/$PROJECT_NAME-dev-frontend
git checkout -b agent/dev/feature-ui
$SPEAK_DEVELOPER "Starting UI implementation"

# Backend Developer Agent (simultaneously)
cd $PROJECT_ROOT/$PROJECT_NAME-dev-backend
git checkout -b agent/dev/feature-api
$SPEAK_DEVELOPER "Creating API endpoints"

# QA Agent (testing both)
cd $PROJECT_ROOT/$PROJECT_NAME-qa-agent
git checkout -b agent/qa/feature-tests
$SPEAK_QA "Writing integration tests"
```

### Story-Based Parallelization

Different agents work on different stories from the backlog:

```bash
# Dev Agent 1: Story A
cd $PROJECT_ROOT/$PROJECT_NAME-dev-1
git checkout -b agent/dev/story-a

# Dev Agent 2: Story B
cd $PROJECT_ROOT/$PROJECT_NAME-dev-2  
git checkout -b agent/dev/story-b

# Dev Agent 3: Story C
cd $PROJECT_ROOT/$PROJECT_NAME-dev-3
git checkout -b agent/dev/story-c
```

### Microservice Pattern

Each developer agent owns a specific service:

- **Dev-API**: API service development
- **Dev-Worker**: Worker service development  
- **Dev-Frontend**: Frontend development
- **Dev-Services**: Backend services development

## Port Configuration

Each agent worktree needs unique ports to avoid conflicts. Configure in `.env`:

```bash
# $PROJECT_NAME-dev-frontend/.env
APP_PORT=3001
API_PORT=4001

# $PROJECT_NAME-dev-backend/.env
APP_PORT=3002
API_PORT=4002

# Add more as needed...
```

## Key Considerations

### Database Connections
- Each worktree needs the same database configuration
- Consider using a shared `.env.shared` file sourced by all worktrees

### Shared Dependencies
- Package manager workspace links need proper setup per worktree
- Run package installation in each worktree after creation

### CI/CD Integration
- Each agent branch can have its own CI pipeline
- Use branch protection rules for agent branches
- Require PR reviews from other agents

### Conflict Resolution
- Document merge conflicts in Obsidian
- Use `Rules/Agent-Conflicts.md` for resolution patterns
- Orchestrator has final say on conflicts

## Advanced Patterns

### Pair Programming Mode
Two developer agents work on the same feature:
- Dev-1: Writes implementation
- Dev-2: Writes tests simultaneously
- Both share branch via frequent commits

### Feature Flag Development
Multiple features developed in parallel:
- Each dev agent works behind feature flags
- All can merge to main without conflicts
- Features activated independently

### Continuous Integration
- Smaller, more frequent merges
- Each agent creates micro-PRs
- Automated testing on each agent branch

## Monitoring and Metrics

Track agent productivity in Obsidian:

```markdown
# $OBSIDIAN_VAULT/Metrics/agent-productivity.md

## Week of YYYY-MM-DD

### Developer Agents
| Agent | Stories Completed | Lines Changed | PRs Merged |
|-------|------------------|---------------|------------|
| dev-frontend | 3 | +1,245 -423 | 5 |
| dev-backend | 2 | +892 -156 | 3 |
| dev-feature | 1 | +567 -89 | 2 |

### Quality Metrics
- Test Coverage: 87%
- Build Success Rate: 95%
- Average PR Review Time: 2.5 hours
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   - Solution: Ensure each worktree has unique ports in .env

2. **Package Install Failures**
   - Solution: Clear node_modules and lock files, reinstall

3. **Merge Conflicts**
   - Solution: Use Orchestrator to resolve, document in Obsidian

4. **Worktree Cleanup**
   ```bash
   # Remove worktree
   git worktree remove $PROJECT_ROOT/$PROJECT_NAME-dev-frontend
   git branch -d agent/dev/frontend-main
   ```

## Implementation Scripts

The following scripts are available in the `$AP_ROOT/agents/scripts/` directory:

- `setup-agent-worktrees.sh` - Creates all agent worktrees
- `agent-switch.sh` - Switches between agent contexts
- `parallel-sprint.sh` - Launches multiple agents for sprint work

To use these scripts with your project:

1. Set the required environment variables
2. Run `source $AP_ROOT/agents/scripts/ap-env.sh` to load the environment
3. Execute the desired script

## Conclusion

Git worktrees enable true parallel development with the AP methodology, transforming any project into a high-velocity, coordinated effort. The combination of isolated worktrees and shared Obsidian memory creates an optimal environment for multi-agent collaboration.