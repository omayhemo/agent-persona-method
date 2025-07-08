#!/bin/bash
# parallel-sprint.sh
# Launches multiple agents in parallel for sprint work
# Project-agnostic version using environment variables

set -e

# Source the AP environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ap-env.sh" || exit 1

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 ${PROJECT_NAME} Parallel Sprint Launcher${NC}"
echo -e "${YELLOW}====================================${NC}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is not installed. Please install tmux first.${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install tmux"
    echo "  macOS: brew install tmux"
    echo "  RHEL/CentOS: sudo yum install tmux"
    exit 1
fi

# Parse command line arguments
AGENTS_TO_LAUNCH=()
SPRINT_NAME="sprint-$(date +%Y-%m-%d)"

while [[ $# -gt 0 ]]; do
    case $1 in
        --agents)
            shift
            IFS=',' read -ra AGENTS_TO_LAUNCH <<< "$1"
            ;;
        --sprint)
            shift
            SPRINT_NAME="$1"
            ;;
        --help)
            echo "Usage: $0 [--agents agent1,agent2,...] [--sprint sprint-name]"
            echo ""
            echo "Examples:"
            echo "  $0 --agents dev-frontend,dev-backend,qa"
            echo "  $0 --agents dev-frontend,dev-backend --sprint feature-auth"
            echo "  $0  # Uses default agents"
            echo ""
            echo "Available standard agents:"
            echo "  - dev-frontend, dev-backend"
            echo "  - qa, architect, analyst, scrum"
            echo ""
            echo "You can also use custom agents defined in your project"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
    shift
done

# Default agents if none specified
if [ ${#AGENTS_TO_LAUNCH[@]} -eq 0 ]; then
    # Check for project-specific default
    if [ -f "$PROJECT_DIR/.ap-default-agents" ]; then
        source "$PROJECT_DIR/.ap-default-agents"
    else
        AGENTS_TO_LAUNCH=("dev-frontend" "dev-backend" "qa")
    fi
fi

# Announce sprint start
[ -f "$SPEAK_ORCHESTRATOR" ] && "$SPEAK_ORCHESTRATOR" "Starting parallel sprint $SPRINT_NAME for $PROJECT_NAME with ${#AGENTS_TO_LAUNCH[@]} agents"

echo -e "\n${YELLOW}📋 Sprint Configuration${NC}"
echo -e "Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "Sprint Name: ${GREEN}$SPRINT_NAME${NC}"
echo -e "Agents: ${GREEN}${AGENTS_TO_LAUNCH[*]}${NC}"

# Create sprint coordination document
SPRINT_DOC="$COORDINATION_DIR/sprints/$SPRINT_NAME.md"
mkdir -p "$(dirname "$SPRINT_DOC")"

cat > "$SPRINT_DOC" << EOF
# Sprint: $SPRINT_NAME

**Project**: $PROJECT_NAME
**Started**: $(date +"%Y-%m-%d %H:%M:%S")
**Agents**: ${AGENTS_TO_LAUNCH[*]}

## Active Agents

EOF

# Function to get agent-specific voice script
get_agent_voice() {
    case $1 in
        dev-*) echo "$SPEAK_DEVELOPER" ;;
        architect*) echo "$SPEAK_ARCHITECT" ;;
        qa*) echo "$SPEAK_QA" ;;
        analyst*) echo "$SPEAK_ANALYST" ;;
        scrum*) echo "$SPEAK_SM" ;;
        po*) echo "$SPEAK_PO" ;;
        *) echo "$SPEAK_ORCHESTRATOR" ;;
    esac
}

# Launch agents in tmux sessions
echo -e "\n${YELLOW}🚀 Launching Agents${NC}"

for agent in "${AGENTS_TO_LAUNCH[@]}"; do
    # Determine worktree directory
    if [[ "$agent" =~ ^dev- ]]; then
        WORKTREE_DIR="$PROJECT_ROOT/$PROJECT_NAME-${agent}"
    else
        WORKTREE_DIR="$PROJECT_ROOT/$PROJECT_NAME-${agent}-agent"
    fi
    
    # Check if worktree exists
    if [ ! -d "$WORKTREE_DIR" ]; then
        echo -e "${RED}⚠️  Worktree for $agent not found at $WORKTREE_DIR${NC}"
        echo "   Run setup-agent-worktrees.sh first"
        continue
    fi
    
    # Check if session already exists
    if tmux has-session -t "$agent" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Session $agent already exists - attaching to existing session${NC}"
    else
        # Create tmux session with agent
        echo -e "${GREEN}✅ Launching $agent agent${NC}"
        
        # Create startup script for the agent
        STARTUP_SCRIPT="/tmp/start-${PROJECT_NAME}-${agent}.sh"
        VOICE_SCRIPT=$(get_agent_voice "$agent")
        
        cat > "$STARTUP_SCRIPT" << EOSCRIPT
#!/bin/bash
cd $WORKTREE_DIR

# Set up environment
export AGENT_NAME="$agent"
export PROJECT_NAME="$PROJECT_NAME"
export OBSIDIAN_VAULT="$OBSIDIAN_VAULT"

echo -e "${GREEN}Welcome to $agent agent for $PROJECT_NAME!${NC}"
echo -e "${YELLOW}Worktree: $WORKTREE_DIR${NC}"
echo -e "${YELLOW}Branch: \$(git branch --show-current)${NC}"
echo ""

# Announce agent start
[ -f "$VOICE_SCRIPT" ] && "$VOICE_SCRIPT" "$agent agent ready for $PROJECT_NAME development"

# Show any agent-specific instructions
if [ -f ".agent-instructions.md" ]; then
    echo -e "${BLUE}Agent Instructions:${NC}"
    cat .agent-instructions.md
    echo ""
fi

echo -e "${BLUE}Starting Claude...${NC}"

# Launch Claude
exec claude
EOSCRIPT
        
        chmod +x "$STARTUP_SCRIPT"
        
        # Launch tmux session
        tmux new-session -d -s "$agent" "$STARTUP_SCRIPT"
    fi
    
    # Update sprint document
    cat >> "$SPRINT_DOC" << EOF
### $agent
- **Status**: 🟢 Active
- **Worktree**: \`$WORKTREE_DIR\`
- **Session**: tmux attach -t $agent
- **Task**: [To be assigned]
- **Notes**: 

EOF
done

# Add coordination section to sprint document
cat >> "$SPRINT_DOC" << EOF

## Coordination Protocol

1. **Task Assignment**: Update this document with assigned tasks
2. **Status Updates**: Agents update their status every 30 minutes
3. **Blockers**: Document any blockers immediately
4. **Communication**: Use Obsidian session notes for detailed updates

## Sprint Goals

1. [Add sprint goal 1]
2. [Add sprint goal 2]
3. [Add sprint goal 3]

## Daily Standups

### $(date +%Y-%m-%d) Standup
- **Time**: [Schedule time]
- **Attendees**: All active agents
- **Format**: Each agent reports progress, plans, blockers

## Sprint Metrics

- **Stories Planned**: 0
- **Stories Completed**: 0
- **Blockers**: 0
- **Test Coverage**: 0%

## Communication Channels

- **Coordination**: This document
- **Details**: Agent session notes in $SESSIONS_DIR
- **Rules**: $RULES_DIR
- **Architecture**: Project documentation

## Notes

- Remember to update agent status regularly
- Create session notes for detailed work logs
- Coordinate through this document
- Check other agents' work before starting related tasks
EOF

echo -e "\n${GREEN}✅ Sprint coordination document created${NC}"
echo -e "   ${BLUE}$SPRINT_DOC${NC}"

# Create active agents summary
ACTIVE_DOC="$COORDINATION_DIR/active-agents.md"
cat > "$ACTIVE_DOC" << EOF
# Active Agents - $PROJECT_NAME

**Updated**: $(date +"%Y-%m-%d %H:%M:%S")
**Sprint**: $SPRINT_NAME

## Currently Active

EOF

for agent in "${AGENTS_TO_LAUNCH[@]}"; do
    cat >> "$ACTIVE_DOC" << EOF
### $agent
- **Sprint**: $SPRINT_NAME
- **Session**: \`tmux attach -t $agent\`
- **Status**: 🟢 Active
- **Current Task**: [Update when assigned]

EOF
done

# Show active sessions
echo -e "\n${YELLOW}📺 Active Agent Sessions${NC}"
tmux list-sessions 2>/dev/null | grep -E "(${AGENTS_TO_LAUNCH[*]// /|})" || echo "Launching sessions..."

# Instructions
echo -e "\n${YELLOW}📖 Quick Commands${NC}"
echo -e "${GREEN}Attach to agent:${NC} tmux attach -t <agent-name>"
echo -e "${GREEN}List all sessions:${NC} tmux ls"
echo -e "${GREEN}Switch between agents:${NC} Ctrl+b, s (while in tmux)"
echo -e "${GREEN}Detach from agent:${NC} Ctrl+b, d (while in tmux)"
echo -e "${GREEN}Kill agent session:${NC} tmux kill-session -t <agent-name>"

# Create convenience scripts
SCRIPTS_DIR="$PROJECT_DIR/.ap-scripts"
mkdir -p "$SCRIPTS_DIR"

# Create attach script
cat > "$SCRIPTS_DIR/attach-agents.sh" << EOF
#!/bin/bash
# Show and attach to active sprint agents

echo "Active $PROJECT_NAME agents:"
tmux ls 2>/dev/null | grep -E "(${AGENTS_TO_LAUNCH[*]// /|})" || echo "No agents running"

echo ""
echo "Attach to specific agent: tmux attach -t <agent-name>"
echo "Or select from list: tmux attach"
EOF

# Create status script
cat > "$SCRIPTS_DIR/agent-status.sh" << EOF
#!/bin/bash
# Show status of all agents

echo "=== $PROJECT_NAME Agent Status ==="
echo ""

for agent in ${AGENTS_TO_LAUNCH[*]}; do
    echo -n "\$agent: "
    if tmux has-session -t "\$agent" 2>/dev/null; then
        echo "🟢 Running"
    else
        echo "🔴 Stopped"
    fi
done

echo ""
echo "Sprint: $SPRINT_NAME"
echo "Coordination: $SPRINT_DOC"
EOF

chmod +x "$SCRIPTS_DIR"/*.sh

echo -e "\n${BLUE}🎯 Sprint $SPRINT_NAME is now active!${NC}"
echo -e "\n${YELLOW}💡 Helpful scripts created:${NC}"
echo "  - ${GREEN}.ap-scripts/attach-agents.sh${NC} - Show active agents"
echo "  - ${GREEN}.ap-scripts/agent-status.sh${NC} - Check agent status"

# Final announcement
[ -f "$SPEAK_ORCHESTRATOR" ] && "$SPEAK_ORCHESTRATOR" "All agents launched. Sprint $SPRINT_NAME is active."