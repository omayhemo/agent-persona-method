#!/bin/bash

# Voice script for Orchestrator persona using ryan voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with ryan voice
handle_input "ryan" "$@"