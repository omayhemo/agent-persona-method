#!/bin/bash

# Voice script for Developer persona using joe voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with joe voice
handle_input "joe" "$@"