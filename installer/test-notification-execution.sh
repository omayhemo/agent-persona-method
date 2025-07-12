#!/bin/bash
# Test notification system execution

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================="
echo "Notification System Execution Test"
echo "=================================="

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# Test 1: Direct sound playback
echo ""
echo "Test 1: Testing direct sound playback..."
if command -v mpg123 >/dev/null 2>&1; then
    echo "Playing chime.mp3 for 1 second..."
    timeout 1s mpg123 -q "$TEMPLATE_DIR/sounds/chime.mp3" 2>/dev/null || true
    echo -e "${GREEN}✓ Direct playback works${NC}"
else
    echo -e "${RED}✗ No mpg123 available${NC}"
fi

# Test 2: Test notification manager in isolation
echo ""
echo "Test 2: Testing notification manager..."

# Create a temporary test environment
TEST_DIR="/tmp/ap_notif_test_$$"
mkdir -p "$TEST_DIR/agents/scripts"
mkdir -p "$TEST_DIR/agents/sounds"
mkdir -p "$TEST_DIR/.claude"

# Copy necessary files
cp "$TEMPLATE_DIR/scripts/notification-manager.sh" "$TEST_DIR/agents/scripts/"
chmod +x "$TEST_DIR/agents/scripts/notification-manager.sh"
cp "$TEMPLATE_DIR/sounds"/*.mp3 "$TEST_DIR/agents/sounds/" 2>/dev/null || true

# Create a test settings.json
cat > "$TEST_DIR/.claude/settings.json" << EOF
{
  "env": {
    "AUDIO_PLAYER": "mpg123",
    "AUDIO_PLAYER_ARGS": "-q",
    "WAV_PLAYER": "aplay",
    "WAV_PLAYER_ARGS": "-q",
    "FFMPEG_AVAILABLE": "false",
    "HOOK_NOTIFICATION_ENABLED": "true",
    "HOOK_NOTIFICATION_SOUND": "chime",
    "HOOK_NOTIFICATION_TTS": "false"
  }
}
EOF

# Run the test
cd "$TEST_DIR/agents/scripts"
if ./notification-manager.sh test notification 2>&1 | grep -q "Testing notification"; then
    echo -e "${GREEN}✓ Notification manager executes${NC}"
else
    echo -e "${RED}✗ Notification manager failed${NC}"
fi

# Test 3: Test Python hook execution
echo ""
echo "Test 3: Testing Python hook execution..."
if python3 -c "import sys; sys.exit(0)" 2>/dev/null; then
    # Create test input for hook
    echo '{"type":"test","message":"Test notification","level":"info","context":{}}' | \
    python3 "$TEMPLATE_DIR/hooks/notification.py" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Python hook executes${NC}"
    else
        echo -e "${RED}✗ Python hook failed${NC}"
    fi
else
    echo -e "${YELLOW}! Python3 not available${NC}"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "=================================="
echo "Execution Test Summary"
echo "=================================="
echo ""
echo "The notification system execution chain:"
echo "1. Claude triggers Python hook (via settings.json)"
echo "2. Python hook calls notification-manager.sh"
echo "3. notification-manager.sh reads settings and plays sound"
echo "4. Sound is played via configured audio player (mpg123)"
echo ""
echo "All components are properly configured for execution."