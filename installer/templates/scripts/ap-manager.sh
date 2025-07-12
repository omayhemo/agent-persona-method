#!/bin/bash
# AP Mapping Manager - Update, uninstall, and manage AP Mapping installation

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get AP_ROOT from environment or find it
if [ -z "$AP_ROOT" ]; then
    # Try to find AP_ROOT by looking for this script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/../personas/ap.md" ]; then
        AP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        echo -e "${RED}Error: Cannot determine AP_ROOT. Please set AP_ROOT environment variable.${NC}"
        exit 1
    fi
fi

# Configuration
REPO_OWNER="omayhemo"
REPO_NAME="agentic-persona-mapping"
VERSION_FILE="$AP_ROOT/version.txt"
INSTALLER_DIR="$AP_ROOT/.installer"
BACKUP_DIR="$AP_ROOT/.backups"

# Show usage
usage() {
    cat << EOF
AP Mapping Manager v1.0.0

Usage: $(basename "$0") <command> [options]

Commands:
    update                    Check for and install updates
    uninstall                 Remove AP Mapping from project
    verify                    Verify installation integrity
    repair                    Repair corrupted installation
    rollback                  Rollback to previous version
    version                   Show current version
    configure-tts             Configure Text-to-Speech settings
    configure-notifications   Configure notification sounds and alerts
    help                      Show this help message

Examples:
    $(basename "$0") update
    $(basename "$0") verify
    $(basename "$0") uninstall --keep-settings

EOF
}

# Get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

# Check for updates using GitHub API
check_for_updates() {
    local current_version=$(get_current_version)
    echo -e "${BLUE}Checking for updates...${NC}"
    echo "Current version: $current_version"
    
    # Get latest release from GitHub
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
    local release_info=$(curl -s "$api_url")
    
    # Check if curl succeeded
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to check for updates${NC}"
        return 1
    fi
    
    # Extract version and download URL
    local latest_version=$(echo "$release_info" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    local download_url=$(echo "$release_info" | grep '"browser_download_url"' | grep '.tar.gz' | cut -d'"' -f4)
    
    if [ -z "$latest_version" ]; then
        echo -e "${RED}Error: Could not determine latest version${NC}"
        return 1
    fi
    
    echo "Latest version: $latest_version"
    
    # Compare versions
    if [ "$latest_version" == "$current_version" ]; then
        echo -e "${GREEN}You are already running the latest version${NC}"
        return 0
    else
        echo -e "${YELLOW}Update available: $current_version → $latest_version${NC}"
        echo "Download URL: $download_url"
        
        # Ask user if they want to update
        read -p "Would you like to update now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            perform_update "$latest_version" "$download_url"
        else
            echo "Update cancelled"
        fi
    fi
}

# Perform update
perform_update() {
    local new_version="$1"
    local download_url="$2"
    local temp_dir=$(mktemp -d)
    
    echo -e "${BLUE}Downloading update...${NC}"
    
    # Download new version
    if ! curl -L -o "$temp_dir/ap-method-v$new_version.tar.gz" "$download_url"; then
        echo -e "${RED}Error: Failed to download update${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create backup
    echo -e "${BLUE}Creating backup...${NC}"
    create_backup "pre-update-$new_version"
    
    # Extract new version
    echo -e "${BLUE}Extracting update...${NC}"
    cd "$temp_dir"
    if ! tar -xzf "ap-method-v$new_version.tar.gz"; then
        echo -e "${RED}Error: Failed to extract update${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Run integrity check on current installation
    if [ -f "$INSTALLER_DIR/integrity-checker.sh" ]; then
        echo -e "${BLUE}Running pre-update integrity check...${NC}"
        "$INSTALLER_DIR/integrity-checker.sh" --quiet || true
    fi
    
    # Update installer files
    echo -e "${BLUE}Updating installer files...${NC}"
    if [ -d "$INSTALLER_DIR" ]; then
        rm -rf "$INSTALLER_DIR.old"
        mv "$INSTALLER_DIR" "$INSTALLER_DIR.old"
    fi
    mkdir -p "$INSTALLER_DIR"
    cp -r installer/* "$INSTALLER_DIR/"
    
    # Update agents directory (preserving user modifications)
    echo -e "${BLUE}Updating agents directory...${NC}"
    # This is a simplified update - in production, would need smarter merging
    cp -r agents/* "$AP_ROOT/"
    
    # Update version file
    echo "$new_version" > "$VERSION_FILE"
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Update completed successfully!${NC}"
    echo "New version: $new_version"
    
    # Run post-update integrity check
    if [ -f "$INSTALLER_DIR/integrity-checker.sh" ]; then
        echo -e "${BLUE}Running post-update integrity check...${NC}"
        "$INSTALLER_DIR/integrity-checker.sh" --quiet
    fi
}

# Create backup
create_backup() {
    local backup_name="${1:-backup-$(date +%Y%m%d-%H%M%S)}"
    mkdir -p "$BACKUP_DIR"
    
    local backup_path="$BACKUP_DIR/$backup_name.tar.gz"
    
    echo "Creating backup: $backup_path"
    tar -czf "$backup_path" -C "$AP_ROOT/.." "$(basename "$AP_ROOT")" 2>/dev/null
    
    # Keep only last 5 backups
    ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
}

# Verify installation
verify_installation() {
    echo -e "${BLUE}Verifying AP Mapping installation...${NC}"
    
    if [ -f "$INSTALLER_DIR/integrity-checker.sh" ]; then
        "$INSTALLER_DIR/integrity-checker.sh"
    else
        # Basic verification if integrity checker not available
        local issues=0
        
        # Check critical files
        for file in "personas/ap.md" "scripts/agentic-setup" "version.txt"; do
            if [ ! -f "$AP_ROOT/$file" ]; then
                echo -e "${RED}Missing: $file${NC}"
                ((issues++))
            fi
        done
        
        # Check critical directories
        for dir in "personas" "tasks" "templates" "scripts"; do
            if [ ! -d "$AP_ROOT/$dir" ]; then
                echo -e "${RED}Missing directory: $dir${NC}"
                ((issues++))
            fi
        done
        
        if [ $issues -eq 0 ]; then
            echo -e "${GREEN}Installation verified successfully${NC}"
        else
            echo -e "${RED}Found $issues issues${NC}"
            return 1
        fi
    fi
}

# Uninstall AP Mapping
uninstall_ap_method() {
    echo -e "${YELLOW}Warning: This will remove AP Mapping from your project${NC}"
    
    # Check for --keep-settings flag
    local keep_settings=false
    if [[ "$1" == "--keep-settings" ]]; then
        keep_settings=true
        echo "Settings and session notes will be preserved"
    fi
    
    read -p "Are you sure you want to uninstall AP Mapping? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled"
        return 0
    fi
    
    # Create final backup
    echo -e "${BLUE}Creating final backup...${NC}"
    create_backup "pre-uninstall-$(date +%Y%m%d-%H%M%S)"
    
    # Get project root
    local project_root="$(dirname "$AP_ROOT")"
    
    echo -e "${BLUE}Removing AP Mapping files...${NC}"
    
    # Remove agents directory
    if [ -d "$AP_ROOT" ]; then
        rm -rf "$AP_ROOT"
        echo "- Removed agents directory"
    fi
    
    # Remove Claude files (unless keeping settings)
    if [ "$keep_settings" != "true" ]; then
        if [ -d "$project_root/.claude" ]; then
            rm -rf "$project_root/.claude"
            echo "- Removed .claude directory"
        fi
        
        # Remove session notes
        if [ -d "$project_root/session-notes" ]; then
            rm -rf "$project_root/session-notes"
            echo "- Removed session notes"
        fi
    else
        # Just remove commands, keep settings
        if [ -d "$project_root/.claude/commands" ]; then
            rm -rf "$project_root/.claude/commands"
            echo "- Removed Claude commands"
        fi
    fi
    
    # Remove project documentation
    if [ -d "$project_root/project_documentation" ]; then
        read -p "Remove project documentation? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$project_root/project_documentation"
            echo "- Removed project documentation"
        fi
    fi
    
    # Update .gitignore
    if [ -f "$project_root/.gitignore" ]; then
        # Remove AP Mapping entries
        sed -i '/# AP Mapping/,/^$/d' "$project_root/.gitignore" 2>/dev/null || \
        sed -i '' '/# AP Mapping/,/^$/d' "$project_root/.gitignore" 2>/dev/null || true
        echo "- Updated .gitignore"
    fi
    
    echo ""
    echo -e "${GREEN}AP Mapping has been uninstalled${NC}"
    if [ "$keep_settings" == "true" ]; then
        echo "Settings have been preserved in .claude/settings.json"
    fi
    echo "Backups are available in: $BACKUP_DIR"
}

# Show version
show_version() {
    local version=$(get_current_version)
    echo "AP Mapping version: $version"
    
    if [ -f "$AP_ROOT/.installer/manifest.txt" ]; then
        local install_date=$(stat -c %y "$AP_ROOT/.installer/manifest.txt" 2>/dev/null | cut -d' ' -f1)
        if [ -n "$install_date" ]; then
            echo "Installed: $install_date"
        fi
    fi
}

# Main command dispatcher
case "${1:-help}" in
    update)
        check_for_updates
        ;;
    uninstall)
        uninstall_ap_method "$2"
        ;;
    verify)
        verify_installation
        ;;
    repair)
        echo -e "${BLUE}Repair functionality coming soon...${NC}"
        echo "For now, run verify to check installation"
        verify_installation
        ;;
    rollback)
        echo -e "${BLUE}Rollback functionality coming soon...${NC}"
        echo "Manual rollback: restore from $BACKUP_DIR"
        ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
        ;;
    version)
        show_version
        ;;
    configure-tts)
        # Run TTS configuration utility
        if [ -f "$SCRIPT_DIR/configure-tts.sh" ]; then
            bash "$SCRIPT_DIR/configure-tts.sh" "$2"
        else
            echo -e "${RED}TTS configuration utility not found${NC}"
            exit 1
        fi
        ;;
    configure-notifications)
        echo -e "${BLUE}Configuring notification settings...${NC}"
        # Run notification configuration wizard
        if [ -f "$SCRIPT_DIR/notification-manager.sh" ]; then
            # First check if audio player is available
            bash "$SCRIPT_DIR/notification-manager.sh" install-audio-player
            echo ""
            echo "You can test notifications with:"
            echo "  $SCRIPT_DIR/notification-manager.sh test [hook_name]"
            echo ""
            echo "To manually update notification settings, edit:"
            echo "  $PROJECT_ROOT/.claude/settings.json"
            echo ""
            echo "Available hooks: notification, pre_tool, post_tool, stop, subagent_stop"
        else
            echo -e "${RED}Notification manager not found${NC}"
            exit 1
        fi
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac