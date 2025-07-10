#!/bin/bash
#
# Install audio player for ElevenLabs TTS in WSL
#

echo "Installing native audio player for WSL..."
echo ""

# Update package list
sudo apt-get update

# Install mpg123 (lightweight, best for MP3s)
echo "Installing mpg123..."
sudo apt-get install -y mpg123

# Test if it worked
if command -v mpg123 &> /dev/null; then
    echo ""
    echo "✓ mpg123 installed successfully!"
    echo ""
    echo "Testing audio setup..."
    
    # For WSL2, check if audio works
    if grep -qi microsoft /proc/version 2>/dev/null; then
        if [[ $(uname -r) =~ WSL2 ]]; then
            echo "✓ WSL2 detected - audio should work with WSLg"
        else
            echo "⚠ WSL1 detected - you may need additional setup:"
            echo "  1. Install PulseAudio on Windows"
            echo "  2. Set PULSE_SERVER environment variable"
        fi
    fi
    
    echo ""
    echo "Audio player ready! You can now use the TTS scripts."
else
    echo "✗ Failed to install mpg123"
    echo "Try manually: sudo apt-get install mpg123"
fi