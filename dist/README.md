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
This package version: 1.0.0
