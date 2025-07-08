#!/bin/bash

# Voice script for SM (Scrum Master) persona using kathleen voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with kathleen voice
handle_input "kathleen" "$@"