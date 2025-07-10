#!/bin/bash
#
# ElevenLabs TTS with native WSL audio playback
#

API_KEY="sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"
VOICE_ID="JBFqnCBsd6RMkjVDRZzb"  # George voice
TEXT="${1:-The first move is what sets everything in motion.}"
OUTPUT="${2:-output.mp3}"

# Function to check and install audio player
check_audio_player() {
    if command -v mpg123 &> /dev/null; then
        echo "✓ Using mpg123"
        PLAYER="mpg123 -q"
    elif command -v ffplay &> /dev/null; then
        echo "✓ Using ffplay"
        PLAYER="ffplay -nodisp -autoexit -loglevel quiet"
    elif command -v play &> /dev/null; then
        echo "✓ Using sox"
        PLAYER="play -q"
    elif command -v mplayer &> /dev/null; then
        echo "✓ Using mplayer"
        PLAYER="mplayer -really-quiet"
    elif command -v cvlc &> /dev/null; then
        echo "✓ Using VLC"
        PLAYER="cvlc --play-and-exit --intf dummy"
    else
        echo "No audio player found. Installing mpg123..."
        sudo apt-get update && sudo apt-get install -y mpg123
        if command -v mpg123 &> /dev/null; then
            PLAYER="mpg123 -q"
        else
            echo "Failed to install audio player"
            exit 1
        fi
    fi
}

echo "Generating speech..."

curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
    -H "xi-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"$TEXT\", \"model_id\": \"eleven_multilingual_v2\"}" \
    --output "$OUTPUT"

if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    echo "✓ Audio saved to: $OUTPUT"
    
    # Check for audio player
    check_audio_player
    
    echo "Playing audio..."
    if $PLAYER "$OUTPUT"; then
        echo "✓ Audio played successfully"
        echo "✓ Deleting temporary audio file..."
        rm -f "$OUTPUT"
    else
        echo "✗ Audio playback failed"
        echo "For WSL2: Make sure WSLg is enabled"
        echo "For WSL1: You need PulseAudio server on Windows"
        echo ""
        echo "Try: export PULSE_SERVER=tcp:$(grep nameserver /etc/resolv.conf | awk '{print $2}')"
    fi
else
    echo "✗ Error: Failed to generate audio"
fi