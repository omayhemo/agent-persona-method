#!/bin/bash
# Notification Manager - Handles audio notifications and TTS

set -e

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AP_ROOT")"

# Settings and TTS Manager
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
TTS_MANAGER="$SCRIPT_DIR/tts-manager.sh"
SOUNDS_DIR="$AP_ROOT/sounds"

# Play notification sound
play_sound() {
    local sound_name="$1"
    local sound_file="$SOUNDS_DIR/${sound_name}.mp3"
    
    if [ ! -f "$sound_file" ]; then
        return 1
    fi
    
    # Detect and use appropriate player
    if command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$sound_file" 2>/dev/null &
    elif command -v play >/dev/null 2>&1; then
        play -q "$sound_file" 2>/dev/null &
    elif command -v afplay >/dev/null 2>&1; then
        afplay "$sound_file" 2>/dev/null &
    elif command -v aplay >/dev/null 2>&1; then
        # Convert mp3 to wav for aplay
        if command -v ffmpeg >/dev/null 2>&1; then
            local temp_wav="/tmp/notification_$$.wav"
            ffmpeg -i "$sound_file" -ar 44100 "$temp_wav" -y >/dev/null 2>&1
            aplay -q "$temp_wav" 2>/dev/null &
            ( sleep 5; rm -f "$temp_wav" ) &
        fi
    fi
    
    return 0
}

# Handle notification for a specific hook
handle_notification() {
    local hook_name="$1"
    local persona="${2:-orchestrator}"
    local message="$3"
    
    # Get configuration for this hook
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local enabled=$(jq -r ".env.HOOK_${hook_name^^}_ENABLED // false" "$SETTINGS_FILE")
        local sound=$(jq -r ".env.HOOK_${hook_name^^}_SOUND // \"none\"" "$SETTINGS_FILE")
        local use_tts=$(jq -r ".env.HOOK_${hook_name^^}_TTS // false" "$SETTINGS_FILE")
        
        if [ "$enabled" != "true" ]; then
            return 0
        fi
        
        # Play sound if configured
        if [ "$sound" != "none" ] && [ "$sound" != "null" ]; then
            play_sound "$sound"
        fi
        
        # Speak via TTS if configured and message provided
        if [ "$use_tts" = "true" ] && [ -n "$message" ] && [ -f "$TTS_MANAGER" ]; then
            "$TTS_MANAGER" speak "$persona" "$message" 2>/dev/null || true
        fi
    fi
}

# Main command
case "${1:-help}" in
    notify)
        handle_notification "$2" "$3" "$4"
        ;;
    test)
        echo "Testing notification for hook: ${2:-notification}"
        handle_notification "${2:-notification}" "orchestrator" "This is a test notification"
        ;;
    install-audio-player)
        echo "Installing audio player for notification sounds..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y mpg123
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y mpg123
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S mpg123
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew >/dev/null 2>&1; then
                brew install mpg123
            fi
        fi
        ;;
    *)
        echo "Usage: $0 notify <hook_name> [persona] [message]"
        echo "       $0 test [hook_name]"
        echo "       $0 install-audio-player"
        echo ""
        echo "Hooks: notification, pre_tool, post_tool, stop, subagent_stop"
        ;;
esac