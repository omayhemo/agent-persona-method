#!/bin/bash
# setup-agent-worktrees.sh
# Creates all agent worktrees for parallel AP development
# This script is project-agnostic and uses environment variables

set -e

# Source the AP environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ap-env.sh" || exit 1

echo "🚀 Setting up Agent Worktrees for $PROJECT_NAME"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo -e "${RED}Error: Not in project repository. Please run from $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Function to create worktree
create_worktree() {
    local name=$1
    local branch=$2
    local dir="$PROJECT_ROOT/$PROJECT_NAME-$name"
    
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}⚠️  Worktree $name already exists at $dir${NC}"
    else
        echo -e "${GREEN}✅ Creating worktree for $name agent${NC}"
        git worktree add "$dir" -b "$branch"
        
        # Setup environment
        cd "$dir"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            echo -e "${GREEN}   ✓ Created .env file${NC}"
        fi
        
        # Install dependencies based on package manager
        if [ -f "package.json" ]; then
            if [ -f "pnpm-lock.yaml" ]; then
                echo -e "${GREEN}   ✓ Installing dependencies with pnpm...${NC}"
                pnpm install
            elif [ -f "yarn.lock" ]; then
                echo -e "${GREEN}   ✓ Installing dependencies with yarn...${NC}"
                yarn install
            else
                echo -e "${GREEN}   ✓ Installing dependencies with npm...${NC}"
                npm install
            fi
        fi
        
        cd "$PROJECT_DIR"
    fi
}

# Allow custom agent configuration
if [ -f "$PROJECT_DIR/.ap-agents" ]; then
    echo -e "${YELLOW}📂 Loading custom agent configuration${NC}"
    source "$PROJECT_DIR/.ap-agents"
else
    # Default agent configuration
    echo -e "${YELLOW}📂 Using default agent configuration${NC}"
    
    # Create Developer Agent worktrees
    echo -e "\n${YELLOW}📂 Creating Developer Agent Worktrees${NC}"
    create_worktree "dev-frontend" "agent/dev/frontend-main"
    create_worktree "dev-backend" "agent/dev/backend-main"
    
    # Create Other Agent worktrees
    echo -e "\n${YELLOW}📂 Creating Specialized Agent Worktrees${NC}"
    create_worktree "architect-agent" "agent/architect/main"
    create_worktree "qa-agent" "agent/qa/main"
    create_worktree "analyst-agent" "agent/analyst/main"
    create_worktree "scrum-agent" "agent/scrum/main"
fi

# Update port configurations
echo -e "\n${YELLOW}🔧 Configuring unique ports for each worktree${NC}"

# Function to update ports in .env
update_ports() {
    local dir=$1
    local web_port=$2
    local api_port=$3
    
    if [ -f "$dir/.env" ]; then
        # Update or add port configurations
        # Handle different port variable names
        for port_var in "PORT" "APP_PORT" "NEXT_PUBLIC_APP_PORT" "WEB_PORT"; do
            if grep -q "$port_var" "$dir/.env"; then
                sed -i "s/$port_var=.*/$port_var=$web_port/" "$dir/.env"
            fi
        done
        
        for api_var in "API_PORT" "BACKEND_PORT" "SERVER_PORT"; do
            if grep -q "$api_var" "$dir/.env"; then
                sed -i "s/$api_var=.*/$api_var=$api_port/" "$dir/.env"
            fi
        done
        
        echo -e "${GREEN}   ✓ Configured $dir with ports: Web=$web_port, API=$api_port${NC}"
    fi
}

# Configure ports for each worktree (if they exist)
PORT_BASE=3000
API_PORT_BASE=4000
port_offset=1

for worktree in "$PROJECT_ROOT/$PROJECT_NAME-"*; do
    if [ -d "$worktree" ] && [ "$worktree" != "$PROJECT_DIR" ]; then
        web_port=$((PORT_BASE + port_offset))
        api_port=$((API_PORT_BASE + port_offset))
        update_ports "$worktree" "$web_port" "$api_port"
        ((port_offset++))
    fi
done

# Create initial coordination document in Obsidian
echo -e "\n${YELLOW}📝 Creating Obsidian coordination structure${NC}"

mkdir -p "$COORDINATION_DIR"
cat > "$COORDINATION_DIR/agent-worktrees.md" << EOF
# Agent Worktrees Configuration

Created: $(date +"%Y-%m-%d %H:%M:%S")
Project: $PROJECT_NAME

## Active Worktrees

EOF

# List all worktrees
git worktree list | while read -r line; do
    if [[ $line =~ ^(.+)[[:space:]]+([a-f0-9]+)[[:space:]]+\[(.+)\]$ ]]; then
        path="${BASH_REMATCH[1]}"
        commit="${BASH_REMATCH[2]}"
        branch="${BASH_REMATCH[3]}"
        
        # Extract agent name from path
        agent_name=$(basename "$path" | sed "s/$PROJECT_NAME-//")
        
        cat >> "$COORDINATION_DIR/agent-worktrees.md" << EOF
### $agent_name
- **Path**: \`$path\`
- **Branch**: \`$branch\`
- **Commit**: \`$commit\`

EOF
    fi
done

cat >> "$COORDINATION_DIR/agent-worktrees.md" << EOF

## Quick Commands

### Switch to agent
\`\`\`bash
cd \$PROJECT_ROOT/\$PROJECT_NAME-{agent-name}
claude
\`\`\`

### Create feature branch
\`\`\`bash
git checkout -b agent/{type}/{feature-name}
\`\`\`

### Check agent status
\`\`\`bash
git worktree list
\`\`\`

### Remove worktree
\`\`\`bash
git worktree remove \$PROJECT_ROOT/\$PROJECT_NAME-{agent-name}
\`\`\`
EOF

echo -e "${GREEN}   ✓ Created Obsidian coordination document${NC}"

# Display summary
echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
echo -e "\n${YELLOW}Summary of created worktrees:${NC}"
git worktree list

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Switch to any agent worktree: cd \$PROJECT_ROOT/\$PROJECT_NAME-{agent-name}"
echo "2. Launch Claude in the worktree: claude"
echo "3. Create feature branches as needed"
echo "4. Document work in Obsidian at $OBSIDIAN_DIR"

echo -e "\n${GREEN}Happy parallel developing! 🚀${NC}"