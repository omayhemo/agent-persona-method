#!/bin/bash

# Voice script for QA (Quality Assurance) persona using amy voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with amy voice
handle_input "amy" "$@"