#!/bin/bash
# Debug version of TTS Manager to diagnose issues

set -e

# Debug log file
DEBUG_LOG="/tmp/tts-manager-debug.log"
echo "=== TTS Manager Debug Log ===" > "$DEBUG_LOG"
echo "Time: $(date)" >> "$DEBUG_LOG"
echo "Arguments: $@" >> "$DEBUG_LOG"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AP_ROOT")"

echo "SCRIPT_DIR: $SCRIPT_DIR" >> "$DEBUG_LOG"
echo "AP_ROOT: $AP_ROOT" >> "$DEBUG_LOG"
echo "PROJECT_ROOT: $PROJECT_ROOT" >> "$DEBUG_LOG"

# Load settings
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
echo "SETTINGS_FILE: $SETTINGS_FILE" >> "$DEBUG_LOG"
echo "Settings exists: $([ -f "$SETTINGS_FILE" ] && echo "yes" || echo "no")" >> "$DEBUG_LOG"

# Provider directory
PROVIDER_DIR="$SCRIPT_DIR/tts-providers"
echo "PROVIDER_DIR: $PROVIDER_DIR" >> "$DEBUG_LOG"
echo "Provider dir exists: $([ -d "$PROVIDER_DIR" ] && echo "yes" || echo "no")" >> "$DEBUG_LOG"

# Get provider from settings
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    PROVIDER=$(jq -r '.env.TTS_PROVIDER // "none"' "$SETTINGS_FILE" 2>/dev/null)
    echo "Provider from settings: $PROVIDER" >> "$DEBUG_LOG"
else
    PROVIDER="none"
    echo "Using default provider: none (jq or settings not found)" >> "$DEBUG_LOG"
fi

# Check if enabled
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    TTS_ENABLED=$(jq -r '.env.TTS_ENABLED // "true"' "$SETTINGS_FILE" 2>/dev/null)
    echo "TTS enabled: $TTS_ENABLED" >> "$DEBUG_LOG"
else
    TTS_ENABLED="true"
    echo "TTS enabled (default): $TTS_ENABLED" >> "$DEBUG_LOG"
fi

# Test provider
PROVIDER_SCRIPT="$PROVIDER_DIR/$PROVIDER.sh"
echo "Provider script: $PROVIDER_SCRIPT" >> "$DEBUG_LOG"
echo "Provider script exists: $([ -f "$PROVIDER_SCRIPT" ] && echo "yes" || echo "no")" >> "$DEBUG_LOG"
echo "Provider script executable: $([ -x "$PROVIDER_SCRIPT" ] && echo "yes" || echo "no")" >> "$DEBUG_LOG"

# Check provider availability
if [ -f "$PROVIDER_SCRIPT" ]; then
    echo "Checking provider availability..." >> "$DEBUG_LOG"
    if "$PROVIDER_SCRIPT" check >> "$DEBUG_LOG" 2>&1; then
        echo "Provider check: SUCCESS" >> "$DEBUG_LOG"
    else
        echo "Provider check: FAILED" >> "$DEBUG_LOG"
    fi
fi

# If this is a speak command, try to execute it
if [ "$1" = "speak" ]; then
    echo "Executing speak command..." >> "$DEBUG_LOG"
    echo "Persona: $2" >> "$DEBUG_LOG"
    echo "Message: $3" >> "$DEBUG_LOG"
    
    if [ "$TTS_ENABLED" = "true" ] && [ -f "$PROVIDER_SCRIPT" ]; then
        echo "Calling provider speak..." >> "$DEBUG_LOG"
        "$PROVIDER_SCRIPT" speak "$2" "$3" >> "$DEBUG_LOG" 2>&1 || echo "Provider speak failed: $?" >> "$DEBUG_LOG"
    else
        echo "Skipping speak: TTS disabled or provider not found" >> "$DEBUG_LOG"
    fi
fi

echo "=== End of debug log ===" >> "$DEBUG_LOG"
echo "Debug log written to: $DEBUG_LOG"

# Also output to stderr for immediate visibility
cat "$DEBUG_LOG" >&2