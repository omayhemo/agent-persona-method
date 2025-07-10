# AP Method Installation Guide

## Overview

The AP (Agent Persona) Method is a project-agnostic approach to orchestrating AI agents for software development. This guide covers how to install the AP Method framework into your project.

## Installation Methods

### Method 1: Distribution Package (Recommended)

Download and install the latest release:

```bash
# Download and extract the distribution
curl -L https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz | tar -xz

# Run the installer
./install.sh
```

#### Installation Options

**Interactive Mode (Default):**
```bash
./install.sh
```
- Prompts for all configuration options
- Allows custom project paths and settings
- Recommended for first-time users

**Unattended Mode:**
```bash
./install.sh --defaults  # or -d
```
- Uses all default settings
- Installs to current directory
- Skips optional features (Piper TTS)

**Specify Target Directory:**
```bash
./install.sh /path/to/your/project
```

### Method 2: Source Installation

For development or customization:

```bash
# Clone the repository
git clone https://github.com/omayhemo/agent-persona-method.git
cd agent-persona-method

# Run the setup wizard
./agents/agentic-setup
```

## What Gets Installed

The installation creates the following structure in your project:

```
your-project/
├── agents/                    # AP Method framework
│   ├── personas/             # 10 agent persona definitions
│   ├── tasks/                # 28 reusable task definitions
│   ├── templates/            # 19 document templates
│   ├── checklists/           # 17 quality checklists
│   ├── scripts/              # Utility and automation scripts
│   ├── voice/                # 10 voice notification scripts
│   ├── data/                 # Knowledge base and preferences
│   └── [configuration files]
├── .claude/                  # Claude AI configuration
│   ├── settings.json         # Project settings
│   └── commands/             # Custom commands (/ap, /handoff, etc.)
└── project_documentation/    # Created for your project docs
    ├── base/                 # Core project documents
    ├── epics/                # Epic documentation
    ├── stories/              # User story files
    └── qa/                   # Quality assurance docs
```

## Installation Process

The installer will:

1. **Check for existing installations** - Offers to backup if found
2. **Copy AP Method files** - Installs the complete framework
3. **Configure your project** - Interactive prompts for:
   - Project name
   - Documentation paths
   - Session notes configuration (Obsidian MCP or local markdown)
   - Voice notification preferences
4. **Create Claude commands** - Sets up `/ap`, `/handoff`, `/switch`, `/wrap`
5. **Update .gitignore** - Excludes session notes from version control
6. **Generate CLAUDE.md** - Project instructions for Claude AI

## Post-Installation Setup

### 1. Make Scripts Executable (Unix/Linux/macOS)

```bash
chmod +x agents/agentic-setup agents/scripts/*.sh agents/voice/*.sh
```

### 2. Verify Installation

Check that commands are available:
```bash
# List Claude commands
ls .claude/commands/

# Check settings
cat .claude/settings.json
```

### 3. Launch AP Orchestrator

In your IDE with Claude Code:
- Use `/ap` command to launch the AP Orchestrator
- Use `/handoff` to switch between agent personas
- Use `/wrap` to wrap up a session

## Configuration

The `.claude/settings.json` file contains:
- `AP_ROOT` - Path to agents directory
- `PROJECT_DOCS` - Path to project documentation
- `PROJECT_ROOT` - Your project's root directory
- `PROJECT_NAME` - Your project name
- Session notes configuration
- Voice script paths

Claude automatically reads these settings when working in your project.

## Optional Features

### Piper TTS (Text-to-Speech)

During installation, you can optionally install Piper TTS for voice notifications:
- Downloads ~100MB Piper binary and voice model
- Enables voice announcements for agent transitions
- Can be installed later with `agents/scripts/setup-piper-chat.sh`

### Obsidian MCP Integration

For cross-session memory using Obsidian:
1. Install Obsidian MCP server
2. Configure during setup with your vault path
3. Session notes will sync automatically

## Troubleshooting

### Permission Denied

If you get permission errors:
```bash
chmod +x install.sh agents/agentic-setup
```

### Existing Installation

The installer detects existing installations and offers options:
- Create a backup (recommended)
- Overwrite existing files
- Cancel installation

### Claude Commands Not Working

Ensure you're using Claude Code (claude.ai/code) and that:
1. `.claude/commands/` directory exists
2. Commands have proper permissions
3. You're in the project root directory

## Building from Source

To create your own distribution:

```bash
# From the repository root
./build-distribution.sh

# Creates dist/ap-method-v*.tar.gz
```

## What's Next?

After installation:
1. Review `/agents/README.md` for AP Method overview
2. Use `/ap` command to start the AP Orchestrator
3. Begin with the Analyst agent to create a project brief
4. Follow the AP workflow through each phase

## Support

For issues or questions:
- Check documentation in `/agents/` subdirectories
- Review task definitions in `/agents/tasks/`
- Consult orchestrator config in `/agents/ide-ap-orchestrator.cfg.md`

The AP Method streamlines AI-assisted software development through specialized agent personas and structured workflows.