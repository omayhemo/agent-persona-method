#!/bin/bash

# AP Method Installation Script
# Template-based installer

set -e

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for --defaults flag
USE_DEFAULTS=false
if [ "$1" = "--defaults" ] || [ "$1" = "-d" ]; then
    USE_DEFAULTS=true
    shift # Remove the flag from arguments
fi

echo "=========================================="
echo "   Agentic Persona Method Installation"
echo "=========================================="
echo ""

# Get the directory where this script is located (installer dir)
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(dirname "$INSTALLER_DIR")"

# Get target directory (default to current directory)
TARGET_DIR="${1:-.}"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "Error: Target directory '$1' does not exist"
    exit 1
}

# Special handling when running from distribution directory without arguments
if [ "$#" -eq 0 ] && [ -f "$INSTALLER_DIR/install.sh" ] && [ -d "$DIST_DIR/agents" ]; then
    if [ "$USE_DEFAULTS" = true ]; then
        echo "Running with defaults - using current directory as project"
        TARGET_DIR="$DIST_DIR"
        SKIP_COPY="true"
    else
        echo "=========================================="
        echo "AP Method Quick Setup"
        echo "=========================================="
        echo ""
        echo "You're running the installer from the extracted distribution."
        echo ""
        echo "Where would you like to install AP Method?"
        echo ""
        echo "1) Use this directory as the project (quick start)"
        echo "2) Create new project in parent directory"
        echo "3) Install to existing project (specify path)"
        echo "4) Show manual installation options"
        echo ""
        printf "${YELLOW}Enter choice (1-4) [1]: ${NC}"
        read CHOICE
        CHOICE="${CHOICE:-1}"
        
        case $CHOICE in
            1)
                echo ""
                echo "Using current directory as project directory."
                echo "This will configure AP Method in-place without copying files."
                TARGET_DIR="$DIST_DIR"
                SKIP_COPY="true"
                echo ""
                ;;
            2)
                echo ""
                printf "${YELLOW}Enter project name [my-project]: ${NC}"
                read PROJ_NAME
                PROJ_NAME="${PROJ_NAME:-my-project}"
                TARGET_DIR="../$PROJ_NAME"
                
                # Create project directory
                mkdir -p "$TARGET_DIR"
                TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
                echo "Creating new project at: $TARGET_DIR"
                echo ""
                ;;
            3)
                echo ""
                printf "${YELLOW}Enter path to existing project: ${NC}"
                read PROJ_PATH
                if [ -z "$PROJ_PATH" ]; then
                    echo "Error: No path specified"
                    exit 1
                fi
                TARGET_DIR="$(cd "$PROJ_PATH" 2>/dev/null && pwd)" || {
                    echo "Error: Invalid path '$PROJ_PATH'"
                    exit 1
                }
                ;;
            4)
                echo ""
                echo "Manual Installation Options:"
                echo ""
                echo "  # Install to specific directory:"
                echo "  ./install.sh /path/to/your/project"
                echo ""
                echo "  # Install to parent directory:"
                echo "  ./install.sh .."
                echo ""
                echo "  # Create and install to new project:"
                echo "  mkdir ../my-project && ./install.sh ../my-project"
                echo ""
                exit 0
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
fi

# Set project root
PROJECT_ROOT="$TARGET_DIR"

# Function to get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [ "$USE_DEFAULTS" = true ]; then
        echo "$default"
    else
        printf "${YELLOW}%s [%s]: ${NC}" "$prompt" "$default" >&2
        read response
        echo "${response:-$default}"
    fi
}

# Function to create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Function to check and install audio dependencies
check_audio_dependencies() {
    local provider="$1"
    
    case "$provider" in
        elevenlabs)
            # ElevenLabs needs MP3 player
            if ! command -v mpg123 >/dev/null 2>&1 && \
               ! command -v ffplay >/dev/null 2>&1 && \
               ! command -v afplay >/dev/null 2>&1; then
                return 1
            fi
            ;;
        piper|system)
            # Piper/System need WAV player
            if ! command -v aplay >/dev/null 2>&1 && \
               ! command -v play >/dev/null 2>&1 && \
               ! command -v afplay >/dev/null 2>&1; then
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to replace variables in templates
replace_variables() {
    local input_file="$1"
    local output_file="$2"
    
    # Create a temporary file for processing
    local temp_file=$(mktemp)
    
    # Copy input to temp file
    cp "$input_file" "$temp_file"
    
    # Replace all variables
    sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$temp_file"
    sed -i "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" "$temp_file"
    sed -i "s|{{AP_ROOT}}|$AP_ROOT|g" "$temp_file"
    sed -i "s|{{PROJECT_DOCS}}|$PROJECT_DOCS|g" "$temp_file"
    sed -i "s|{{CLAUDE_DIR}}|$CLAUDE_DIR|g" "$temp_file"
    sed -i "s|{{CLAUDE_COMMANDS_DIR}}|$CLAUDE_COMMANDS_DIR|g" "$temp_file"
    sed -i "s|{{NOTES_TYPE}}|$NOTES_TYPE|g" "$temp_file"
    sed -i "s|{{SESSION_NOTES_PATH}}|$SESSION_NOTES_PATH|g" "$temp_file"
    sed -i "s|{{RULES_PATH}}|$RULES_PATH|g" "$temp_file"
    sed -i "s|{{ARCHIVE_PATH}}|$ARCHIVE_PATH|g" "$temp_file"
    sed -i "s|{{FALLBACK_SESSION_NOTES_PATH}}|$FALLBACK_SESSION_NOTES_PATH|g" "$temp_file"
    sed -i "s|{{FALLBACK_RULES_PATH}}|$FALLBACK_RULES_PATH|g" "$temp_file"
    sed -i "s|{{FALLBACK_ARCHIVE_PATH}}|$FALLBACK_ARCHIVE_PATH|g" "$temp_file"
    sed -i "s|{{SPEAK_ORCHESTRATOR}}|$SPEAK_ORCHESTRATOR|g" "$temp_file"
    sed -i "s|{{SPEAK_DEVELOPER}}|$SPEAK_DEVELOPER|g" "$temp_file"
    sed -i "s|{{SPEAK_ARCHITECT}}|$SPEAK_ARCHITECT|g" "$temp_file"
    sed -i "s|{{SPEAK_ANALYST}}|$SPEAK_ANALYST|g" "$temp_file"
    sed -i "s|{{SPEAK_QA}}|$SPEAK_QA|g" "$temp_file"
    sed -i "s|{{SPEAK_PM}}|$SPEAK_PM|g" "$temp_file"
    sed -i "s|{{SPEAK_PO}}|$SPEAK_PO|g" "$temp_file"
    sed -i "s|{{SPEAK_SM}}|$SPEAK_SM|g" "$temp_file"
    sed -i "s|{{SPEAK_DESIGN_ARCHITECT}}|$SPEAK_DESIGN_ARCHITECT|g" "$temp_file"
    
    # Move the processed file to the output location
    mv "$temp_file" "$output_file"
}

echo ""
echo "Step 1: Copying Agents Directory"
echo "-------------------------------"

# Copy agents directory if not skipping
if [ "$SKIP_COPY" != "true" ]; then
    if [ -d "$DIST_DIR/agents" ]; then
        echo "Copying agents directory to: $PROJECT_ROOT/agents"
        cp -r "$DIST_DIR/agents" "$PROJECT_ROOT/"
        AP_ROOT="$PROJECT_ROOT/agents"
    else
        echo "Error: agents directory not found in distribution"
        exit 1
    fi
else
    echo "Using existing agents directory"
    AP_ROOT="$PROJECT_ROOT/agents"
fi

# Replace voice scripts with TTS-manager versions
echo "Installing updated voice scripts..."
rm -rf "$AP_ROOT/voice"
mkdir -p "$AP_ROOT/voice"
cp "$INSTALLER_DIR/templates/voice"/*.sh "$AP_ROOT/voice/"
chmod +x "$AP_ROOT/voice"/*.sh

# Install ap-manager.sh
echo "Installing AP Method Manager..."
if [ -f "$INSTALLER_DIR/templates/scripts/ap-manager.sh" ]; then
    cp "$INSTALLER_DIR/templates/scripts/ap-manager.sh" "$AP_ROOT/scripts/"
    chmod +x "$AP_ROOT/scripts/ap-manager.sh"
    echo "- Installed ap-manager.sh for updates and management"
else
    echo "- Warning: ap-manager.sh not found in installer"
fi

echo ""
echo "Step 2: Project Configuration"
echo "-----------------------------"

# Get project name
PROJECT_NAME=$(get_input "Enter project name" "$(basename "$PROJECT_ROOT")")

# Get project documentation path
DEFAULT_PROJECT_DOCS="$PROJECT_ROOT/project_documentation"
PROJECT_DOCS=$(get_input "Enter project documentation path" "$DEFAULT_PROJECT_DOCS")

# Get .claude directory
DEFAULT_CLAUDE_DIR="$PROJECT_ROOT/.claude"
CLAUDE_DIR=$(get_input "Enter .claude directory" "$DEFAULT_CLAUDE_DIR")
CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

echo ""
echo "Step 3: Session Notes Configuration"
echo "-----------------------------------"

if [ "$USE_DEFAULTS" = true ]; then
    NOTES_SYSTEM="2"
    echo "Using default: Markdown files"
else
    echo "Choose your session notes system:"
    echo "1) Obsidian MCP (recommended if you use Obsidian)"
    echo "2) Markdown files (standalone markdown files)"
    printf "${YELLOW}Enter choice (1-2) [2]: ${NC}"
    read NOTES_SYSTEM
    NOTES_SYSTEM="${NOTES_SYSTEM:-2}"
fi

# Configure based on choice
if [ "$NOTES_SYSTEM" = "1" ]; then
    NOTES_TYPE="obsidian"
    if [ "$USE_DEFAULTS" = true ]; then
        OBSIDIAN_ROOT="."
        SESSION_NOTES_PATH="Sessions/"
        RULES_PATH="Rules/"
        ARCHIVE_PATH="Sessions/Archive/"
    else
        echo ""
        echo "Configure Obsidian MCP paths (relative to Obsidian vault root):"
        printf "${YELLOW}Obsidian vault root (relative to project) [.]: ${NC}"
        read OBSIDIAN_ROOT
        OBSIDIAN_ROOT="${OBSIDIAN_ROOT:-.}"
        
        printf "${YELLOW}Session notes folder (in Obsidian) [Sessions/]: ${NC}"
        read SESSION_NOTES_PATH
        SESSION_NOTES_PATH="${SESSION_NOTES_PATH:-Sessions/}"
        
        printf "${YELLOW}Rules folder (in Obsidian) [Rules/]: ${NC}"
        read RULES_PATH
        RULES_PATH="${RULES_PATH:-Rules/}"
        
        printf "${YELLOW}Archive folder (in Obsidian) [Sessions/Archive/]: ${NC}"
        read ARCHIVE_PATH
        ARCHIVE_PATH="${ARCHIVE_PATH:-Sessions/Archive/}"
    fi
else
    NOTES_TYPE="markdown"
    SESSION_NOTES_PATH="$PROJECT_DOCS/session_notes"
    RULES_PATH="$PROJECT_DOCS/rules"
    ARCHIVE_PATH="$PROJECT_DOCS/session_notes/archive"
    
    # Create the directories
    ensure_dir "$SESSION_NOTES_PATH"
    ensure_dir "$RULES_PATH"
    ensure_dir "$ARCHIVE_PATH"
fi

# Create fallback session notes path for Obsidian users
if [ "$NOTES_TYPE" = "obsidian" ]; then
    FALLBACK_SESSION_NOTES_PATH="$PROJECT_DOCS/session_notes"
    FALLBACK_RULES_PATH="$PROJECT_DOCS/rules"
    FALLBACK_ARCHIVE_PATH="$PROJECT_DOCS/session_notes/archive"
    
    # Create fallback directories
    ensure_dir "$FALLBACK_SESSION_NOTES_PATH"
    ensure_dir "$FALLBACK_RULES_PATH"
    ensure_dir "$FALLBACK_ARCHIVE_PATH"
else
    FALLBACK_SESSION_NOTES_PATH=""
    FALLBACK_RULES_PATH=""
    FALLBACK_ARCHIVE_PATH=""
fi

# Set voice script paths
SPEAK_ORCHESTRATOR="\${AP_ROOT}/voice/speakOrchestrator.sh"
SPEAK_DEVELOPER="\${AP_ROOT}/voice/speakDeveloper.sh"
SPEAK_ARCHITECT="\${AP_ROOT}/voice/speakArchitect.sh"
SPEAK_ANALYST="\${AP_ROOT}/voice/speakAnalyst.sh"
SPEAK_QA="\${AP_ROOT}/voice/speakQA.sh"
SPEAK_PM="\${AP_ROOT}/voice/speakPM.sh"
SPEAK_PO="\${AP_ROOT}/voice/speakPO.sh"
SPEAK_SM="\${AP_ROOT}/voice/speakSM.sh"
SPEAK_DESIGN_ARCHITECT="\${AP_ROOT}/voice/speakDesignArchitect.sh"

echo ""
echo "Step 4: Creating Project Documentation Structure"
echo "-----------------------------------------------"

# Create project documentation structure
ensure_dir "$PROJECT_DOCS"
ensure_dir "$PROJECT_DOCS/base"
ensure_dir "$PROJECT_DOCS/epics"
ensure_dir "$PROJECT_DOCS/stories"
ensure_dir "$PROJECT_DOCS/qa"
ensure_dir "$PROJECT_DOCS/qa/test-plans"
ensure_dir "$PROJECT_DOCS/qa/automation"

# Copy project documentation README from template
replace_variables "$INSTALLER_DIR/templates/project_documentation/README.md.template" "$PROJECT_DOCS/README.md"
echo "Created project documentation structure at: $PROJECT_DOCS"

echo ""
echo "Step 5: Creating Environment Configuration"
echo "-----------------------------------------"

# Create .claude/settings.json from template
ensure_dir "$CLAUDE_DIR"
replace_variables "$INSTALLER_DIR/templates/claude/settings.json.template" "$CLAUDE_DIR/settings.json"
echo "Created Claude settings configuration: $CLAUDE_DIR/settings.json"

# Create .claude/hooks directory and copy hook scripts
ensure_dir "$CLAUDE_DIR/hooks"
if [ -d "$INSTALLER_DIR/templates/hooks" ]; then
    cp "$INSTALLER_DIR/templates/hooks"/*.py "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks"/*.py 2>/dev/null || true
    echo "Created Claude hooks: $CLAUDE_DIR/hooks/"
fi

echo ""
echo "Step 6: Creating .claude Commands"
echo "---------------------------------"

ensure_dir "$CLAUDE_COMMANDS_DIR"

# Create ap.md command
replace_variables "$INSTALLER_DIR/templates/claude/commands/ap.md.template" "$CLAUDE_COMMANDS_DIR/ap.md"

# Create handoff.md command
replace_variables "$INSTALLER_DIR/templates/claude/commands/handoff.md.template" "$CLAUDE_COMMANDS_DIR/handoff.md"

# Create wrap.md command based on notes type
if [ "$NOTES_TYPE" = "obsidian" ]; then
    replace_variables "$INSTALLER_DIR/templates/claude/commands/wrap.md.obsidian.template" "$CLAUDE_COMMANDS_DIR/wrap.md"
else
    replace_variables "$INSTALLER_DIR/templates/claude/commands/wrap.md.markdown.template" "$CLAUDE_COMMANDS_DIR/wrap.md"
fi

# Create session-note-setup.md command based on notes type
if [ "$NOTES_TYPE" = "obsidian" ]; then
    replace_variables "$INSTALLER_DIR/templates/claude/commands/session-note-setup.md.obsidian.template" "$CLAUDE_COMMANDS_DIR/session-note-setup.md"
else
    replace_variables "$INSTALLER_DIR/templates/claude/commands/session-note-setup.md.markdown.template" "$CLAUDE_COMMANDS_DIR/session-note-setup.md"
fi

# Create switch.md command
replace_variables "$INSTALLER_DIR/templates/claude/commands/switch.md.template" "$CLAUDE_COMMANDS_DIR/switch.md"

echo "Created .claude commands in: $CLAUDE_COMMANDS_DIR"

echo ""
echo "Step 7: Setting Up Python Hooks"
echo "-------------------------------"

# Python hooks are already copied and made executable in Step 5
echo "✓ Python hooks configured in $CLAUDE_DIR/hooks/"

echo ""
echo "Step 8: Configuring Text-to-Speech (TTS) System"
echo "-----------------------------------------------"

# Install TTS manager
echo "Installing TTS manager..."
cp "$INSTALLER_DIR/templates/scripts/tts-manager.sh" "$AP_ROOT/scripts/"
chmod +x "$AP_ROOT/scripts/tts-manager.sh"

# Install TTS configuration utility
cp "$INSTALLER_DIR/templates/scripts/configure-tts.sh" "$AP_ROOT/scripts/"
chmod +x "$AP_ROOT/scripts/configure-tts.sh"

# Create TTS providers directory
mkdir -p "$AP_ROOT/scripts/tts-providers"
cp "$INSTALLER_DIR/templates/scripts/tts-providers"/*.sh "$AP_ROOT/scripts/tts-providers/"
chmod +x "$AP_ROOT/scripts/tts-providers"/*.sh

# Create TTS setup directory
mkdir -p "$AP_ROOT/scripts/tts-setup"
cp "$INSTALLER_DIR/templates/scripts/tts-setup"/*.sh "$AP_ROOT/scripts/tts-setup/"
chmod +x "$AP_ROOT/scripts/tts-setup"/*.sh

# Configure TTS provider
if [ "$USE_DEFAULTS" = true ]; then
    echo "Using default TTS configuration (Piper - offline)"
    TTS_PROVIDER="piper"
else
    echo ""
    echo "Select a Text-to-Speech (TTS) provider:"
    echo ""
    echo "1) Piper (local, offline, ~100MB download)"
    echo "2) ElevenLabs (cloud, high quality, requires API key)"
    echo "3) System TTS (uses OS built-in TTS)"
    echo "4) Discord (send notifications to Discord channel)"
    echo "5) None (silent mode, no audio)"
    echo ""
    printf "${YELLOW}Select TTS provider (1-5) [1]: ${NC}"
    read tts_choice
    
    case "${tts_choice:-1}" in
        1)
            TTS_PROVIDER="piper"
            ;;
        2)
            TTS_PROVIDER="elevenlabs"
            echo ""
            echo "Checking for MP3 audio player..."
            
            # Check for MP3-capable players
            if command -v mpg123 >/dev/null 2>&1; then
                echo "✓ Found mpg123"
            elif command -v ffplay >/dev/null 2>&1; then
                echo "✓ Found ffplay (ffmpeg)"
            elif command -v afplay >/dev/null 2>&1; then
                echo "✓ Found afplay (macOS)"
            else
                echo "No MP3-capable player found."
                echo ""
                
                # Check if we can install mpg123
                if command -v apt-get >/dev/null 2>&1; then
                    if [ "$USE_DEFAULTS" = true ]; then
                        INSTALL_MPG123="y"
                    else
                        printf "${YELLOW}Would you like to install mpg123 for audio playback? (Y/n): ${NC}"
                        read -n 1 -r
                        echo
                        INSTALL_MPG123="${REPLY:-y}"
                    fi
                    
                    if [[ $INSTALL_MPG123 =~ ^[Yy]$ ]]; then
                        echo "Installing mpg123..."
                        sudo apt-get update >/dev/null 2>&1
                        if sudo apt-get install -y mpg123; then
                            echo "✓ mpg123 installed successfully"
                        else
                            echo "⚠ Failed to install mpg123. Audio playback may not work correctly."
                            echo "  You can install it manually later with: sudo apt-get install mpg123"
                        fi
                    else
                        echo "⚠ Warning: Without an MP3 player, you may hear static instead of speech."
                        echo "  Install mpg123 later with: sudo apt-get install mpg123"
                    fi
                elif command -v brew >/dev/null 2>&1; then
                    # macOS with Homebrew
                    echo "To install mpg123 on macOS: brew install mpg123"
                else
                    echo "⚠ Please install mpg123 manually for audio playback"
                fi
            fi
            echo ""
            ;;
        3)
            TTS_PROVIDER="system"
            echo ""
            echo "System TTS uses your operating system's built-in text-to-speech."
            echo "Make sure you have TTS configured in your OS settings."
            ;;
        4)
            TTS_PROVIDER="discord"
            ;;
        5)
            TTS_PROVIDER="none"
            ;;
        *)
            echo "Invalid choice. Using Piper."
            TTS_PROVIDER="piper"
            ;;
    esac
fi

echo ""
echo "Selected TTS provider: $TTS_PROVIDER"

# Configure the selected provider
case "$TTS_PROVIDER" in
    piper)
        echo ""
        echo "Checking for audio player..."
        
        # Check for audio players that can handle WAV files
        if command -v aplay >/dev/null 2>&1; then
            echo "✓ Found aplay (ALSA)"
        elif command -v play >/dev/null 2>&1; then
            echo "✓ Found play (SoX)"
        elif command -v afplay >/dev/null 2>&1; then
            echo "✓ Found afplay (macOS)"
        elif command -v mpg123 >/dev/null 2>&1; then
            echo "✓ Found mpg123"
        elif command -v ffplay >/dev/null 2>&1; then
            echo "✓ Found ffplay (ffmpeg)"
        else
            echo "No audio player found."
            echo ""
            
            # Try to install audio player
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing ALSA audio utilities..."
                sudo apt-get update >/dev/null 2>&1
                if sudo apt-get install -y alsa-utils; then
                    echo "✓ ALSA utilities installed successfully"
                else
                    echo "⚠ Failed to install audio player. Audio playback may not work."
                fi
            else
                echo "⚠ Please install an audio player manually"
            fi
        fi
        
        echo ""
        echo "Installing Piper TTS system..."
        
        # Check if setup script exists
        PIPER_SETUP_SCRIPT="$INSTALLER_DIR/templates/scripts/tts-setup/setup-piper-chat.sh"
        if [ -f "$PIPER_SETUP_SCRIPT" ]; then
            # Run the piper setup script
            if [ "$USE_DEFAULTS" = true ]; then
                USE_DEFAULTS=true bash "$PIPER_SETUP_SCRIPT" "$PROJECT_ROOT/.piper"
            else
                bash "$PIPER_SETUP_SCRIPT" "$PROJECT_ROOT/.piper"
            fi
            
            if [ $? -eq 0 ]; then
                echo "✓ Piper installation completed successfully!"
            else
                echo "⚠ Piper installation encountered issues."
                echo "You can manually install it later."
            fi
        fi
        ;;
        
    elevenlabs)
        echo ""
        # Run ElevenLabs configuration
        "$AP_ROOT/scripts/tts-providers/elevenlabs.sh" configure
        ;;
        
    system)
        echo ""
        # Check system TTS availability
        "$AP_ROOT/scripts/tts-providers/system.sh" configure
        ;;
        
    discord)
        echo ""
        # Configure Discord webhook
        "$AP_ROOT/scripts/tts-providers/discord.sh" configure
        ;;
        
    none)
        echo "Silent mode selected. No audio output will be produced."
        ;;
esac

# Update settings with TTS provider
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    tmp_file=$(mktemp)
    jq ".env.TTS_PROVIDER = \"$TTS_PROVIDER\" | .env.TTS_ENABLED = \"true\"" "$SETTINGS_FILE" > "$tmp_file" && mv "$tmp_file" "$SETTINGS_FILE"
fi

echo ""
echo "Step 8a: Configuring Notification System"
echo "----------------------------------------"

# Function to detect available audio players
detect_audio_player() {
    echo "Detecting available audio players..."
    
    # Check for MP3 players
    if command -v mpg123 >/dev/null 2>&1; then
        AUDIO_PLAYER="mpg123"
        AUDIO_PLAYER_ARGS="-q"
        echo "✓ Found mpg123 for MP3 playback"
    elif command -v play >/dev/null 2>&1; then
        AUDIO_PLAYER="play"
        AUDIO_PLAYER_ARGS="-q"
        echo "✓ Found sox/play for audio playback"
    elif command -v afplay >/dev/null 2>&1; then
        AUDIO_PLAYER="afplay"
        AUDIO_PLAYER_ARGS=""
        echo "✓ Found afplay (macOS) for audio playback"
    elif command -v ffplay >/dev/null 2>&1; then
        AUDIO_PLAYER="ffplay"
        AUDIO_PLAYER_ARGS="-nodisp -autoexit -loglevel quiet"
        echo "✓ Found ffplay for audio playback"
    else
        AUDIO_PLAYER="none"
        AUDIO_PLAYER_ARGS=""
        echo -e "${YELLOW}⚠ No MP3 player found. Audio notifications will not work.${NC}"
        echo ""
        echo "To enable audio notifications, install one of:"
        echo "  - Linux: sudo apt-get install mpg123"
        echo "  - macOS: brew install mpg123"
        echo "  - Alternative: sudo apt-get install sox"
    fi
    
    # Check for WAV players (fallback)
    if [ "$AUDIO_PLAYER" = "none" ] && command -v aplay >/dev/null 2>&1; then
        WAV_PLAYER="aplay"
        WAV_PLAYER_ARGS="-q"
        echo "✓ Found aplay for WAV playback (limited support)"
    else
        WAV_PLAYER="none"
        WAV_PLAYER_ARGS=""
    fi
    
    # Check for ffmpeg (for conversion)
    if command -v ffmpeg >/dev/null 2>&1; then
        FFMPEG_AVAILABLE="true"
        echo "✓ Found ffmpeg for audio conversion"
    else
        FFMPEG_AVAILABLE="false"
    fi
}

# Function to configure individual hook
configure_hook() {
    local hook_name="$1"
    local hook_display="$2"
    local hook_var_prefix="$3"
    
    echo ""
    echo "Configuring $hook_display hook:"
    echo "1) No notification"
    echo "2) Audible notification sound only"
    if [ "$TTS_PROVIDER" != "none" ]; then
        echo "3) TTS only"
        echo "4) Both audible notification sound and TTS"
        printf "${YELLOW}Select option (1-4) [1]: ${NC}"
    else
        printf "${YELLOW}Select option (1-2) [1]: ${NC}"
    fi
    
    read hook_option
    hook_option="${hook_option:-1}"
    
    # Set variables based on selection
    eval "${hook_var_prefix}_ENABLED=false"
    eval "${hook_var_prefix}_SOUND=none"
    eval "${hook_var_prefix}_TTS=false"
    
    case "$hook_option" in
        2)
            eval "${hook_var_prefix}_ENABLED=true"
            select_notification_sound "$hook_var_prefix"
            ;;
        3)
            if [ "$TTS_PROVIDER" != "none" ]; then
                eval "${hook_var_prefix}_ENABLED=true"
                eval "${hook_var_prefix}_TTS=true"
            fi
            ;;
        4)
            if [ "$TTS_PROVIDER" != "none" ]; then
                eval "${hook_var_prefix}_ENABLED=true"
                eval "${hook_var_prefix}_TTS=true"
                select_notification_sound "$hook_var_prefix"
            fi
            ;;
    esac
}

# Function to select notification sound
select_notification_sound() {
    local var_prefix="$1"
    
    echo ""
    echo "Select notification sound:"
    echo "1) Chime - Pleasant bell chime"
    echo "2) Ping - Modern digital ping"
    echo "3) Bell - Traditional notification bell"
    echo "4) Whoosh - Smooth transition sound"
    echo "5) Success - Positive completion sound"
    printf "${YELLOW}Select sound (1-5) [1]: ${NC}"
    
    read sound_choice
    sound_choice="${sound_choice:-1}"
    
    case "$sound_choice" in
        1) eval "${var_prefix}_SOUND=chime" ;;
        2) eval "${var_prefix}_SOUND=ping" ;;
        3) eval "${var_prefix}_SOUND=bell" ;;
        4) eval "${var_prefix}_SOUND=whoosh" ;;
        5) eval "${var_prefix}_SOUND=success" ;;
        *) eval "${var_prefix}_SOUND=chime" ;;
    esac
}

# Initialize audio player variables
AUDIO_PLAYER="none"
AUDIO_PLAYER_ARGS=""
WAV_PLAYER="none"
WAV_PLAYER_ARGS=""
FFMPEG_AVAILABLE="false"

# Check if user wants to configure notifications
if [ "$USE_DEFAULTS" = true ]; then
    SETUP_NOTIFICATIONS=false
else
    printf "${YELLOW}Would you like to setup audible notifications? (Y/n): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        SETUP_NOTIFICATIONS=false
    else
        SETUP_NOTIFICATIONS=true
    fi
fi

if [ "$SETUP_NOTIFICATIONS" = true ]; then
    # Detect audio players first
    echo ""
    detect_audio_player
    
    # Warn if no audio player available
    if [ "$AUDIO_PLAYER" = "none" ] && [ "$WAV_PLAYER" = "none" ]; then
        echo ""
        echo -e "${YELLOW}WARNING: No audio player detected!${NC}"
        echo "Audio notifications will not work without an audio player."
        echo ""
        echo "Would you like to:"
        echo "1) Install mpg123 now (recommended)"
        echo "2) Continue without audio support"
        echo "3) Cancel notification setup"
        printf "${YELLOW}Select option (1-3) [2]: ${NC}"
        read install_choice
        install_choice="${install_choice:-2}"
        
        case "$install_choice" in
            1)
                echo ""
                echo "Installing mpg123..."
                if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                    if command -v apt-get >/dev/null 2>&1; then
                        sudo apt-get update && sudo apt-get install -y mpg123
                    elif command -v yum >/dev/null 2>&1; then
                        sudo yum install -y mpg123
                    elif command -v pacman >/dev/null 2>&1; then
                        sudo pacman -S mpg123
                    else
                        echo -e "${RED}Unable to install mpg123 automatically${NC}"
                        echo "Please install manually: sudo apt-get install mpg123"
                    fi
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    if command -v brew >/dev/null 2>&1; then
                        brew install mpg123
                    else
                        echo -e "${RED}Unable to install mpg123 automatically${NC}"
                        echo "Please install Homebrew first: https://brew.sh"
                    fi
                fi
                # Re-detect after installation
                detect_audio_player
                ;;
            3)
                SETUP_NOTIFICATIONS=false
                ;;
        esac
    fi
fi

if [ "$SETUP_NOTIFICATIONS" = true ]; then
    # Copy notification sounds
    echo ""
    echo "Installing notification sounds..."
    mkdir -p "$AP_ROOT/sounds"
    if [ -d "$INSTALLER_DIR/templates/sounds" ]; then
        cp "$INSTALLER_DIR/templates/sounds"/*.mp3 "$AP_ROOT/sounds/" 2>/dev/null || true
        chmod 644 "$AP_ROOT/sounds"/*.mp3 2>/dev/null || true
    fi
    
    # Copy notification manager
    if [ -f "$INSTALLER_DIR/templates/scripts/notification-manager.sh" ]; then
        cp "$INSTALLER_DIR/templates/scripts/notification-manager.sh" "$AP_ROOT/scripts/"
        chmod +x "$AP_ROOT/scripts/notification-manager.sh"
    fi
    
    # Explain hooks
    echo ""
    echo "Audible notifications are available on 5 hooks:"
    echo "- Notification: General notifications and alerts"
    echo "- Pre-tool: Before Claude uses a tool"
    echo "- Post-tool: After Claude completes a tool"
    echo "- Stop: When Claude stops/exits"
    echo "- Subagent Stop: When a subagent completes"
    echo ""
    echo "Each hook can be configured independently."
    
    # Configure each hook
    configure_hook "notification" "Notification" "HOOK_NOTIFICATION"
    configure_hook "pre_tool" "Pre-tool" "HOOK_PRE_TOOL"
    configure_hook "post_tool" "Post-tool" "HOOK_POST_TOOL"
    configure_hook "stop" "Stop" "HOOK_STOP"
    configure_hook "subagent_stop" "Subagent Stop" "HOOK_SUBAGENT_STOP"
    
    # Save notification configuration to settings
    echo ""
    echo "Saving notification configuration..."
    
    # Update settings.json with notification config
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        tmp_file=$(mktemp)
        jq ".env.AUDIO_PLAYER = \"$AUDIO_PLAYER\" |
            .env.AUDIO_PLAYER_ARGS = \"$AUDIO_PLAYER_ARGS\" |
            .env.WAV_PLAYER = \"$WAV_PLAYER\" |
            .env.WAV_PLAYER_ARGS = \"$WAV_PLAYER_ARGS\" |
            .env.FFMPEG_AVAILABLE = \"$FFMPEG_AVAILABLE\" |
            .env.HOOK_NOTIFICATION_ENABLED = \"$HOOK_NOTIFICATION_ENABLED\" |
            .env.HOOK_NOTIFICATION_SOUND = \"$HOOK_NOTIFICATION_SOUND\" |
            .env.HOOK_NOTIFICATION_TTS = \"$HOOK_NOTIFICATION_TTS\" |
            .env.HOOK_PRE_TOOL_ENABLED = \"$HOOK_PRE_TOOL_ENABLED\" |
            .env.HOOK_PRE_TOOL_SOUND = \"$HOOK_PRE_TOOL_SOUND\" |
            .env.HOOK_PRE_TOOL_TTS = \"$HOOK_PRE_TOOL_TTS\" |
            .env.HOOK_POST_TOOL_ENABLED = \"$HOOK_POST_TOOL_ENABLED\" |
            .env.HOOK_POST_TOOL_SOUND = \"$HOOK_POST_TOOL_SOUND\" |
            .env.HOOK_POST_TOOL_TTS = \"$HOOK_POST_TOOL_TTS\" |
            .env.HOOK_STOP_ENABLED = \"$HOOK_STOP_ENABLED\" |
            .env.HOOK_STOP_SOUND = \"$HOOK_STOP_SOUND\" |
            .env.HOOK_STOP_TTS = \"$HOOK_STOP_TTS\" |
            .env.HOOK_SUBAGENT_STOP_ENABLED = \"$HOOK_SUBAGENT_STOP_ENABLED\" |
            .env.HOOK_SUBAGENT_STOP_SOUND = \"$HOOK_SUBAGENT_STOP_SOUND\" |
            .env.HOOK_SUBAGENT_STOP_TTS = \"$HOOK_SUBAGENT_STOP_TTS\"" "$SETTINGS_FILE" > "$tmp_file" && mv "$tmp_file" "$SETTINGS_FILE"
    fi
    
    echo "✓ Notification system configured"
else
    # Even if notifications are disabled, detect and save audio player info
    detect_audio_player >/dev/null 2>&1
    
    # Save audio player configuration for future use
    if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
        tmp_file=$(mktemp)
        jq ".env.AUDIO_PLAYER = \"$AUDIO_PLAYER\" |
            .env.AUDIO_PLAYER_ARGS = \"$AUDIO_PLAYER_ARGS\" |
            .env.WAV_PLAYER = \"$WAV_PLAYER\" |
            .env.WAV_PLAYER_ARGS = \"$WAV_PLAYER_ARGS\" |
            .env.FFMPEG_AVAILABLE = \"$FFMPEG_AVAILABLE\"" "$SETTINGS_FILE" > "$tmp_file" && mv "$tmp_file" "$SETTINGS_FILE"
    fi
fi

echo ""
echo "Step 9: Setting Up Python Support (Optional)"
echo "-------------------------------------------"

# Ask if user wants to set up Python support
if [ "$USE_DEFAULTS" = true ]; then
    echo "Skipping Python support setup (use --python to include)"
    SETUP_PYTHON=false
else
    echo "Python support includes:"
    echo "  - Virtual environment management"
    echo "  - Python wrapper scripts"
    echo "  - Requirements management"
    echo ""
    printf "${YELLOW}Would you like to set up Python support for hooks and scripts? (y/N): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SETUP_PYTHON=true
    else
        SETUP_PYTHON=false
    fi
fi

if [ "$SETUP_PYTHON" = true ]; then
    echo "Installing Python support..."
    if [ -f "$INSTALLER_DIR/templates/python-support/install-python-support.sh" ]; then
        bash "$INSTALLER_DIR/templates/python-support/install-python-support.sh" "$PROJECT_ROOT"
        echo "✓ Python support installed"
    else
        echo "⚠ Python support files not found in installer"
    fi
else
    echo "Skipping Python support setup."
    echo "Hooks will use system Python if available."
fi

echo ""
echo "Step 10: Updating CLAUDE.md"
echo "---------------------------"

# Check if CLAUDE.md exists
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
    echo "CLAUDE.md already exists. Creating CLAUDE.md.ap-setup instead."
    CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md.ap-setup"
fi

# Create CLAUDE.md from template based on notes type
if [ "$NOTES_TYPE" = "obsidian" ]; then
    replace_variables "$INSTALLER_DIR/templates/CLAUDE.md.obsidian.template" "$CLAUDE_MD"
else
    replace_variables "$INSTALLER_DIR/templates/CLAUDE.md.markdown.template" "$CLAUDE_MD"
fi

echo "Created: $CLAUDE_MD"

echo ""
echo "Step 11: Configuring .gitignore"
echo "-------------------------------"

# Configure .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    echo "Updating existing .gitignore file..."
    
    # Check if session notes entries already exist
    if ! grep -q "# Session notes" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Session notes (both Obsidian fallback and markdown)" >> "$GITIGNORE_FILE"
        echo "project_documentation/session_notes/" >> "$GITIGNORE_FILE"
        echo "session_notes/" >> "$GITIGNORE_FILE"
        echo "" >> "$GITIGNORE_FILE"
        echo "# AP Method generated files" >> "$GITIGNORE_FILE"
        echo "CLAUDE.md.ap-setup" >> "$GITIGNORE_FILE"
        echo "harmonization.log" >> "$GITIGNORE_FILE"
        echo "" >> "$GITIGNORE_FILE"
        echo "# Piper TTS installation (project-local)" >> "$GITIGNORE_FILE"
        echo ".piper/" >> "$GITIGNORE_FILE"
        
        echo "Added AP method entries to .gitignore"
    else
        echo ".gitignore already contains session notes entries"
    fi
else
    echo "Creating new .gitignore file..."
    cp "$INSTALLER_DIR/templates/gitignore.template" "$GITIGNORE_FILE"
    echo "Created .gitignore with AP method entries"
fi

# Read VERSION file
VERSION=$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo "unknown")

echo ""
echo "=========================================="
echo "AP Method installation completed!"
echo "=========================================="
echo ""
echo "Installation Summary:"
echo "- Version: $VERSION"
echo "- Location: $PROJECT_ROOT"
echo "- Project: $PROJECT_NAME"
echo ""

# Create version file for update checking
echo "$VERSION" > "$AP_ROOT/version.txt"
echo "Created version file: $AP_ROOT/version.txt"

# Preserve installer for future management
echo "Preserving installer for updates and management..."

# Move installer to hidden directory in AP_ROOT
INSTALLER_PRESERVE_DIR="$AP_ROOT/.installer"
if [ -d "$PROJECT_ROOT/installer" ] && [ ! -d "$INSTALLER_PRESERVE_DIR" ]; then
    mkdir -p "$INSTALLER_PRESERVE_DIR"
    cp -r "$PROJECT_ROOT/installer"/* "$INSTALLER_PRESERVE_DIR/"
    echo "- Installer preserved at: $INSTALLER_PRESERVE_DIR"
fi

# Change to project root before cleaning up
cd "$PROJECT_ROOT" 2>/dev/null || true

# Remove the tar.gz file if it exists in the project root
if [ -f "$PROJECT_ROOT/ap-method-v$VERSION.tar.gz" ]; then
    rm -f "$PROJECT_ROOT/ap-method-v$VERSION.tar.gz"
    echo "- Removed distribution archive"
fi

# Remove other distribution files that aren't needed after installation
if [ -f "$PROJECT_ROOT/LICENSE" ] && [ "$SKIP_COPY" != "true" ]; then
    rm -f "$PROJECT_ROOT/LICENSE"
    echo "- Removed LICENSE file (included in agents directory)"
fi

if [ -f "$PROJECT_ROOT/VERSION" ]; then
    rm -f "$PROJECT_ROOT/VERSION"
    echo "- Removed VERSION file"
fi

# Remove the distribution README if it exists (not the installer README)
if [ -f "$PROJECT_ROOT/README.md" ] && grep -q "AP Method - Agent Persona Framework" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    rm -f "$PROJECT_ROOT/README.md"
    echo "- Removed distribution README"
fi

echo ""
echo "Next steps:"
echo ""
echo "1. Open the project in Claude Code"
echo "2. Try running: /ap"
echo "3. Check out the documentation at: $PROJECT_DOCS"
echo ""
echo "Management commands:"
echo "- Check for updates: $AP_ROOT/scripts/ap-manager.sh update"
echo "- Verify installation: $AP_ROOT/scripts/ap-manager.sh verify"
echo "- Show version: $AP_ROOT/scripts/ap-manager.sh version"
echo ""
echo "For more information, see:"
echo "- Main instructions: $CLAUDE_MD"
echo "- Agents directory: $AP_ROOT"
echo ""
echo "Enjoy using the AP Method!"