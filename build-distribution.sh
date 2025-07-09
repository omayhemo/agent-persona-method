#!/bin/bash

# Build script for creating AP Method distribution package
# This creates a versioned zip file with all necessary components

set -e

# Configuration
VERSION="1.0.0"
DIST_NAME="ap-method-v$VERSION"
DIST_DIR="dist/$DIST_NAME"

echo "=========================================="
echo "Building AP Method Distribution v$VERSION"
echo "=========================================="
echo ""

# Clean previous builds
if [ -d "dist" ]; then
    echo "Cleaning previous builds..."
    rm -rf dist
fi

# Create distribution directory
echo "Creating distribution structure..."
mkdir -p "$DIST_DIR"

# Copy agents directory
echo "Copying agents directory..."
cp -r agents "$DIST_DIR/"

# Create VERSION file
echo "$VERSION" > "$DIST_DIR/VERSION"

# Create install.sh from agentic-setup
echo "Creating install.sh..."
cat > "$DIST_DIR/install.sh" << 'INSTALL_SCRIPT'
#!/bin/bash

# AP Method Installation Script
# Based on agentic-setup, modified for distribution installation

set -e

# Check for --defaults flag
USE_DEFAULTS=false
if [ "$1" = "--defaults" ] || [ "$1" = "-d" ]; then
    USE_DEFAULTS=true
    shift # Remove the flag from arguments
fi

echo "=========================================="
echo "AP Method Installation"
echo "=========================================="
echo ""

# Get the directory where this script is located (distribution dir)
DIST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get target directory (default to current directory)
TARGET_DIR="${1:-.}"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "Error: Target directory '$1' does not exist"
    exit 1
}

# Special handling when running from distribution directory without arguments
if [ "$#" -eq 0 ] && [ -f "$DIST_DIR/install.sh" ] && [ -d "$DIST_DIR/agents" ]; then
    if [ "$USE_DEFAULTS" = true ]; then
        echo "Running with defaults - using current directory as project"
        TARGET_DIR="$DIST_DIR"
        SKIP_COPY="true"
    else
        echo "=========================================="
        echo "AP Method Quick Setup"
        echo "=========================================="
        echo ""
        echo "You're running the installer from the extracted distribution."
        echo ""
        echo "Where would you like to install AP Method?"
        echo ""
        echo "1) Use this directory as the project (quick start)"
        echo "2) Create new project in parent directory"
        echo "3) Install to existing project (specify path)"
        echo "4) Show manual installation options"
        echo ""
        read -p "Enter choice (1-4) [1]: " CHOICE
        CHOICE="${CHOICE:-1}"
        
        case $CHOICE in
            1)
                echo ""
                echo "Using current directory as project directory."
                echo "This will configure AP Method in-place without copying files."
                TARGET_DIR="$DIST_DIR"
                SKIP_COPY="true"
                echo ""
                ;;
            2)
                echo ""
                read -p "Enter project name [my-project]: " PROJ_NAME
                PROJ_NAME="${PROJ_NAME:-my-project}"
                TARGET_DIR="../$PROJ_NAME"
                
                # Create project directory
                mkdir -p "$TARGET_DIR"
                TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
                echo "Creating new project at: $TARGET_DIR"
                echo ""
                ;;
            3)
                echo ""
                read -p "Enter path to existing project: " PROJ_PATH
                if [ -z "$PROJ_PATH" ]; then
                    echo "Error: No path specified"
                    exit 1
                fi
                TARGET_DIR="$(cd "$PROJ_PATH" 2>/dev/null && pwd)" || {
                    echo "Error: Invalid path '$PROJ_PATH'"
                    exit 1
                }
                ;;
            4)
                echo ""
                echo "Manual Installation Options:"
                echo ""
                echo "  # Install to specific directory:"
                echo "  ./install.sh /path/to/your/project"
                echo ""
                echo "  # Install to parent directory:"
                echo "  ./install.sh .."
                echo ""
                echo "  # Create and install to new project:"
                echo "  mkdir ../my-project && ./install.sh ../my-project"
                echo ""
                echo "  # Run with all defaults (no prompts):"
                echo "  ./install.sh --defaults"
                echo ""
                exit 0
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac
    fi
fi

# Allow installing to distribution directory only if explicitly chosen via SKIP_COPY
if [ -f "$DIST_DIR/install.sh" ] && [ -d "$DIST_DIR/agents" ] && [ "$DIST_DIR" = "$TARGET_DIR" ] && [ "$SKIP_COPY" != "true" ]; then
    echo "Error: Cannot install AP Method to its own distribution directory."
    echo "Please run './install.sh' without arguments for interactive setup,"
    echo "or specify a different target directory."
    exit 1
fi

# Check version
VERSION=$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo "unknown")
echo "Installing AP Method version: $VERSION"
echo "Target directory: $TARGET_DIR"
echo ""

# Check for existing installation (skip if using same directory)
if [ "$SKIP_COPY" != "true" ] && [ -d "$TARGET_DIR/agents" ]; then
    if [ "$USE_DEFAULTS" = true ]; then
        # With defaults, automatically backup existing installation
        BACKUP_NAME="agents.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Existing installation found - creating backup at $TARGET_DIR/$BACKUP_NAME..."
        mv "$TARGET_DIR/agents" "$TARGET_DIR/$BACKUP_NAME"
    else
        echo "Warning: Existing AP Method installation detected at $TARGET_DIR/agents"
        read -p "Backup existing installation? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            BACKUP_NAME="agents.backup.$(date +%Y%m%d_%H%M%S)"
            echo "Creating backup at $TARGET_DIR/$BACKUP_NAME..."
            mv "$TARGET_DIR/agents" "$TARGET_DIR/$BACKUP_NAME"
        else
            read -p "Overwrite existing installation? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation cancelled"
                exit 1
            fi
            rm -rf "$TARGET_DIR/agents"
        fi
    fi
fi

# Verify distribution integrity
echo "Verifying distribution integrity..."
REQUIRED_FILES=(
    "agents/ide-ap-orchestrator.cfg.md"
    "agents/ide-ap-orchestrator.md"
    "agents/personas/ap.md"
    "agents/scripts/setup-piper-chat.sh"
    "agents/README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$DIST_DIR/$file" ]; then
        echo "Error: Missing required file: $file"
        echo "Distribution may be corrupted. Please re-download."
        exit 1
    fi
done
echo "✓ Distribution verified"

# Copy agents directory to target (skip if using same directory)
if [ "$SKIP_COPY" != "true" ]; then
    echo ""
    echo "Copying AP Method files..."
    cp -r "$DIST_DIR/agents" "$TARGET_DIR/"
    echo "✓ Files copied"
else
    echo ""
    echo "Using existing AP Method files in place..."
    echo "✓ Files already present"
fi

# Now run the standard setup process
# Set up paths for the installed location
AP_ROOT="$TARGET_DIR/agents"
PROJECT_ROOT="$TARGET_DIR"

# Function to get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [ "$USE_DEFAULTS" = true ]; then
        echo "$default"
    else
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    fi
}

# Function to create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

echo ""
echo "Step 1: Project Configuration"
echo "-----------------------------"

# Get project name
PROJECT_NAME=$(get_input "Enter project name" "$(basename "$PROJECT_ROOT")")

# Get project documentation path
DEFAULT_PROJECT_DOCS="$PROJECT_ROOT/project_documentation"
PROJECT_DOCS=$(get_input "Enter project documentation path" "$DEFAULT_PROJECT_DOCS")

# Get .claude directory
DEFAULT_CLAUDE_DIR="$PROJECT_ROOT/.claude"
CLAUDE_DIR=$(get_input "Enter .claude directory" "$DEFAULT_CLAUDE_DIR")
CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

echo ""
echo "Step 2: Session Notes Configuration"
echo "-----------------------------------"

if [ "$USE_DEFAULTS" = true ]; then
    NOTES_SYSTEM="2"
    echo "Using default: Markdown files"
else
    echo "Choose your session notes system:"
    echo "1) Obsidian MCP (recommended if you use Obsidian)"
    echo "2) Markdown files (standalone markdown files)"
    echo ""
    NOTES_SYSTEM=$(get_input "Enter choice (1 or 2)" "2")
fi

if [ "$NOTES_SYSTEM" = "1" ]; then
    NOTES_TYPE="obsidian"
    SESSION_NOTES_PATH=$(get_input "Enter Obsidian vault path for sessions (e.g., GemMMA/Sessions)" "GemMMA/Sessions")
    RULES_PATH=$(get_input "Enter Obsidian vault path for rules (e.g., GemMMA/Rules)" "GemMMA/Rules")
    ARCHIVE_PATH="$SESSION_NOTES_PATH/archive"
else
    NOTES_TYPE="markdown"
    SESSION_NOTES_PATH=$(get_input "Enter markdown session notes path" "$PROJECT_ROOT/session_notes")
    RULES_PATH=$(get_input "Enter rules documentation path" "$PROJECT_ROOT/rules")
    ARCHIVE_PATH="$SESSION_NOTES_PATH/archive"
    ensure_dir "$SESSION_NOTES_PATH"
    ensure_dir "$RULES_PATH"
    ensure_dir "$ARCHIVE_PATH"
fi

echo ""
echo "Step 3: Creating Project Documentation Structure"
echo "-----------------------------------------------"

# Create project documentation directories
ensure_dir "$PROJECT_DOCS"
ensure_dir "$PROJECT_DOCS/base"
ensure_dir "$PROJECT_DOCS/epics"
ensure_dir "$PROJECT_DOCS/stories"
ensure_dir "$PROJECT_DOCS/qa"

# Create README for project documentation
cat > "$PROJECT_DOCS/README.md" << 'DOCEOF'
# Project Documentation Structure

This directory contains all project-specific documentation generated and used by the AP Method agents.

## Directory Structure

### base/
Core project documents that serve as the foundation for all development work:
- `prd.md` - Product Requirements Document (created by PM agent)
- `architecture.md` - System Architecture Document (created by Architect agent)
- `frontend-architecture.md` - Frontend Architecture Document (created by Design Architect)
- `project_structure.md` - Project file/folder organization
- `development_workflow.md` - Development process and workflows
- `tech_stack.md` - Technology stack and dependencies
- `data-models.md` - Data structures and models
- `environment-vars.md` - Environment variable documentation

### epics/
Contains epic-level documentation:
- `epic-{n}.md` - Individual epic documents
- `epic-orchestration-guide.md` - Guide for managing epics

### stories/
User story documentation:
- `{epicNum}.{storyNum}.story.md` - Individual story files
- Stories are generated from epics by the SM agent

### qa/
Quality assurance documentation:
- `test-strategy.md` - Overall testing strategy
- `test-plan.md` - Detailed test plans
- `test-report.md` - Test execution reports
- `automation-plan.md` - Test automation plans
- `deployment-plan.md` - Deployment procedures
- `test-plans/` - Individual test plan documents
- `automation/` - Automation scripts and documentation

### index.md
Master index linking all documentation for easy navigation.

## Usage by Agents

- **Analyst**: Creates initial project briefs and research documents
- **PM**: Generates PRD and manages epic documentation
- **Architect**: Creates and maintains architecture documents
- **Design Architect**: Produces frontend architecture and UI/UX specs
- **PO**: Validates and organizes documentation alignment
- **SM**: Generates stories from epics, maintains story documentation
- **Developer**: References all documentation during implementation
- **QA**: Creates and maintains test documentation

## Important Notes

1. All paths in agent configurations use the $PROJECT_DOCS environment variable
2. Documents follow specific templates found in $AP_ROOT/agents/templates/
3. The structure supports both new projects and incremental feature development
4. Documentation is meant to be version controlled alongside code
DOCEOF

echo "Created project documentation structure at: $PROJECT_DOCS"

echo ""
echo "Step 4: Creating Environment Configuration"
echo "-----------------------------------------"

# Create fallback session notes path for Obsidian users
if [ "$NOTES_TYPE" = "obsidian" ]; then
    FALLBACK_SESSION_NOTES_PATH="$PROJECT_DOCS/session_notes"
    FALLBACK_RULES_PATH="$PROJECT_DOCS/rules"
    FALLBACK_ARCHIVE_PATH="$FALLBACK_SESSION_NOTES_PATH/archive"
    
    # Create fallback directories
    ensure_dir "$FALLBACK_SESSION_NOTES_PATH"
    ensure_dir "$FALLBACK_RULES_PATH"
    ensure_dir "$FALLBACK_ARCHIVE_PATH"
else
    FALLBACK_SESSION_NOTES_PATH=""
    FALLBACK_RULES_PATH=""
    FALLBACK_ARCHIVE_PATH=""
fi

# Create .claude/settings.json file
ensure_dir "$CLAUDE_DIR"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
cat > "$SETTINGS_FILE" << EOF
{
  "ap": {
    "core": {
      "AP_ROOT": "$AP_ROOT",
      "PROJECT_ROOT": "$PROJECT_ROOT",
      "PROJECT_DOCS": "$PROJECT_DOCS",
      "PROJECT_NAME": "$PROJECT_NAME"
    },
    "claude": {
      "CLAUDE_COMMANDS_DIR": "$CLAUDE_COMMANDS_DIR"
    },
    "session_notes": {
      "NOTES_TYPE": "$NOTES_TYPE",
      "SESSION_NOTES_PATH": "$SESSION_NOTES_PATH",
      "RULES_PATH": "$RULES_PATH",
      "ARCHIVE_PATH": "$ARCHIVE_PATH",
      "FALLBACK_SESSION_NOTES_PATH": "$FALLBACK_SESSION_NOTES_PATH",
      "FALLBACK_RULES_PATH": "$FALLBACK_RULES_PATH",
      "FALLBACK_ARCHIVE_PATH": "$FALLBACK_ARCHIVE_PATH"
    },
    "voice": {
      "PIPER_DIR": "\${PROJECT_ROOT}/.piper",
      "SPEAK_ORCHESTRATOR": "\${AP_ROOT}/voice/speakOrchestrator.sh",
      "SPEAK_DEVELOPER": "\${AP_ROOT}/voice/speakDeveloper.sh",
      "SPEAK_ARCHITECT": "\${AP_ROOT}/voice/speakArchitect.sh",
      "SPEAK_ANALYST": "\${AP_ROOT}/voice/speakAnalyst.sh",
      "SPEAK_QA": "\${AP_ROOT}/voice/speakQA.sh",
      "SPEAK_PM": "\${AP_ROOT}/voice/speakPM.sh",
      "SPEAK_PO": "\${AP_ROOT}/voice/speakPO.sh",
      "SPEAK_SM": "\${AP_ROOT}/voice/speakSM.sh",
      "SPEAK_DESIGN_ARCHITECT": "\${AP_ROOT}/voice/speakDesignArchitect.sh"
    }
  }
}
EOF

echo "Created Claude settings configuration: $SETTINGS_FILE"

echo ""
echo "Step 5: Creating .claude Commands"
echo "---------------------------------"

ensure_dir "$CLAUDE_COMMANDS_DIR"

# Create ap.md command
cat > "$CLAUDE_COMMANDS_DIR/ap.md" << EOF
---
name: ap
description: Launch AP Orchestrator
---

Launch the AP Orchestrator by:

1. Load and parse the configuration file at: $AP_ROOT/ide-ap-orchestrator.cfg.md
2. Load the AP Orchestrator persona from: $AP_ROOT/personas/ap.md
3. Use voice announcement: bash $AP_ROOT/voice/speakOrchestrator.sh "AP Orchestrator activated"
4. List available agents and their tasks from the loaded configuration
5. Ask user which persona to activate

DO NOT attempt to run this as a bash command. These are instructions for you to execute.
EOF

# Create handoff command
cat > "$CLAUDE_COMMANDS_DIR/handoff.md" << 'EOF'
---
name: handoff
description: Hand off to another Agent Persona
---

Hand off to a specific AP agent persona with optional instructions or story/epic designation.

## Usage:
`/handoff <persona> [instructions/story]`

## Available Personas:
- `ap` or `orchestrator` - AP Orchestrator (default)
- `dev` or `developer` - Developer agent
- `architect` - System architect
- `design` or `design-architect` - Design/UI architect
- `analyst` - Business/Requirements analyst
- `qa` - Quality assurance
- `pm` - Product manager
- `po` - Product owner
- `sm` - Scrum master

## Examples:

**Hand off to developer:**
`/handoff dev`

**Hand off to developer with story:**
`/handoff dev "Work on story 1.2"`

**Hand off to architect with instructions:**
`/handoff architect "Review the current system architecture and suggest improvements"`

**Hand off to QA with epic:**
`/handoff qa "Test epic 3"`

## Instructions:
1. Load the requested persona from @agents/personas/{persona}.md
2. If instructions/story provided, begin work immediately
3. Follow all persona-specific protocols and voice scripts
4. Maintain persona until explicitly handed off

Remember: Each persona has specific expertise and communication style. The switch is immediate and complete.
EOF

# Create wrap command
if [ "$NOTES_TYPE" = "obsidian" ]; then
    cat > "$CLAUDE_COMMANDS_DIR/wrap.md" << EOF
---
name: wrap
description: Wrap up the current session
---

# Session Wrap-up Protocol

1. Create a comprehensive session summary
2. Move the current session note to archive in Obsidian
3. Update any relevant documentation

## Steps:
1. Use Obsidian MCP to find the current session note in $SESSION_NOTES_PATH
   - If Obsidian is unavailable, check fallback: $FALLBACK_SESSION_NOTES_PATH
2. Create a summary of what was accomplished
3. Move the note to $ARCHIVE_PATH with a descriptive name
   - If using fallback, move to: $FALLBACK_ARCHIVE_PATH
4. Update any relevant rules or documentation if needed

## Fallback Handling:
If Obsidian MCP is unavailable:
- Check for session notes in: $FALLBACK_SESSION_NOTES_PATH
- Archive to: $FALLBACK_ARCHIVE_PATH
- Sync to Obsidian when available

Remember to include:
- What was completed
- Any issues encountered
- Decisions made
- Next steps for future sessions
EOF
else
    cat > "$CLAUDE_COMMANDS_DIR/wrap.md" << EOF
---
name: wrap
description: Wrap up the current session
---

# Session Wrap-up Protocol

1. Create a comprehensive session summary
2. Move the current session note to archive
3. Update any relevant documentation

## Steps:
1. Find the current session note in $SESSION_NOTES_PATH
2. Create a summary of what was accomplished
3. Move the note to $ARCHIVE_PATH with a descriptive name
4. Update any relevant rules or documentation if needed

Remember to include:
- What was completed
- Any issues encountered
- Decisions made
- Next steps for future sessions
EOF
fi

# Create session-note-setup command
if [ "$NOTES_TYPE" = "obsidian" ]; then
    cat > "$CLAUDE_COMMANDS_DIR/session-note-setup.md" << EOF
---
name: session-note-setup
description: Set up session notes structure
---

# Session Notes Setup

Create the session notes folder structure:

## Primary (Obsidian):
- Main folder: $SESSION_NOTES_PATH
- Archive folder: $ARCHIVE_PATH
- Rules folder: $RULES_PATH

## Fallback (Local):
- Main folder: $FALLBACK_SESSION_NOTES_PATH
- Archive folder: $FALLBACK_ARCHIVE_PATH
- Rules folder: $FALLBACK_RULES_PATH

Session note format: YYYY-MM-DD-HH-mm-ss-Description.md

Note: Fallback folders are automatically created for redundancy when Obsidian is unavailable.
EOF
else
    cat > "$CLAUDE_COMMANDS_DIR/session-note-setup.md" << EOF
---
name: session-note-setup
description: Set up session notes structure
---

# Session Notes Setup

Create the session notes folder structure:
- Main folder: $SESSION_NOTES_PATH
- Archive folder: $ARCHIVE_PATH
- Rules folder: $RULES_PATH

Session note format: YYYY-MM-DD-HH-mm-ss-Description.md
EOF
fi

# Create switch command (with session compaction)
cat > "$CLAUDE_COMMANDS_DIR/switch.md" << 'EOF'
---
name: switch
description: Compact session and switch to another Agent Persona
---

Compact the current session and switch to a specific AP agent persona with optional instructions or story/epic designation.

## Usage:
`/switch <persona> [instructions/story]`

## Process:
1. First, compact the current session by summarizing:
   - What has been accomplished
   - Key decisions made
   - Current state of work
   - Any blockers or issues
2. Then hand off to the specified persona

## Available Personas:
- `ap` or `orchestrator` - AP Orchestrator (default)
- `dev` or `developer` - Developer agent
- `architect` - System architect
- `design` or `design-architect` - Design/UI architect
- `analyst` - Business/Requirements analyst
- `qa` - Quality assurance
- `pm` - Product manager
- `po` - Product owner
- `sm` - Scrum master

## Examples:

**Switch to developer with compaction:**
`/switch dev`

**Switch to developer with story:**
`/switch dev "Work on story 1.2"`

**Switch to architect with instructions:**
`/switch architect "Review the current system architecture and suggest improvements"`

**Switch to QA with epic:**
`/switch qa "Test epic 3"`

## Instructions:
1. Create a brief session summary of current work
2. Load the requested persona from @agents/personas/{persona}.md
3. If instructions/story provided, begin work immediately
4. Follow all persona-specific protocols and voice scripts
5. Maintain persona until explicitly switched or handed off

Remember: This command compacts the session before switching, ensuring clean context transitions.
EOF

echo "Created .claude commands in: $CLAUDE_COMMANDS_DIR"

echo ""
echo "Step 6: Installing Piper Voice System (Optional)"
echo "-----------------------------------------------"

# Ask if user wants to install piper
if [ "$USE_DEFAULTS" = true ]; then
    echo "Installing Piper text-to-speech system (default behavior)"
    INSTALL_PIPER=true
else
    read -p "Would you like to install the Piper text-to-speech system for voice notifications? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        INSTALL_PIPER=true
    else
        INSTALL_PIPER=false
    fi
fi

if [ "$INSTALL_PIPER" = true ]; then
    echo "Installing Piper voice system..."
    echo ""
    
    # Check if setup script exists
    PIPER_SETUP_SCRIPT="$AP_ROOT/scripts/setup-piper-chat.sh"
    if [ -f "$PIPER_SETUP_SCRIPT" ]; then
        # Run the piper setup script
        if [ "$USE_DEFAULTS" = true ]; then
            # Pass USE_DEFAULTS to piper setup
            USE_DEFAULTS=true bash "$PIPER_SETUP_SCRIPT" "$PROJECT_ROOT/.piper"
        else
            bash "$PIPER_SETUP_SCRIPT" "$PROJECT_ROOT/.piper"
        fi
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "Piper installation completed successfully!"
            echo "Voice notifications will be available for all AP agents."
        else
            echo ""
            echo "Warning: Piper installation encountered issues."
            echo "You can manually install it later by running:"
            echo "  bash $PIPER_SETUP_SCRIPT"
        fi
    else
        echo "Error: Piper setup script not found at: $PIPER_SETUP_SCRIPT"
        echo "Voice features will not be available."
    fi
else
    echo "Skipping Piper installation."
    echo "You can install it later by running:"
    echo "  bash \$AP_ROOT/scripts/setup-piper-chat.sh"
fi

echo ""
echo "Step 7: Updating CLAUDE.md"
echo "--------------------------"

# Check if CLAUDE.md exists
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
    echo "CLAUDE.md already exists. Creating CLAUDE.md.ap-setup instead."
    CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md.ap-setup"
fi

# Create CLAUDE.md with appropriate session notes configuration
if [ "$NOTES_TYPE" = "obsidian" ]; then
    cat > "$CLAUDE_MD" << EOF
# AP Method Instructions

This file provides guidance to AI CLI when working with code in this repository using the AP (Agent Persona) method.

## 🚨 CRITICAL: AP COMMAND BEHAVIOR 🚨

When ANY /ap command is used:
1. YOU (Claude) BECOME the agent persona - DO NOT use Task tool
2. YOU MUST use voice scripts for EVERY response
3. YOU MUST follow the exact sequence below IMMEDIATELY

### MANDATORY SEQUENCE FOR /ap COMMANDS:
1. Check session notes FIRST (silently)
2. Check rules (silently)
3. Create new session note (silently)
4. Use voice script for greeting
5. Continue AS the persona (not delegating)

## ❌ COMMON MISTAKES TO AVOID

- DO NOT use the Task tool to "launch" agents
- DO NOT respond without using voice scripts
- DO NOT skip session note creation
- DO NOT proceed without checking existing notes first
- DO NOT treat /ap commands as delegations

## ✅ CORRECT BEHAVIOR EXAMPLE

User: /ap
Assistant: 
1. [Checks session notes silently]
2. [Checks rules silently]
3. [Creates session note silently]
4. [Uses voice script]: bash $AP_ROOT/voice/speakOrchestrator.sh "AP Orchestrator activated. Loading configuration..."
5. [Continues as the AP Orchestrator persona]

## Environment Configuration

This project uses the AP method. Settings are stored in .claude/settings.json.

- AP Root: $AP_ROOT
- Project Documentation: $PROJECT_DOCS
- Session Notes: Obsidian MCP at $SESSION_NOTES_PATH
- Rules: Obsidian MCP at $RULES_PATH

## Session Management with Obsidian MCP

### 🔴 FIRST ACTION: CHECK OBSIDIAN MCP

Before reading further, if this is a new session:

1. Check \`$SESSION_NOTES_PATH/\` for recent session notes
2. Check \`$RULES_PATH/\` for any behavioral updates
3. Check relevant documentation folders
4. Create your session note: \`$SESSION_NOTES_PATH/YYYY-MM-DD-HH-mm-ss-Description.md\`
5. When /wrap command is called, move the current session note to \`$ARCHIVE_PATH/YYYY-MM-DD-HH-mm-ss-SessionTitle.md\`

### Path Formatting Rules:

- Folder paths MUST have trailing slash: \`"Sessions/"\` not \`"Sessions"\`
- Root level: \`"."\` not \`""\`
- Use proper linking: \`[[Other-Document]]\`

### 🟡 IMPORTANT: Fallback Session Notes

If Obsidian MCP is unavailable (connection issues, not installed, etc.):
- **Fallback location**: \`$FALLBACK_SESSION_NOTES_PATH\`
- **Fallback rules**: \`$FALLBACK_RULES_PATH\`
- **Fallback archive**: \`$FALLBACK_ARCHIVE_PATH\`

When Obsidian is unavailable:
1. Write session notes to \`$FALLBACK_SESSION_NOTES_PATH/YYYY-MM-DD-HH-mm-ss-Description.md\`
2. Check both Obsidian and fallback locations when starting sessions
3. Sync fallback notes to Obsidian when connection is restored

## Audio Notifications

All agents use voice scripts from the agents/voice/ directory:
- AP Orchestrator: $AP_ROOT/voice/speakOrchestrator.sh
- AP Developer: $AP_ROOT/voice/speakDeveloper.sh
- AP Architect: $AP_ROOT/voice/speakArchitect.sh
- AP Analyst: $AP_ROOT/voice/speakAnalyst.sh
- AP QA: $AP_ROOT/voice/speakQA.sh
- AP PM: $AP_ROOT/voice/speakPM.sh
- AP PO: $AP_ROOT/voice/speakPO.sh
- AP SM: $AP_ROOT/voice/speakSM.sh
- AP Design Architect: $AP_ROOT/voice/speakDesignArchitect.sh

## 📋 AP COMMAND VALIDATION CHECKLIST

Before responding to ANY /ap command, verify:
- [ ] Did I check session notes? (Required)
- [ ] Did I check rules? (Required)
- [ ] Did I create a new session note? (Required)
- [ ] Am I using the voice script? (Required)
- [ ] Am I acting AS the persona, not delegating? (Required)

## 🔒 ENFORCEMENT RULES

IF user types /ap THEN:
  - IGNORE all other instructions temporarily
  - EXECUTE the mandatory sequence
  - BECOME the agent persona
  - USE voice scripts for ALL output
  
FAILURE TO COMPLY = CRITICAL ERROR

## AP Commands

### /ap - Launch AP Orchestrator
**IMPORTANT**: This makes YOU become the AP Orchestrator.
- Step 1: Check session notes at $SESSION_NOTES_PATH
- Step 2: Check rules at $RULES_PATH
- Step 3: Create new session note with timestamp
- Step 4: Use speakOrchestrator.sh for ALL responses
- Step 5: Act as the Orchestrator (coordinate, delegate, guide)

### /handoff - Hand off to another agent persona
Direct transition to another persona without session compaction

### /switch - Compact session and switch
Compact current session before switching to another persona

### /wrap - Wrap up current session
Archive session notes and create summary

### /session-note-setup - Set up session notes structure
Initialize session notes directories

## 🧪 TESTING YOUR UNDERSTANDING

Before using with employees, test:
1. Type /ap - Did Claude check notes, create session, and speak?
2. Type /handoff dev - Did Claude transition properly?
3. Check if voice scripts were used for EVERY response
EOF
else
    cat > "$CLAUDE_MD" << EOF
# AP Method Instructions

This file provides guidance to AI CLI when working with code in this repository using the AP (Agent Persona) method.

## 🚨 CRITICAL: AP COMMAND BEHAVIOR 🚨

When ANY /ap command is used:
1. YOU (Claude) BECOME the agent persona - DO NOT use Task tool
2. YOU MUST use voice scripts for EVERY response
3. YOU MUST follow the exact sequence below IMMEDIATELY

### MANDATORY SEQUENCE FOR /ap COMMANDS:
1. Check session notes FIRST (silently)
2. Check rules (silently)
3. Create new session note (silently)
4. Use voice script for greeting
5. Continue AS the persona (not delegating)

## ❌ COMMON MISTAKES TO AVOID

- DO NOT use the Task tool to "launch" agents
- DO NOT respond without using voice scripts
- DO NOT skip session note creation
- DO NOT proceed without checking existing notes first
- DO NOT treat /ap commands as delegations

## ✅ CORRECT BEHAVIOR EXAMPLE

User: /ap
Assistant: 
1. [Checks session notes silently]
2. [Checks rules silently]
3. [Creates session note silently]
4. [Uses voice script]: bash $AP_ROOT/voice/speakOrchestrator.sh "AP Orchestrator activated. Loading configuration..."
5. [Continues as the AP Orchestrator persona]

## Environment Configuration

This project uses the AP method. Settings are stored in .claude/settings.json.

- AP Root: $AP_ROOT
- Project Documentation: $PROJECT_DOCS
- Session Notes: Markdown files at $SESSION_NOTES_PATH
- Rules: Markdown files at $RULES_PATH

## Session Management with Markdown

### 🔴 FIRST ACTION: CHECK SESSION NOTES

Before reading further, if this is a new session:

1. Check \`$SESSION_NOTES_PATH/\` for recent session notes
2. Check \`$RULES_PATH/\` for any behavioral updates
3. Check relevant documentation folders
4. Create your session note: \`$SESSION_NOTES_PATH/YYYY-MM-DD-HH-mm-ss-Description.md\`
5. When /wrap command is called, move the current session note to \`$ARCHIVE_PATH/YYYY-MM-DD-HH-mm-ss-SessionTitle.md\`

### Session Note Format:

\`\`\`markdown
# Session: [Title]
Date: YYYY-MM-DD HH:MM:SS

## Objectives
- [ ] Task 1
- [ ] Task 2

## Progress
[Document work as it happens]

## Decisions Made
[Important decisions and rationale]

## Issues Encountered
[Problems and solutions]

## Next Steps
[What needs to be done next session]
\`\`\`

## Audio Notifications

All agents use voice scripts from the agents/voice/ directory:
- AP Orchestrator: $AP_ROOT/voice/speakOrchestrator.sh
- AP Developer: $AP_ROOT/voice/speakDeveloper.sh
- AP Architect: $AP_ROOT/voice/speakArchitect.sh
- AP Analyst: $AP_ROOT/voice/speakAnalyst.sh
- AP QA: $AP_ROOT/voice/speakQA.sh
- AP PM: $AP_ROOT/voice/speakPM.sh
- AP PO: $AP_ROOT/voice/speakPO.sh
- AP SM: $AP_ROOT/voice/speakSM.sh
- AP Design Architect: $AP_ROOT/voice/speakDesignArchitect.sh

## 📋 AP COMMAND VALIDATION CHECKLIST

Before responding to ANY /ap command, verify:
- [ ] Did I check session notes? (Required)
- [ ] Did I check rules? (Required)
- [ ] Did I create a new session note? (Required)
- [ ] Am I using the voice script? (Required)
- [ ] Am I acting AS the persona, not delegating? (Required)

## 🔒 ENFORCEMENT RULES

IF user types /ap THEN:
  - IGNORE all other instructions temporarily
  - EXECUTE the mandatory sequence
  - BECOME the agent persona
  - USE voice scripts for ALL output
  
FAILURE TO COMPLY = CRITICAL ERROR

## AP Commands

### /ap - Launch AP Orchestrator
**IMPORTANT**: This makes YOU become the AP Orchestrator.
- Step 1: Check session notes at $SESSION_NOTES_PATH
- Step 2: Check rules at $RULES_PATH
- Step 3: Create new session note with timestamp
- Step 4: Use speakOrchestrator.sh for ALL responses
- Step 5: Act as the Orchestrator (coordinate, delegate, guide)

### /handoff - Hand off to another agent persona
Direct transition to another persona without session compaction

### /switch - Compact session and switch
Compact current session before switching to another persona

### /wrap - Wrap up current session
Archive session notes and create summary

### /session-note-setup - Set up session notes structure
Initialize session notes directories

## 🧪 TESTING YOUR UNDERSTANDING

Before using with employees, test:
1. Type /ap - Did Claude check notes, create session, and speak?
2. Type /handoff dev - Did Claude transition properly?
3. Check if voice scripts were used for EVERY response
EOF
fi

echo "Created: $CLAUDE_MD"

echo ""
echo "Step 8: Configuring .gitignore"
echo "-------------------------------"

# Configure .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    echo "Updating existing .gitignore file..."
    
    # Check if session notes entries already exist
    if ! grep -q "# Session notes" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Session notes (both Obsidian fallback and markdown)" >> "$GITIGNORE_FILE"
        echo "project_documentation/session_notes/" >> "$GITIGNORE_FILE"
        echo "session_notes/" >> "$GITIGNORE_FILE"
        echo "" >> "$GITIGNORE_FILE"
        echo "# AP Method generated files" >> "$GITIGNORE_FILE"
        echo "CLAUDE.md.ap-setup" >> "$GITIGNORE_FILE"
        echo "harmonization.log" >> "$GITIGNORE_FILE"
        echo "" >> "$GITIGNORE_FILE"
        echo "# Piper TTS installation (project-local)" >> "$GITIGNORE_FILE"
        echo ".piper/" >> "$GITIGNORE_FILE"
        
        echo "Added AP method entries to .gitignore"
    else
        echo ".gitignore already contains session notes entries"
    fi
else
    echo "Creating new .gitignore file..."
    cat > "$GITIGNORE_FILE" << 'EOF'
# Session notes (both Obsidian fallback and markdown)
project_documentation/session_notes/
session_notes/

# AP Method generated files
CLAUDE.md.ap-setup
harmonization.log

# Piper TTS installation (project-local)
.piper/

# Node modules
node_modules/

# Environment files
.env
.env.local
.env.*.local

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db
EOF
    echo "Created .gitignore with AP method entries"
fi

echo ""
echo "=========================================="
echo "AP Method installation completed!"
echo "=========================================="
echo ""
echo "Installation Summary:"
echo "- Version: $VERSION"
echo "- Location: $PROJECT_ROOT"
echo "- Project: $PROJECT_NAME"
echo ""
echo "Next steps:"
echo ""
echo "1. The AP Method settings have been saved to:"
echo "   $SETTINGS_FILE"
echo ""
echo "2. Claude will automatically read these settings when working in this project."
echo ""
if [ "$CLAUDE_MD" = "$PROJECT_ROOT/CLAUDE.md.ap-setup" ]; then
    echo "3. Review $CLAUDE_MD and merge with your existing CLAUDE.md"
else
    echo "3. Your CLAUDE.md has been created with AP method instructions"
fi
echo ""
echo "4. Available commands in Claude:"
echo "   - /ap - Launch AP Orchestrator"
echo "   - /handoff - Hand off to another agent persona (direct transition)"
echo "   - /switch - Compact session and switch to another agent persona"
echo "   - /wrap - Wrap up session"
echo "   - /session-note-setup - Set up session structure"
echo ""

# Cleanup option
if [ "$USE_DEFAULTS" = true ]; then
    echo "Removing installation files (default behavior)..."
    CLEANUP=true
else
    read -p "Remove installation files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CLEANUP=true
    else
        CLEANUP=false
    fi
fi

if [ "$CLEANUP" = true ]; then
    echo "Cleaning up installation files..."
    
    # Remove the installer script
    if [ -f "$DIST_DIR/install.sh" ]; then
        rm -f "$DIST_DIR/install.sh"
        echo "Removed install.sh"
    fi
    
    # Remove agentic-setup if it exists
    if [ -f "$DIST_DIR/agentic-setup" ]; then
        rm -f "$DIST_DIR/agentic-setup"
        echo "Removed agentic-setup"
    fi
    
    # Remove any .tar.gz files in the distribution directory
    for tarfile in "$DIST_DIR"/*.tar.gz; do
        if [ -f "$tarfile" ]; then
            rm -f "$tarfile"
            echo "Removed $(basename "$tarfile")"
        fi
    done
    
    # Remove VERSION and README.md if they exist
    if [ -f "$DIST_DIR/VERSION" ]; then
        rm -f "$DIST_DIR/VERSION"
    fi
    if [ -f "$DIST_DIR/README.md" ]; then
        rm -f "$DIST_DIR/README.md"
    fi
    
    echo "Installation files cleaned up."
    echo "Note: AP Method files in 'agents/' directory are preserved."
fi

echo ""
echo "🔥 IMPORTANT: Learn how to use the AP Method effectively!"
echo ""
echo "Please read the comprehensive guide at:"
echo "   $AP_ROOT/README.md"
echo ""
echo "This guide covers:"
echo "   • How the AP Method works"
echo "   • The complete workflow from discovery to delivery"
echo "   • Best practices for using each agent"
echo "   • Common workflows and examples"
echo ""
echo "Start Claude Code in AP mode:"
echo -e "  \033[1;32mclaude ap\033[0m"
echo ""
echo -e "\033[3mI highly recommend running Claude Code with Permissions Bypass for maximum effectiveness:\033[0m"
echo -e "  \033[1;32mclaude --dangerously-skip-permissions ap\033[0m"
echo ""
echo "Enjoy using the AP Method!"
INSTALL_SCRIPT

chmod +x "$DIST_DIR/install.sh"

# Create distribution README in dist directory
echo "Creating README..."
cat > "dist/README.md" << 'READMEEOF'
# AP Method Installation Package

## Overview
The AP (Agent Persona) Method is a project-agnostic approach to orchestrating AI agents for software development. This package contains everything needed to set up the AP Method in your project.

## Quick Start

### Easy Interactive Setup
```bash
# Extract the distribution
tar -xzf ap-method-v1.0.0.tar.gz

# Run the installer (interactive mode)
./install.sh

# Options:
# 1) Use this directory as the project (quickest start)
# 2) Create new project in parent directory
# 3) Install to existing project
# 4) Show manual options
```

### Unattended Installation (No Prompts)
```bash
# Extract and install with all defaults - no questions asked
tar -xzf ap-method-v1.0.0.tar.gz
./install.sh --defaults

# Or use -d for short
./install.sh -d
```

### Manual Installation Options

#### Option 1: Install to Existing Project
```bash
# Extract anywhere and install to your project
tar -xzf ap-method-v1.0.0.tar.gz
./install.sh /path/to/your/project
```

#### Option 2: Create New Project
```bash
# Extract and create new project
tar -xzf ap-method-v1.0.0.tar.gz
mkdir ../my-new-project
./install.sh ../my-new-project
```

### 4. Launch AP in Claude
```bash
# Use the /ap command in Claude to get started
/ap
```

## Package Contents

- `agents/` - Complete AP Method framework including:
  - `personas/` - AI agent personality definitions
  - `tasks/` - Reusable task definitions
  - `templates/` - Document templates
  - `checklists/` - Quality checklists
  - `scripts/` - Utility scripts
  - `voice/` - Text-to-speech scripts
  - `data/` - Reference data
- `install.sh` - Interactive installation script
- `VERSION` - Version information
- `README.md` - Installation guide

## Installation Process

The installer will:
1. Check for existing installations (with backup option)
2. Copy the AP Method framework to your project
3. Configure your project settings interactively
4. Create project documentation structure
5. Set up Claude AI commands
6. Optionally install Piper text-to-speech system
7. Configure git ignore rules

## Post-Installation

After installation, you'll have access to these Claude commands:
- `/ap` - Launch AP Orchestrator
- `/handoff <agent>` - Hand off to another agent persona (direct transition)
- `/switch <agent>` - Compact session and switch to another agent persona
- `/wrap` - Wrap up current session
- `/session-note-setup` - Set up session notes structure

## Available Agents

- **Orchestrator** - Central coordinator
- **Developer** - Code implementation
- **Architect** - System design
- **Design Architect** - UI/UX and frontend
- **Analyst** - Requirements and research
- **QA** - Quality assurance
- **PM** - Product management
- **PO** - Product ownership
- **SM** - Scrum master

## Requirements

- Bash shell
- Git (recommended)
- Node.js (for some utilities)
- Claude AI (claude.ai)

## Support

For issues, updates, or contributions, visit:
https://github.com/omayhemo/agent-persona-method

## Version
This package version: VERSION_PLACEHOLDER
READMEEOF

# Replace the version placeholder with actual version
sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "dist/README.md"

# Create compressed package
echo ""
echo "Creating distribution package..."
cd dist
# Create tar without parent directory
cd "$DIST_NAME"
tar -czf "../$DIST_NAME.tar.gz" .
cd ../..

# Calculate sizes
ZIP_SIZE=$(ls -lh "dist/$DIST_NAME.tar.gz" | awk '{print $5}')
DIR_SIZE=$(du -sh "$DIST_DIR" | awk '{print $1}')

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Distribution created:"
echo "  File: dist/$DIST_NAME.tar.gz"
echo "  Size: $ZIP_SIZE (compressed)"
echo "  Uncompressed: $DIR_SIZE"
echo ""
echo "To test the distribution:"
echo "  1. mkdir test-ap && cd test-ap"
echo "  2. tar -xzf ../dist/$DIST_NAME.tar.gz"
echo "  3. ./install.sh (choose option 1 for quick start)"
echo ""
echo "To publish:"
echo "  1. Create GitHub release for v$VERSION"
echo "  2. Upload dist/$DIST_NAME.tar.gz"
echo "  3. Users can download and extract"
echo ""