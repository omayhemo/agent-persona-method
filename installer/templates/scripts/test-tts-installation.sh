#!/bin/bash
# Test TTS installation and diagnose issues

echo "=== TTS Installation Test ==="
echo ""

# Get script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$AP_ROOT")"

echo "1. Checking directories..."
echo "   Script dir: $SCRIPT_DIR"
echo "   AP root: $AP_ROOT"
echo "   Project root: $PROJECT_ROOT"
echo ""

echo "2. Checking settings file..."
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo "   ✓ Settings file exists: $SETTINGS_FILE"
    
    # Check if jq is available
    if command -v jq >/dev/null 2>&1; then
        echo "   ✓ jq is available"
        
        # Extract TTS settings
        TTS_ENABLED=$(jq -r '.env.TTS_ENABLED // "false"' "$SETTINGS_FILE")
        TTS_PROVIDER=$(jq -r '.env.TTS_PROVIDER // "none"' "$SETTINGS_FILE")
        
        echo "   - TTS enabled: $TTS_ENABLED"
        echo "   - TTS provider: $TTS_PROVIDER"
        
        # Check provider-specific settings
        if [ "$TTS_PROVIDER" = "elevenlabs" ]; then
            API_KEY_REF=$(jq -r '.env.TTS_ELEVENLABS_API_KEY // ""' "$SETTINGS_FILE")
            if [ -n "$API_KEY_REF" ]; then
                echo "   - ElevenLabs API key: configured (${API_KEY_REF:0:20}...)"
                
                # Try to decode if encrypted
                if [[ "$API_KEY_REF" == encrypted:* ]]; then
                    ENCRYPTED="${API_KEY_REF#encrypted:}"
                    DECODED=$(echo "$ENCRYPTED" | base64 -d 2>/dev/null || echo "decode failed")
                    if [ "$DECODED" != "decode failed" ] && [ -n "$DECODED" ]; then
                        echo "   - API key decoding: ✓ successful"
                    else
                        echo "   - API key decoding: ✗ failed"
                    fi
                fi
            else
                echo "   - ElevenLabs API key: not configured"
            fi
        fi
    else
        echo "   ✗ jq not found - cannot parse settings"
    fi
else
    echo "   ✗ Settings file not found: $SETTINGS_FILE"
fi
echo ""

echo "3. Checking TTS manager..."
TTS_MANAGER="$SCRIPT_DIR/tts-manager.sh"
if [ -f "$TTS_MANAGER" ]; then
    echo "   ✓ TTS manager exists: $TTS_MANAGER"
    if [ -x "$TTS_MANAGER" ]; then
        echo "   ✓ TTS manager is executable"
    else
        echo "   ✗ TTS manager is not executable"
        echo "   Fix with: chmod +x $TTS_MANAGER"
    fi
else
    echo "   ✗ TTS manager not found: $TTS_MANAGER"
fi
echo ""

echo "4. Checking provider scripts..."
PROVIDER_DIR="$SCRIPT_DIR/tts-providers"
if [ -d "$PROVIDER_DIR" ]; then
    echo "   ✓ Provider directory exists: $PROVIDER_DIR"
    
    # List provider scripts
    for provider in "$PROVIDER_DIR"/*.sh; do
        if [ -f "$provider" ]; then
            PROVIDER_NAME=$(basename "$provider" .sh)
            echo -n "   - $PROVIDER_NAME: "
            if [ -x "$provider" ]; then
                echo -n "executable"
                
                # Check if it's the current provider
                if [ "$PROVIDER_NAME" = "$TTS_PROVIDER" ]; then
                    echo -n " (current)"
                fi
                
                # Test provider check
                if "$provider" check >/dev/null 2>&1; then
                    echo " - available ✓"
                else
                    echo " - not available ✗"
                fi
            else
                echo "not executable ✗"
            fi
        fi
    done
else
    echo "   ✗ Provider directory not found: $PROVIDER_DIR"
fi
echo ""

echo "5. Testing voice scripts..."
VOICE_DIR="$AP_ROOT/voice"
if [ -d "$VOICE_DIR" ]; then
    echo "   ✓ Voice directory exists: $VOICE_DIR"
    
    # Test one voice script
    TEST_SCRIPT="$VOICE_DIR/speakOrchestrator.sh"
    if [ -f "$TEST_SCRIPT" ]; then
        echo "   ✓ Sample voice script exists: speakOrchestrator.sh"
        if [ -x "$TEST_SCRIPT" ]; then
            echo "   ✓ Voice script is executable"
        else
            echo "   ✗ Voice script is not executable"
        fi
    else
        echo "   ✗ Sample voice script not found"
    fi
else
    echo "   ✗ Voice directory not found: $VOICE_DIR"
fi
echo ""

echo "6. Testing TTS functionality..."
if [ -f "$TTS_MANAGER" ] && [ -x "$TTS_MANAGER" ]; then
    echo "   Running: $TTS_MANAGER test"
    "$TTS_MANAGER" test
else
    echo "   ✗ Cannot test - TTS manager not available"
fi
echo ""

echo "7. Testing voice script directly..."
if [ -f "$TEST_SCRIPT" ] && [ -x "$TEST_SCRIPT" ]; then
    echo "   Running: $TEST_SCRIPT \"Test message\""
    "$TEST_SCRIPT" "This is a test of the AP Mapping text-to-speech system"
    echo "   If you didn't hear anything, check the logs above for issues"
else
    echo "   ✗ Cannot test - voice script not available"
fi
echo ""

echo "=== Test Complete ==="
echo ""
echo "If TTS is not working, check:"
echo "1. Is TTS enabled in settings.json?"
echo "2. Is the correct provider selected?"
echo "3. Are API keys properly configured?"
echo "4. Are all scripts executable?"
echo "5. Are audio players installed (mpg123, afplay, etc.)?"
echo ""
echo "For more details, run the debug version:"
echo "  cp $SCRIPT_DIR/tts-manager-debug.sh $SCRIPT_DIR/tts-manager.sh"
echo "  $TEST_SCRIPT \"Test message\""
echo "  cat /tmp/tts-manager-debug.log"