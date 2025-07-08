#!/bin/bash

# Voice script for Analyst persona using john voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with john voice
handle_input "john" "$@"