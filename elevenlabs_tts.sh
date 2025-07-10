#!/bin/bash
#
# ElevenLabs Text-to-Speech Shell Script
# Converts text to speech using the ElevenLabs API via curl
#

# API Configuration
API_KEY="sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"
API_BASE_URL="https://api.elevenlabs.io"

# Default settings
DEFAULT_VOICE_ID="JBFqnCBsd6RMkjVDRZzb"  # George voice
DEFAULT_MODEL="eleven_multilingual_v2"
DEFAULT_OUTPUT="output.mp3"

# Function to display usage
usage() {
    echo "Usage: $0 'text to speak' [voice_id] [output_file]"
    echo ""
    echo "Examples:"
    echo "  $0 'Hello, world!'"
    echo "  $0 'Hello, world!' JBFqnCBsd6RMkjVDRZzb"
    echo "  $0 'Hello, world!' JBFqnCBsd6RMkjVDRZzb hello.mp3"
    echo ""
    echo "Options:"
    echo "  --no-play        Generate audio without playing"
    echo "  --list-voices    List available voices"
    echo "  --help           Show this help"
    echo ""
    echo "Available voice IDs:"
    echo "  JBFqnCBsd6RMkjVDRZzb - George"
    echo "  EXAVITQu4vr4xnSDxMaL - Bella"
    echo "  MF3mGyEYCl7XYWbV9V6O - Elli"
    echo "  TxGEqnHWrfWFTfGW9XjX - Josh"
}

# Function to detect if running in WSL
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Function to play audio file and delete it
play_audio() {
    local audio_file="$1"
    local played=false
    
    echo ""
    echo "Playing audio..."
    
    # If in WSL, use Windows to play
    if is_wsl; then
        # Use the method that worked - cmd.exe with start
        if cmd.exe /c start /min "" "$audio_file" 2>/dev/null; then
            echo "✓ Audio playing in Windows default player"
            played=true
            # Give Windows time to play the file
            sleep 3
        fi
    else
        # Native Linux - try different players in order
        if command -v mpg123 &> /dev/null; then
            mpg123 -q "$audio_file" 2>/dev/null
            played=true
        elif command -v ffplay &> /dev/null; then
            ffplay -nodisp -autoexit -loglevel quiet "$audio_file" 2>/dev/null
            played=true
        elif command -v play &> /dev/null; then
            play -q "$audio_file" 2>/dev/null
            played=true
        else
            echo "⚠ No audio player found. Install one of: mpg123, ffmpeg, or sox"
            echo "  sudo apt-get install mpg123"
        fi
    fi
    
    # Delete the file after playing
    if [ "$played" = true ]; then
        echo "✓ Deleting temporary audio file..."
        rm -f "$audio_file"
    else
        echo "⚠ Audio file kept at: $audio_file (not auto-deleted since playback failed)"
    fi
}

# Function to list available voices
list_voices() {
    echo "Fetching available voices..."
    
    response=$(curl -s -X GET "$API_BASE_URL/v2/voices" \
        -H "xi-api-key: $API_KEY")
    
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.voices[] | "\(.voice_id) - \(.name)"' | head -10
    else
        echo "Install 'jq' for formatted voice list. Raw response:"
        echo "$response" | grep -o '"voice_id":"[^"]*"' | head -10
    fi
}

# Function to convert text to speech
text_to_speech() {
    local text="$1"
    local voice_id="${2:-$DEFAULT_VOICE_ID}"
    local output_file="${3:-$DEFAULT_OUTPUT}"
    
    echo "Converting text to speech..."
    echo "Text: '$text'"
    echo "Voice ID: $voice_id"
    echo "Output file: $output_file"
    
    # Create JSON payload
    json_payload=$(cat <<EOF
{
    "text": "$text",
    "model_id": "$DEFAULT_MODEL",
    "voice_settings": {
        "stability": 0.5,
        "similarity_boost": 0.75
    }
}
EOF
)
    
    # Make API request
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/v1/text-to-speech/$voice_id" \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -H "Accept: audio/mpeg" \
        -d "$json_payload" \
        --output "$output_file")
    
    # Get HTTP status code
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo "✓ Audio saved to: $output_file"
        
        # Check if file was created and has content
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            echo "✓ File size: $(ls -lh "$output_file" | awk '{print $5}')"
            
            # Play the audio file if auto-play is enabled
            if [ "$AUTO_PLAY" = true ]; then
                play_audio "$output_file"
            else
                echo "✓ Audio file saved (auto-play disabled)"
            fi
        else
            echo "✗ Error: Output file is empty or not created"
            exit 1
        fi
    else
        echo "✗ Error: API request failed with status code $http_code"
        
        # Try to show error message if file contains JSON error
        if [ -f "$output_file" ]; then
            echo "Error details:"
            cat "$output_file"
            rm "$output_file"  # Remove error file
        fi
        exit 1
    fi
}

# Global flag for auto-play
AUTO_PLAY=true

# Main script
main() {
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed. Please install it with: sudo apt-get install curl"
        exit 1
    fi
    
    # Check arguments
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    # Handle special commands
    if [ "$1" = "--list-voices" ] || [ "$1" = "-l" ]; then
        list_voices
        exit 0
    fi
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        usage
        exit 0
    fi
    
    # Check for --no-play flag
    if [ "$1" = "--no-play" ]; then
        AUTO_PLAY=false
        shift  # Remove the flag from arguments
    fi
    
    # Process text-to-speech
    text_to_speech "$@"
}

# Run main function
main "$@"