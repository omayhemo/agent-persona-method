#!/bin/bash
# Piper TTS Provider - Local, offline text-to-speech

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TTS_MANAGER_DIR="$(dirname "$SCRIPT_DIR")"
AP_ROOT="$(dirname "$TTS_MANAGER_DIR")"
PROJECT_ROOT="$(dirname "$AP_ROOT")"

# Load settings
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

# Get Piper directory from settings or default
get_piper_dir() {
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local dir=$(jq -r '.ap.tts.providers.piper.install_path // ""' "$SETTINGS_FILE" 2>/dev/null)
        if [ -n "$dir" ] && [ "$dir" != "null" ]; then
            # Expand variables
            dir="${dir//\${PROJECT_ROOT}/$PROJECT_ROOT}"
            echo "$dir"
            return
        fi
    fi
    echo "$PROJECT_ROOT/.piper"
}

PIPER_DIR=$(get_piper_dir)
PIPER_BIN="$PIPER_DIR/piper"

# Voice mappings
declare -A VOICE_MAP=(
    ["orchestrator"]="ryan"
    ["developer"]="joe"
    ["architect"]="ryan"
    ["analyst"]="kathy"
    ["qa"]="kathleen"
    ["pm"]="joe"
    ["po"]="ryan"
    ["sm"]="joe"
    ["design_architect"]="amy"
)

# Provider info
info() {
    echo "Piper TTS - Fast, offline neural text-to-speech"
}

# Check if Piper is available
check() {
    if [ -f "$PIPER_BIN" ] && [ -x "$PIPER_BIN" ]; then
        return 0
    else
        return 1
    fi
}

# Get voice for persona
get_voice() {
    local persona="$1"
    
    # First check settings for custom mapping
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local custom_voice=$(jq -r ".ap.tts.voices.$persona.piper // \"\"" "$SETTINGS_FILE" 2>/dev/null)
        if [ -n "$custom_voice" ] && [ "$custom_voice" != "null" ]; then
            echo "$custom_voice"
            return
        fi
    fi
    
    # Use default mapping
    echo "${VOICE_MAP[$persona]:-ryan}"
}

# Speak function
speak() {
    local persona="$1"
    local message="$2"
    local options="$3"
    
    if ! check; then
        return 1
    fi
    
    # Get voice for persona
    local voice=$(get_voice "$persona")
    local model_path="$PIPER_DIR/${voice}.onnx"
    
    # Check if model exists
    if [ ! -f "$model_path" ]; then
        # Try medium quality
        model_path="$PIPER_DIR/en_US-${voice}-medium.onnx"
        if [ ! -f "$model_path" ]; then
            # Fallback to ryan
            model_path="$PIPER_DIR/en_US-ryan-medium.onnx"
        fi
    fi
    
    # Ensure model exists
    if [ ! -f "$model_path" ]; then
        echo "Error: Voice model not found: $model_path" >&2
        return 1
    fi
    
    # Generate speech
    echo "$message" | "$PIPER_BIN" \
        --model "$model_path" \
        --output-raw 2>/dev/null | \
        aplay -q -r 22050 -f S16_LE -t raw - 2>/dev/null || \
        play -q -t raw -r 22050 -e signed -b 16 -c 1 - 2>/dev/null || \
        afplay -q -f LEI16 -r 22050 - 2>/dev/null || \
        return 1
}

# Configure Piper
configure() {
    echo "=== Configure Piper TTS ==="
    echo ""
    
    if check; then
        echo "Piper is already installed at: $PIPER_DIR"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Run Piper setup script
    local setup_script="$AP_ROOT/scripts/setup-piper-chat.sh"
    if [ -f "$setup_script" ]; then
        bash "$setup_script" "$PIPER_DIR"
    else
        echo "Error: Piper setup script not found at: $setup_script"
        return 1
    fi
}

# Main command handler
case "${1:-info}" in
    info)
        info
        ;;
    check)
        check
        ;;
    speak)
        speak "$2" "$3" "$4"
        ;;
    configure)
        configure
        ;;
    *)
        echo "Usage: $0 {info|check|speak|configure}"
        exit 1
        ;;
esac