#!/bin/bash
# agent-switch.sh
# Switches between different agent worktrees with appropriate audio announcements
# Project-agnostic version using environment variables

set -e

# Source the AP environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ap-env.sh" || exit 1

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if agent name provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No agent specified${NC}"
    echo "Usage: $0 <agent-name>"
    echo ""
    echo "Available agents (standard):"
    echo "  - dev-frontend"
    echo "  - dev-backend"
    echo "  - architect"
    echo "  - qa"
    echo "  - analyst"
    echo "  - scrum"
    echo "  - orchestrator (main repo)"
    echo ""
    echo "Or any custom agents defined in your project"
    exit 1
fi

AGENT=$1

# Determine worktree directory
if [ "$AGENT" = "orchestrator" ]; then
    WORKTREE_DIR="$PROJECT_DIR"
else
    # Handle both with and without -agent suffix
    if [[ "$AGENT" =~ ^dev- ]]; then
        WORKTREE_DIR="$PROJECT_ROOT/$PROJECT_NAME-${AGENT}"
    else
        WORKTREE_DIR="$PROJECT_ROOT/$PROJECT_NAME-${AGENT}-agent"
    fi
fi

# Check if worktree exists
if [ ! -d "$WORKTREE_DIR" ]; then
    echo -e "${RED}Error: Agent worktree $WORKTREE_DIR does not exist${NC}"
    echo "Run setup-agent-worktrees.sh first to create worktrees"
    exit 1
fi

# Get current directory for context
CURRENT_DIR=$(pwd)

echo -e "${YELLOW}🔄 Switching from $CURRENT_DIR to $WORKTREE_DIR${NC}"

# Function to announce with appropriate voice
announce_switch() {
    local agent=$1
    local message=$2
    
    case $agent in
        "orchestrator")
            [ -f "$SPEAK_ORCHESTRATOR" ] && "$SPEAK_ORCHESTRATOR" "$message"
            ;;
        dev-*)
            [ -f "$SPEAK_DEVELOPER" ] && "$SPEAK_DEVELOPER" "$message"
            ;;
        "architect")
            [ -f "$SPEAK_ARCHITECT" ] && "$SPEAK_ARCHITECT" "$message"
            ;;
        "qa")
            [ -f "$SPEAK_QA" ] && "$SPEAK_QA" "$message"
            ;;
        "analyst")
            [ -f "$SPEAK_ANALYST" ] && "$SPEAK_ANALYST" "$message"
            ;;
        "scrum")
            [ -f "$SPEAK_SM" ] && "$SPEAK_SM" "$message"
            ;;
        "po")
            [ -f "$SPEAK_PO" ] && "$SPEAK_PO" "$message"
            ;;
        *)
            [ -f "$SPEAK_ORCHESTRATOR" ] && "$SPEAK_ORCHESTRATOR" "$message"
            ;;
    esac
}

# Announce context switch
announce_switch "$AGENT" "Switching to ${AGENT} context in ${PROJECT_NAME}"

# Change to worktree directory
cd "$WORKTREE_DIR"

# Show current branch and status
echo -e "${GREEN}✅ Switched to $AGENT agent${NC}"
echo -e "${YELLOW}Current branch:${NC}"
git branch --show-current

echo -e "\n${YELLOW}Git status:${NC}"
git status -s

# Show recent commits
echo -e "\n${YELLOW}Recent commits:${NC}"
git log --oneline -5

# Show any active TODOs if present
if [ -f "TODO.md" ]; then
    echo -e "\n${YELLOW}Active TODOs:${NC}"
    head -10 TODO.md
fi

# Check for agent-specific instructions
if [ -f ".agent-instructions.md" ]; then
    echo -e "\n${YELLOW}Agent Instructions:${NC}"
    cat .agent-instructions.md
fi

echo -e "\n${GREEN}Ready to work in $AGENT context!${NC}"
echo -e "${YELLOW}Launch Claude with: claude${NC}"

# Create session note in Obsidian
SESSION_NOTE="$SESSIONS_DIR/$(date +%Y-%m-%d-%H-%M-%S)-${AGENT}-switch.md"
mkdir -p "$SESSIONS_DIR"

cat > "$SESSION_NOTE" << EOF
# Agent Switch: ${AGENT}

**Time**: $(date +"%Y-%m-%d %H:%M:%S")
**Project**: $PROJECT_NAME
**From**: $CURRENT_DIR
**To**: $WORKTREE_DIR
**Branch**: $(cd "$WORKTREE_DIR" && git branch --show-current)

## Context
Switched to ${AGENT} agent for parallel development work.

## Current Status
\`\`\`
$(cd "$WORKTREE_DIR" && git status -s)
\`\`\`

## Notes
- Ready for ${AGENT} specific tasks
- Check Coordination folder for active work items
- Update this note with work performed

## Tasks
[ ] Review current branch state
[ ] Check for any pending work
[ ] Update coordination document
EOF

echo -e "${GREEN}   ✓ Created session note: $(basename "$SESSION_NOTE")${NC}"

# Show coordination status if available
if [ -f "$COORDINATION_DIR/active-agents.md" ]; then
    echo -e "\n${YELLOW}Active Agents Status:${NC}"
    grep -A 3 "### $AGENT" "$COORDINATION_DIR/active-agents.md" 2>/dev/null || echo "No active status found"
fi