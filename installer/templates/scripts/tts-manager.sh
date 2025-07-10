#!/bin/bash
# TTS Manager - Central hub for all text-to-speech operations
# Supports multiple providers: piper, elevenlabs, system, discord, none

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AP_ROOT")"

# Source utilities
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true

# Load settings
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

# Cache directory for audio files
CACHE_DIR="$PROJECT_ROOT/.cache/tts"
mkdir -p "$CACHE_DIR"

# Provider directory
PROVIDER_DIR="$SCRIPT_DIR/tts-providers"

# Get TTS configuration from settings
get_tts_setting() {
    local key="$1"
    local default="$2"
    
    if [ -f "$SETTINGS_FILE" ]; then
        # First try jq, fall back to grep
        if command -v jq >/dev/null 2>&1; then
            local value=$(jq -r ".ap.tts.$key // \"$default\"" "$SETTINGS_FILE" 2>/dev/null)
            if [ "$value" != "null" ] && [ "$value" != "$default" ]; then
                echo "$value"
            else
                echo "$default"
            fi
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Get provider-specific setting
get_provider_setting() {
    local provider="$1"
    local key="$2"
    local default="$3"
    
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local value=$(jq -r ".ap.tts.providers.$provider.$key // \"$default\"" "$SETTINGS_FILE" 2>/dev/null)
        if [ "$value" != "null" ] && [ "$value" != "$default" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Get voice mapping for persona and provider
get_voice_mapping() {
    local persona="$1"
    local provider="$2"
    local default="$3"
    
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        local value=$(jq -r ".ap.tts.voices.$persona.$provider // \"$default\"" "$SETTINGS_FILE" 2>/dev/null)
        if [ "$value" != "null" ] && [ "$value" != "$default" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Detect available TTS providers
detect_providers() {
    local providers=()
    
    # Check for provider scripts
    if [ -d "$PROVIDER_DIR" ]; then
        for provider_script in "$PROVIDER_DIR"/*.sh; do
            if [ -f "$provider_script" ] && [ -x "$provider_script" ]; then
                local provider_name=$(basename "$provider_script" .sh)
                
                # Check if provider is available
                if "$provider_script" check >/dev/null 2>&1; then
                    providers+=("$provider_name")
                fi
            fi
        done
    fi
    
    # Always add 'none' as fallback
    if [[ ! " ${providers[@]} " =~ " none " ]]; then
        providers+=("none")
    fi
    
    echo "${providers[@]}"
}

# Get configured provider
get_provider() {
    local configured_provider=$(get_tts_setting "provider" "auto")
    
    if [ "$configured_provider" = "auto" ]; then
        # Auto-detect best available provider
        local available_providers=($(detect_providers))
        
        # Preference order: piper, elevenlabs, system, discord, none
        local preferred_order=("piper" "elevenlabs" "system" "discord" "none")
        
        for pref in "${preferred_order[@]}"; do
            if [[ " ${available_providers[@]} " =~ " $pref " ]]; then
                echo "$pref"
                return 0
            fi
        done
        
        # Fallback to first available
        echo "${available_providers[0]:-none}"
    else
        echo "$configured_provider"
    fi
}

# Main speak function
speak() {
    local persona="$1"
    local message="$2"
    local options="$3"
    
    # Check if TTS is enabled
    local tts_enabled=$(get_tts_setting "enabled" "true")
    if [ "$tts_enabled" != "true" ]; then
        return 0
    fi
    
    # Get provider
    local provider=$(get_provider)
    local provider_script="$PROVIDER_DIR/$provider.sh"
    
    # Check if provider script exists
    if [ ! -f "$provider_script" ]; then
        # Try fallback provider
        local fallback=$(get_tts_setting "fallback_provider" "none")
        provider_script="$PROVIDER_DIR/$fallback.sh"
        
        if [ ! -f "$provider_script" ]; then
            # Silent fallback
            return 0
        fi
    fi
    
    # Execute provider
    "$provider_script" speak "$persona" "$message" "$options"
}

# Speak with fallback
speak_with_fallback() {
    local persona="$1"
    local message="$2"
    
    if ! speak "$persona" "$message"; then
        # Try fallback provider
        local fallback=$(get_tts_setting "fallback_provider" "none")
        local fallback_script="$PROVIDER_DIR/$fallback.sh"
        
        if [ -f "$fallback_script" ] && [ "$fallback" != "none" ]; then
            "$fallback_script" speak "$persona" "$message"
        else
            # Text-only fallback
            echo "[TTS - $persona]: $message"
        fi
    fi
}

# Test TTS functionality
test_tts() {
    local provider="${1:-$(get_provider)}"
    
    echo "Testing TTS with provider: $provider"
    
    local test_message="Hello, this is a test of the $provider text-to-speech system."
    local provider_script="$PROVIDER_DIR/$provider.sh"
    
    if [ -f "$provider_script" ]; then
        if "$provider_script" check; then
            echo "Provider $provider is available"
            "$provider_script" speak "test" "$test_message"
            echo "Test complete"
        else
            echo "Provider $provider is not available"
            return 1
        fi
    else
        echo "Provider $provider not found"
        return 1
    fi
}

# Configure TTS provider
configure_provider() {
    local provider="$1"
    local provider_script="$PROVIDER_DIR/$provider.sh"
    
    if [ -f "$provider_script" ] && [ -x "$provider_script" ]; then
        "$provider_script" configure
    else
        echo "Provider $provider not found or not executable"
        return 1
    fi
}

# List available providers
list_providers() {
    echo "Available TTS providers:"
    echo ""
    
    local current_provider=$(get_provider)
    local providers=($(detect_providers))
    
    for provider in "${providers[@]}"; do
        if [ "$provider" = "$current_provider" ]; then
            echo "* $provider (current)"
        else
            echo "  $provider"
        fi
        
        # Show provider info
        local provider_script="$PROVIDER_DIR/$provider.sh"
        if [ -f "$provider_script" ]; then
            local info=$("$provider_script" info 2>/dev/null || echo "No description available")
            echo "    $info"
        fi
    done
}

# Clear cache
clear_cache() {
    echo "Clearing TTS cache..."
    rm -rf "$CACHE_DIR"/*
    echo "Cache cleared"
}

# Main command handler
case "${1:-speak}" in
    speak)
        speak "$2" "$3" "$4"
        ;;
    test)
        test_tts "$2"
        ;;
    configure)
        configure_provider "$2"
        ;;
    list)
        list_providers
        ;;
    clear-cache)
        clear_cache
        ;;
    detect)
        detect_providers
        ;;
    *)
        echo "Usage: $0 {speak|test|configure|list|clear-cache|detect} [args...]"
        echo ""
        echo "Commands:"
        echo "  speak <persona> <message>  - Speak a message as persona"
        echo "  test [provider]           - Test TTS functionality"
        echo "  configure <provider>      - Configure a provider"
        echo "  list                      - List available providers"
        echo "  clear-cache              - Clear audio cache"
        echo "  detect                   - Detect available providers"
        exit 1
        ;;
esac