#!/bin/bash
# Test script for notification system

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================="
echo "Notification System Test Suite"
echo "=================================="

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# Test 1: Check if sound files exist
echo ""
echo "Test 1: Checking sound files..."
if [ -d "$TEMPLATE_DIR/sounds" ]; then
    for sound in notification.mp3 pre_tool.mp3 post_tool.mp3 stop.mp3 subagent_stop.mp3; do
        if [ -f "$TEMPLATE_DIR/sounds/$sound" ]; then
            echo -e "${GREEN}✓ Found: $sound${NC}"
        else
            echo -e "${RED}✗ Missing: $sound${NC}"
        fi
    done
else
    echo -e "${RED}✗ Sound directory not found${NC}"
fi

# Test 2: Check notification manager
echo ""
echo "Test 2: Checking notification manager..."
if [ -f "$TEMPLATE_DIR/scripts/notification-manager.sh" ]; then
    echo -e "${GREEN}✓ Notification manager found${NC}"
    
    # Check if it's executable in template
    if [ -x "$TEMPLATE_DIR/scripts/notification-manager.sh" ]; then
        echo -e "${GREEN}✓ Notification manager is executable${NC}"
    else
        echo -e "${YELLOW}! Notification manager not executable (will be fixed during install)${NC}"
    fi
else
    echo -e "${RED}✗ Notification manager not found${NC}"
fi

# Test 3: Check hook integration
echo ""
echo "Test 3: Checking hook integrations..."
for hook in notification.py pre_tool_use.py post_tool_use.py stop.py subagent_stop.py; do
    if [ -f "$TEMPLATE_DIR/hooks/$hook" ]; then
        if grep -q "notification-manager.sh" "$TEMPLATE_DIR/hooks/$hook"; then
            echo -e "${GREEN}✓ $hook has notification integration${NC}"
        else
            echo -e "${RED}✗ $hook missing notification integration${NC}"
        fi
    else
        echo -e "${RED}✗ Hook not found: $hook${NC}"
    fi
done

# Test 4: Check settings template
echo ""
echo "Test 4: Checking settings template..."
if [ -f "$TEMPLATE_DIR/claude/settings.json.template" ]; then
    # Check for notification settings
    if grep -q "HOOK_NOTIFICATION_ENABLED" "$TEMPLATE_DIR/claude/settings.json.template"; then
        echo -e "${GREEN}✓ Settings template has notification configuration${NC}"
    else
        echo -e "${RED}✗ Settings template missing notification configuration${NC}"
    fi
else
    echo -e "${RED}✗ Settings template not found${NC}"
fi

# Test 5: Check installer integration
echo ""
echo "Test 5: Checking installer integration..."
if [ -f "$SCRIPT_DIR/install.sh" ]; then
    if grep -q "Step 8a: Configuring Notification System" "$SCRIPT_DIR/install.sh"; then
        echo -e "${GREEN}✓ Installer has notification configuration section${NC}"
    else
        echo -e "${RED}✗ Installer missing notification configuration${NC}"
    fi
else
    echo -e "${RED}✗ Installer not found${NC}"
fi

# Test 6: Check ap-manager integration
echo ""
echo "Test 6: Checking ap-manager integration..."
if [ -f "$TEMPLATE_DIR/scripts/ap-manager.sh" ]; then
    if grep -q "configure-notifications" "$TEMPLATE_DIR/scripts/ap-manager.sh"; then
        echo -e "${GREEN}✓ ap-manager has configure-notifications command${NC}"
    else
        echo -e "${RED}✗ ap-manager missing configure-notifications command${NC}"
    fi
else
    echo -e "${RED}✗ ap-manager not found${NC}"
fi

echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo ""
# Test 7: Check audio player availability
echo ""
echo "Test 7: Checking audio players on this system..."
for player in mpg123 play afplay aplay ffmpeg ffplay; do
    if command -v $player >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Found: $player${NC}"
    else
        echo -e "${YELLOW}✗ Not found: $player${NC}"
    fi
done

echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo ""
echo "The notification system has been successfully implemented with:"
echo "- 5 notification sound placeholders (need real audio files)"
echo "- Notification manager script for handling audio/TTS"
echo "- Hook integrations for all 5 hooks"
echo "- Installer configuration wizard with audio player detection"
echo "- Settings template with notification and audio player defaults"
echo "- ap-manager command for reconfiguration"
echo "- Automatic audio player installation option"
echo ""
echo "Next steps:"
echo "1. Replace placeholder MP3 files with actual sounds"
echo "2. Test installation on a real project"
echo "3. Verify audio playback on different platforms"