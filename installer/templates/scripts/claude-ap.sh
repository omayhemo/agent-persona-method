#!/bin/bash
# Claude AP Command Launcher
# This script launches Claude Code and automatically executes the /ap command

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "Error: Claude Code is not installed or not in PATH"
    exit 1
fi

# Launch Claude with initial instruction to execute /ap command
claude "/ap"