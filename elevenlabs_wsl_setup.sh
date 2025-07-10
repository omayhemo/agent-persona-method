#!/bin/bash
#
# Setup script for better audio playback in WSL
#

echo "ElevenLabs TTS - WSL Audio Setup"
echo "================================"
echo ""
echo "This script will help you set up audio playback in WSL."
echo ""

# Check if in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "This script is for WSL only. Exiting."
    exit 1
fi

echo "Option 1: Install mpg123 (Recommended)"
echo "--------------------------------------"
echo "mpg123 plays audio through WSL2's audio support (requires WSLg)"
echo ""
echo "To install mpg123:"
echo "  sudo apt update"
echo "  sudo apt install mpg123"
echo ""

echo "Option 2: Use Windows audio (current method)"
echo "-------------------------------------------"
echo "The scripts currently use PowerShell to play audio without popups."
echo ""

echo "Option 3: Install PulseAudio for WSL1"
echo "-------------------------------------"
echo "For WSL1, you need PulseAudio on Windows. See:"
echo "https://github.com/DesktopECHO/T95-H616-Malware/blob/master/Enable-PulseAudio-WSL.md"
echo ""

# Test if mpg123 is available
if command -v mpg123 &> /dev/null; then
    echo "✓ mpg123 is already installed!"
else
    echo "Would you like to install mpg123 now? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt install -y mpg123
        echo "✓ mpg123 installed successfully!"
    fi
fi

echo ""
echo "Testing audio playback methods..."
echo ""

# Create a test file
TEST_FILE="/tmp/test_audio.mp3"
API_KEY="sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"

echo "Generating test audio..."
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb" \
    -H "xi-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"text": "Audio test successful", "model_id": "eleven_multilingual_v2"}' \
    --output "$TEST_FILE"

if [ -f "$TEST_FILE" ] && [ -s "$TEST_FILE" ]; then
    echo "✓ Test audio generated"
    
    # Test mpg123
    if command -v mpg123 &> /dev/null; then
        echo ""
        echo "Testing mpg123..."
        mpg123 -q "$TEST_FILE" 2>/dev/null && echo "✓ mpg123 works!"
    fi
    
    # Test PowerShell
    echo ""
    echo "Testing PowerShell (no popup)..."
    win_path=$(wslpath -w "$TEST_FILE")
    powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName presentationCore
        \$player = New-Object System.Windows.Media.MediaPlayer
        \$player.Open('$win_path')
        \$player.Play()
        Start-Sleep -Seconds 2
        \$player.Close()
    " 2>/dev/null && echo "✓ PowerShell audio works!"
    
    rm -f "$TEST_FILE"
fi

echo ""
echo "Setup complete! The TTS scripts will automatically use the best available method."