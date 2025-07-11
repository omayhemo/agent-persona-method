#!/bin/bash

# Voice script for PO (Product Owner) persona using danny voice

# Source the base script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/speakBase.sh"

# Handle input with danny voice
handle_input "danny" "$@"