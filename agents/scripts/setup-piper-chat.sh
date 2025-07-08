#!/bin/bash

# Piper Chat Setup Script
# This script sets up piper text-to-speech system with required dependencies

set -e

echo "========================================"
echo "Piper Chat Setup Script"
echo "========================================"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Get the directory where we'll set up piper
SETUP_DIR="${1:-$HOME/piper-chat}"

echo "Setting up Piper in: $SETUP_DIR"
echo ""

# Create and enter directory
mkdir -p "$SETUP_DIR" || handle_error "Failed to create directory $SETUP_DIR"
cd "$SETUP_DIR" || handle_error "Failed to change to directory $SETUP_DIR"

echo "Step 1: Installing Dependencies"
echo "-------------------------------"

# Check if running on a Debian-based system
if ! command_exists apt-get; then
    echo "Warning: This script is designed for Debian-based systems (Ubuntu, etc.)"
    echo "You'll need to manually install espeak-ng for your system."
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "Installing espeak-ng..."
    sudo apt-get update
    sudo apt-get install -y espeak-ng || handle_error "Failed to install espeak-ng"
fi

# Create symbolic link for espeak-ng data (fixes common path error)
echo "Creating symbolic link for espeak-ng data..."
if [ -d "/usr/lib/x86_64-linux-gnu/espeak-ng-data" ] && [ ! -L "/usr/share/espeak-ng-data" ]; then
    sudo ln -s /usr/lib/x86_64-linux-gnu/espeak-ng-data /usr/share/espeak-ng-data || \
        echo "Warning: Failed to create symbolic link (may already exist)"
fi

echo ""
echo "Step 2: Cloning Repositories"
echo "----------------------------"

# Clone repositories
echo "Cloning piper..."
if [ ! -d "piper" ]; then
    git clone https://github.com/rhasspy/piper.git || handle_error "Failed to clone piper"
else
    echo "piper directory already exists, skipping clone"
fi

echo "Cloning piper-voices..."
if [ ! -d "piper-voices" ]; then
    git clone https://github.com/rhasspy/piper-voices.git || handle_error "Failed to clone piper-voices"
else
    echo "piper-voices directory already exists, skipping clone"
fi

echo "Cloning piper-phonemize..."
if [ ! -d "piper-phonemize" ]; then
    # Try SSH first, fall back to HTTPS if it fails
    git clone git@github.com:rhasspy/piper-phonemize.git 2>/dev/null || \
    git clone https://github.com/rhasspy/piper-phonemize.git || \
    handle_error "Failed to clone piper-phonemize"
else
    echo "piper-phonemize directory already exists, skipping clone"
fi

echo ""
echo "Step 3: Building piper-phonemize"
echo "--------------------------------"

cd piper-phonemize || handle_error "Failed to enter piper-phonemize directory"

# Check if we need to install build dependencies
if ! command_exists cmake; then
    echo "Installing build dependencies..."
    sudo apt-get install -y build-essential cmake || handle_error "Failed to install build dependencies"
fi

# Build piper-phonemize
echo "Building piper-phonemize..."
mkdir -p build
cd build
cmake .. || handle_error "Failed to configure piper-phonemize"
make || handle_error "Failed to build piper-phonemize"

echo "Installing piper-phonemize..."
sudo make install || echo "Warning: Failed to install piper-phonemize system-wide (continuing anyway)"

cd "$SETUP_DIR"

echo ""
echo "Step 4: Building piper"
echo "---------------------"

cd piper || handle_error "Failed to enter piper directory"

# Build piper
echo "Building piper..."
make || handle_error "Failed to build piper"

# Copy piper binary to main directory
echo "Copying piper binary..."
cp build/piper "$SETUP_DIR/" || handle_error "Failed to copy piper binary"

cd "$SETUP_DIR"

echo ""
echo "Step 5: Downloading Voice Models"
echo "--------------------------------"

# Create models directory
mkdir -p models
cd models

# Base URL for piper models
BASE_URL="https://github.com/rhasspy/piper/releases/download/v1.2.0"

# Function to download a voice model
download_voice() {
    local voice_name="$1"
    local voice_desc="$2"
    
    if [ ! -f "${voice_name}.onnx" ]; then
        echo "Downloading ${voice_desc} (${voice_name})..."
        wget -q --show-progress "${BASE_URL}/${voice_name}.onnx" || \
            echo "Warning: Failed to download ${voice_name}"
        wget -q "${BASE_URL}/${voice_name}.onnx.json" || \
            echo "Warning: Failed to download ${voice_name} config"
    else
        echo "${voice_desc} already exists, skipping..."
    fi
}

echo ""
echo "Downloading 5 women's voices..."
echo "------------------------------"

# Women's voices
download_voice "en_US-amy-medium" "Amy (woman, medium quality)"
download_voice "en_US-kusal-medium" "Kusal (woman, medium quality)"
download_voice "en_US-kathleen-low" "Kathleen (woman, low quality)"
download_voice "en_US-lessac-medium" "Lessac (woman, medium quality)"
download_voice "en_US-libritts_r-medium" "LibriTTS-R (woman, medium quality)"

echo ""
echo "Downloading 4 men's voices..."
echo "----------------------------"

# Men's voices
download_voice "en_US-ryan-medium" "Ryan (man, medium quality)"
download_voice "en_US-joe-medium" "Joe (man, medium quality)"
download_voice "en_US-danny-low" "Danny (man, low quality)"
download_voice "en_US-john-medium" "John (man, medium quality)"

cd ..

echo ""
echo "Voice models downloaded successfully!"
echo ""

echo ""
echo "Step 6: Creating Test Script"
echo "----------------------------"

# Create a test script
cat > test-piper.sh << 'EOF'
#!/bin/bash

# Test script for piper with voice selection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to list available voices
list_voices() {
    echo "Available voices:"
    echo ""
    echo "Women's voices:"
    echo "  1) amy      - Amy (medium quality)"
    echo "  2) kusal    - Kusal (medium quality)"
    echo "  3) kathleen - Kathleen (low quality)"
    echo "  4) lessac   - Lessac (medium quality)"
    echo "  5) libritts - LibriTTS-R (medium quality)"
    echo ""
    echo "Men's voices:"
    echo "  6) ryan     - Ryan (medium quality)"
    echo "  7) joe      - Joe (medium quality)"
    echo "  8) danny    - Danny (low quality)"
    echo "  9) john     - John (medium quality)"
}

# Map voice names to model files
get_model_file() {
    case "$1" in
        amy|1)      echo "en_US-amy-medium.onnx" ;;
        kusal|2)    echo "en_US-kusal-medium.onnx" ;;
        kathleen|3) echo "en_US-kathleen-low.onnx" ;;
        lessac|4)   echo "en_US-lessac-medium.onnx" ;;
        libritts|5) echo "en_US-libritts_r-medium.onnx" ;;
        ryan|6)     echo "en_US-ryan-medium.onnx" ;;
        joe|7)      echo "en_US-joe-medium.onnx" ;;
        danny|8)    echo "en_US-danny-low.onnx" ;;
        john|9)     echo "en_US-john-medium.onnx" ;;
        *)          echo "" ;;
    esac
}

# Parse arguments
if [ "$1" == "--list" ] || [ "$1" == "-l" ]; then
    list_voices
    exit 0
fi

# Get voice selection
VOICE="${1:-amy}"
MODEL_FILE=$(get_model_file "$VOICE")

if [ -z "$MODEL_FILE" ]; then
    echo "Error: Unknown voice '$VOICE'"
    echo ""
    list_voices
    echo ""
    echo "Usage: $0 [voice-name|number] [text]"
    echo "   or: $0 --list"
    exit 1
fi

MODEL="$SCRIPT_DIR/models/$MODEL_FILE"

if [ ! -f "$MODEL" ]; then
    echo "Error: Model file not found: $MODEL"
    echo "Please run the setup script first."
    exit 1
fi

# Get text to speak (from argument or stdin)
if [ -n "$2" ]; then
    TEXT="${@:2}"
else
    TEXT="Hello world, this is a test of the piper text to speech system using the $VOICE voice."
fi

echo "Using voice: $VOICE ($(basename "$MODEL_FILE" .onnx))"
echo "Text: $TEXT"
echo ""

# Generate audio
echo "$TEXT" | "$SCRIPT_DIR/piper" --model "$MODEL" --output_file test-output.wav

if [ -f "test-output.wav" ]; then
    echo "Success! Audio saved to test-output.wav"
    
    # Try to play the audio if a player is available
    if command -v aplay >/dev/null 2>&1; then
        echo "Playing audio..."
        aplay test-output.wav
    elif command -v ffplay >/dev/null 2>&1; then
        echo "Playing audio..."
        ffplay -nodisp -autoexit test-output.wav 2>/dev/null
    else
        echo "No audio player found. Install 'alsa-utils' for aplay or 'ffmpeg' for ffplay to hear the output."
    fi
else
    echo "Error: Failed to generate audio"
fi
EOF

chmod +x test-piper.sh

echo ""
echo "========================================"
echo "Piper Chat Setup Complete!"
echo "========================================"
echo ""
echo "Installation directory: $SETUP_DIR"
echo ""
echo "9 US English voices installed:"
echo "  Women: amy, kusal, kathleen, lessac, libritts"
echo "  Men: ryan, joe, danny, john"
echo ""
echo "To test piper with different voices:"
echo "  cd $SETUP_DIR"
echo "  ./test-piper.sh --list              # List all voices"
echo "  ./test-piper.sh amy                 # Use Amy's voice"
echo "  ./test-piper.sh joe \"Hello there\"   # Use Joe's voice with custom text"
echo "  ./test-piper.sh 3                   # Use voice #3 (Kathleen)"
echo ""
echo "Or use piper directly:"
echo "  echo 'Your text' | ./piper --model models/en_US-amy-medium.onnx --output_file output.wav"
echo ""
echo "Voice samples: https://rhasspy.github.io/piper-samples/"
echo ""