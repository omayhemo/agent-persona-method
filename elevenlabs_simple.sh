#!/bin/bash
#
# Simple ElevenLabs TTS - Minimal example with auto-play
#

API_KEY="sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"
VOICE_ID="JBFqnCBsd6RMkjVDRZzb"  # George voice
TEXT="${1:-The first move is what sets everything in motion.}"
OUTPUT="${2:-output.mp3}"

echo "Generating speech..."

curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
    -H "xi-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"$TEXT\", \"model_id\": \"eleven_multilingual_v2\"}" \
    --output "$OUTPUT"

if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    echo "✓ Audio saved to: $OUTPUT"
    
    echo "Playing audio..."
    
    # Try native Linux players first
    if command -v mpg123 &> /dev/null; then
        mpg123 -q "$OUTPUT" 2>/dev/null && rm -f "$OUTPUT"
    elif command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$OUTPUT" 2>/dev/null && rm -f "$OUTPUT"
    elif command -v play &> /dev/null; then
        play -q "$OUTPUT" 2>/dev/null && rm -f "$OUTPUT"
    else
        # If no native player, check if in WSL and use Windows as fallback
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo "No Linux audio player found, using Windows..."
            cmd.exe /c start "" "$OUTPUT" 2>/dev/null && {
                sleep 3
                rm -f "$OUTPUT"
            }
        else
            echo "No audio player found. Install one of these:"
            echo "  sudo apt-get install mpg123     # Recommended - lightweight MP3 player"
            echo "  sudo apt-get install ffmpeg     # Includes ffplay"
            echo "  sudo apt-get install sox         # Includes play command"
        fi
    fi
else
    echo "✗ Error: Failed to generate audio"
fi