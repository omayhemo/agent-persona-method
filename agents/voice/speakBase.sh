#!/bin/bash

# Base script for voice synthesis using piper
# This script provides common functionality for all voice scripts

# Get the project root directory
VOICE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$VOICE_SCRIPT_DIR/../.." && pwd)"

# Set PIPER_DIR if not already set
# Default to project-local .piper directory
: ${PIPER_DIR:="$PROJECT_ROOT/.piper"}

# Function to check if piper is available
check_piper() {
    if [ ! -f "$PIPER_DIR/piper" ]; then
        echo "Error: piper not found at $PIPER_DIR/piper"
        echo "Please install piper or set PIPER_DIR environment variable"
        exit 1
    fi
}

# Function to get model path for a voice
get_model_path() {
    local voice_name="$1"
    echo "$PIPER_DIR/models/en_US-${voice_name}-medium.onnx"
}

# Function to synthesize speech
synthesize_speech() {
    local voice_name="$1"
    local text="$2"
    local model_path=$(get_model_path "$voice_name")
    
    # Check if model exists
    if [ ! -f "$model_path" ]; then
        echo "Error: Voice model not found at $model_path"
        echo "Please download the model for voice: $voice_name"
        exit 1
    fi
    
    # Create temporary WAV file
    local temp_wav=$(mktemp --suffix=.wav)
    
    # Synthesize speech
    echo "$text" | "$PIPER_DIR/piper" \
        --model "$model_path" \
        --output_file "$temp_wav" 2>/dev/null
    
    # Play the audio if successful
    if [ -f "$temp_wav" ]; then
        # Try different audio players
        if command -v aplay >/dev/null 2>&1; then
            aplay "$temp_wav" 2>/dev/null
        elif command -v play >/dev/null 2>&1; then
            play "$temp_wav" 2>/dev/null
        elif command -v afplay >/dev/null 2>&1; then
            afplay "$temp_wav" 2>/dev/null
        else
            echo "Warning: No audio player found. WAV file saved at: $temp_wav"
            return 1
        fi
        
        # Clean up temp file
        rm -f "$temp_wav"
    else
        echo "Error: Failed to generate speech"
        return 1
    fi
}

# Function to handle input (from arguments or stdin)
handle_input() {
    local voice_name="$1"
    local text=""
    
    # Check if text is provided as arguments
    if [ $# -gt 1 ]; then
        # Shift to remove voice_name from arguments
        shift
        text="$*"
    else
        # Read from stdin
        if [ -t 0 ]; then
            echo "Usage: $0 \"text to speak\""
            echo "   or: echo \"text to speak\" | $0"
            exit 1
        fi
        text=$(cat)
    fi
    
    # Check if we have text
    if [ -z "$text" ]; then
        echo "Error: No text provided"
        exit 1
    fi
    
    # Check piper availability
    check_piper
    
    # Synthesize and play speech
    synthesize_speech "$voice_name" "$text"
}