#!/bin/bash

# Voice script for Design Architect persona using kusal voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with kusal voice
handle_input "kusal" "$@"