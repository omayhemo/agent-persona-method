#!/bin/bash
# Test script for the new TTS system

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== TTS System Test ===${NC}"
echo ""

# Test directory setup
TEST_DIR="/tmp/ap-tts-test-$$"
PROJECT_ROOT="$TEST_DIR/test-project"
AP_ROOT="$PROJECT_ROOT/agents"

echo "Setting up test environment..."
mkdir -p "$PROJECT_ROOT/.claude"
mkdir -p "$AP_ROOT/scripts/tts-providers"
mkdir -p "$AP_ROOT/voice"

# Copy TTS files
echo "Copying TTS system files..."
cp installer/templates/scripts/tts-manager.sh "$AP_ROOT/scripts/"
cp installer/templates/scripts/configure-tts.sh "$AP_ROOT/scripts/"
cp installer/templates/scripts/tts-providers/*.sh "$AP_ROOT/scripts/tts-providers/"
cp installer/templates/voice/*.sh "$AP_ROOT/voice/"
chmod +x "$AP_ROOT/scripts"/*.sh
chmod +x "$AP_ROOT/scripts/tts-providers"/*.sh
chmod +x "$AP_ROOT/voice"/*.sh

# Create minimal settings.json
echo "Creating test settings..."
cat > "$PROJECT_ROOT/.claude/settings.json" << EOF
{
  "env": {
    "TTS_ENABLED": "true",
    "TTS_PROVIDER": "none",
    "TTS_FALLBACK_PROVIDER": "none"
  }
}
EOF

# Test 1: TTS Manager detection
echo ""
echo -e "${BLUE}Test 1: Provider Detection${NC}"
cd "$PROJECT_ROOT"
if "$AP_ROOT/scripts/tts-manager.sh" detect | grep -q "none"; then
    echo -e "${GREEN}✓ Provider detection working${NC}"
else
    echo -e "${RED}✗ Provider detection failed${NC}"
fi

# Test 2: Silent mode
echo ""
echo -e "${BLUE}Test 2: Silent Mode (none provider)${NC}"
if "$AP_ROOT/scripts/tts-manager.sh" speak "test" "This is a test message"; then
    echo -e "${GREEN}✓ Silent mode working${NC}"
else
    echo -e "${RED}✗ Silent mode failed${NC}"
fi

# Test 3: Voice scripts
echo ""
echo -e "${BLUE}Test 3: Voice Scripts${NC}"
if "$AP_ROOT/voice/speakOrchestrator.sh" "Testing orchestrator voice"; then
    echo -e "${GREEN}✓ Voice scripts working${NC}"
else
    echo -e "${RED}✗ Voice scripts failed${NC}"
fi

# Test 4: List providers
echo ""
echo -e "${BLUE}Test 4: List Providers${NC}"
"$AP_ROOT/scripts/tts-manager.sh" list

# Test 5: Configuration utility
echo ""
echo -e "${BLUE}Test 5: Configuration Utility${NC}"
if "$AP_ROOT/scripts/configure-tts.sh" show; then
    echo -e "${GREEN}✓ Configuration utility working${NC}"
else
    echo -e "${RED}✗ Configuration utility failed${NC}"
fi

# Test 6: System TTS check
echo ""
echo -e "${BLUE}Test 6: System TTS Check${NC}"
if "$AP_ROOT/scripts/tts-providers/system.sh" check; then
    echo -e "${GREEN}✓ System TTS available${NC}"
    "$AP_ROOT/scripts/tts-providers/system.sh" info
else
    echo -e "${YELLOW}⚠ System TTS not available${NC}"
fi

# Test 7: Settings update
echo ""
echo -e "${BLUE}Test 7: Settings Update${NC}"
if command -v jq >/dev/null 2>&1; then
    # Update provider in settings
    tmp_file=$(mktemp)
    jq '.env.TTS_PROVIDER = "system"' "$PROJECT_ROOT/.claude/settings.json" > "$tmp_file" && \
        mv "$tmp_file" "$PROJECT_ROOT/.claude/settings.json"
    
    # Check if update worked
    provider=$(jq -r '.env.TTS_PROVIDER' "$PROJECT_ROOT/.claude/settings.json")
    if [ "$provider" = "system" ]; then
        echo -e "${GREEN}✓ Settings update working${NC}"
    else
        echo -e "${RED}✗ Settings update failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ jq not available for settings test${NC}"
fi

# Cleanup
echo ""
echo "Cleaning up test environment..."
rm -rf "$TEST_DIR"

echo ""
echo -e "${GREEN}TTS system tests completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Run the installer with TTS options"
echo "2. Test with actual Piper installation"
echo "3. Test with ElevenLabs API key"
echo "4. Test Discord webhooks"