#!/bin/bash

# Build script for creating AP Method distribution package
# This creates a versioned tar.gz file with all necessary components

set -e

# Configuration
# Read version from VERSION file if it exists
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
else
    VERSION="1.0.0"
fi
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

# Clean up files that shouldn't be distributed
echo "Cleaning up distribution..."

# Count files before cleanup
LOG_COUNT=$(find "$DIST_DIR/agents" -name "*.log" -type f | wc -l)
TEMP_COUNT=$(find "$DIST_DIR/agents" \( -name "*~" -o -name "*.tmp" \) -type f | wc -l)
DS_COUNT=$(find "$DIST_DIR/agents" -name ".DS_Store" -type f | wc -l)

# Remove all log files
find "$DIST_DIR/agents" -name "*.log" -type f -delete
[ "$LOG_COUNT" -gt 0 ] && echo "  - Removed $LOG_COUNT log files"

# Remove any .DS_Store files (macOS)
find "$DIST_DIR/agents" -name ".DS_Store" -type f -delete
[ "$DS_COUNT" -gt 0 ] && echo "  - Removed $DS_COUNT .DS_Store files"

# Remove any temporary files
find "$DIST_DIR/agents" -name "*~" -type f -delete
find "$DIST_DIR/agents" -name "*.tmp" -type f -delete
[ "$TEMP_COUNT" -gt 0 ] && echo "  - Removed $TEMP_COUNT temporary files"

# Note: Hook scripts are now in installer/templates/hooks as Python files
# The old agents/hooks directory has been removed

# Remove any git files that might have been copied
find "$DIST_DIR/agents" -name ".gitignore" -type f -delete
find "$DIST_DIR/agents" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# Create VERSION file
echo "$VERSION" > "$DIST_DIR/VERSION"

# Copy installer directory with templates
echo "Copying installer directory..."
cp -r installer "$DIST_DIR/"

# Create distribution README
echo "Creating distribution README..."
cat > "$DIST_DIR/README.md" << 'EOF'
# AP Method - Agent Persona Framework

Version: 1.0.0

## What is AP Method?

The AP (Agent Persona) Method is a project-agnostic approach to orchestrating AI agents for software development. It provides specialized agent personas, each with specific expertise and responsibilities for planning and executing software projects.

## Quick Installation

### Option 1: Interactive Installation (Recommended)
```bash
tar -xzf ap-method-v1.0.0.tar.gz && cd ap-method-v1.0.0 && bash installer/install.sh && cd ..
```

### Option 2: Install with Defaults
```bash
tar -xzf ap-method-v1.0.0.tar.gz && cd ap-method-v1.0.0 && bash installer/install.sh --defaults && cd ..
```

### Option 3: Install to Specific Directory
```bash
tar -xzf ap-method-v1.0.0.tar.gz && cd ap-method-v1.0.0 && bash installer/install.sh /path/to/your/project && cd ..
```

## What Gets Installed

1. **Agents Directory**: Contains all agent personas, tasks, templates, and configurations
2. **Claude Integration**: Creates `.claude/` directory with settings and commands
3. **Project Documentation**: Sets up structured documentation folders
4. **Session Management**: Configures session notes (Obsidian or markdown)
5. **Voice System**: Optional Piper TTS for audio notifications

## Key Features

- **9 Specialized Agents**: Each agent has specific expertise (PM, Architect, Developer, QA, etc.)
- **Structured Workflow**: From project briefs to implementation
- **Session Management**: Track all work with automatic session notes
- **Voice Notifications**: Audio feedback for agent activities
- **Project Agnostic**: Works with any project type or technology stack
- **Parallel Subtask System**: Developer and QA agents can execute multiple analysis tasks in parallel for 80% time reduction

## First Steps After Installation

1. Open your project in Claude Code
2. Run `/ap` to activate the AP Orchestrator
3. Let the Orchestrator guide you through setting up your project

## Agent Personas

- **AP Orchestrator**: Central coordinator and method expert
- **Analyst**: Research, requirements gathering, project briefs
- **PM**: Product Requirements Documents, epics, planning
- **Architect**: System design, technical architecture
- **Design Architect**: UI/UX, frontend architecture
- **PO**: Backlog management, story validation
- **SM**: Story generation, sprint planning
- **Developer**: Code implementation
- **QA**: Quality assurance, testing strategies

## Commands

- `/ap` - Launch AP Orchestrator
- `/handoff <agent>` - Switch to another agent
- `/switch <agent>` - Compact session and switch
- `/wrap` - Archive session and create summary
- `/session-note-setup` - Initialize session structure
- `/parallel-review` - Developer: Execute parallel code analysis (security, performance, coverage, etc.)
- `/parallel-test` - QA: Execute parallel test suite (cross-browser, accessibility, load, etc.)

## Documentation

After installation, see:
- `CLAUDE.md` - Main instructions for Claude
- `project_documentation/` - Project-specific docs
- `agents/` - All agent configurations

## Support

For issues or questions:
- GitHub: https://github.com/chrisgscott/agentic-persona
- Documentation: See agents/README.md

## License

This project is licensed under the MIT License.
EOF

# Create LICENSE file
echo "Creating LICENSE file..."
cat > "$DIST_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 AP Method Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create the tar.gz archive
echo ""
echo "Creating distribution archive..."
cd "$DIST_DIR"
tar -czf "../$DIST_NAME.tar.gz" .
cd ../..

# Copy README to dist directory for easy access
cp "$DIST_DIR/README.md" "dist/README.md"

# Calculate file size
FILE_SIZE=$(ls -lh "dist/$DIST_NAME.tar.gz" | awk '{print $5}')

# Count files in distribution
FILE_COUNT=$(find "$DIST_DIR" -type f | wc -l)

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Distribution Details:"
echo "- Package: dist/$DIST_NAME.tar.gz"
echo "- Size: $FILE_SIZE"
echo "- Files: $FILE_COUNT"
echo ""
echo "Installation Instructions:"
echo "1. Extract: tar -xzf $DIST_NAME.tar.gz"
echo "2. Install: ./installer/install.sh"
echo ""
echo "Distribution ready for release!"