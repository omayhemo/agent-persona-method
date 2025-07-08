#!/bin/bash
# ap-env.sh
# Environment setup for AP methodology
# Source this file to set up your AP environment

# Check if required variables are set
check_required_vars() {
    local missing_vars=()
    
    [ -z "$AP_ROOT" ] && missing_vars+=("AP_ROOT")
    [ -z "$PROJECT_ROOT" ] && missing_vars+=("PROJECT_ROOT")
    [ -z "$PROJECT_NAME" ] && missing_vars+=("PROJECT_NAME")
    [ -z "$OBSIDIAN_VAULT" ] && missing_vars+=("OBSIDIAN_VAULT")
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables:"
        printf '  - %s\n' "${missing_vars[@]}"
        echo ""
        echo "Please set these variables before sourcing ap-env.sh:"
        echo "  export AP_ROOT=/path/to/ap/setup"
        echo "  export PROJECT_ROOT=/path/to/project"
        echo "  export PROJECT_NAME=YourProject"
        echo "  export OBSIDIAN_VAULT=YourVault"
        return 1
    fi
}

# Set up voice script paths
setup_voice_scripts() {
    export SPEAK_ORCHESTRATOR="$AP_ROOT/agents/voice/speakLessac.sh"
    export SPEAK_DEVELOPER="$AP_ROOT/agents/voice/speakJoe.sh"
    export SPEAK_ARCHITECT="$AP_ROOT/agents/voice/speakHFCMale.sh"
    export SPEAK_QA="$AP_ROOT/agents/voice/speakAmy.sh"
    export SPEAK_ANALYST="$AP_ROOT/agents/voice/speakHFCMale.sh"
    export SPEAK_SM="$AP_ROOT/agents/voice/speakHFC.sh"
    export SPEAK_PO="$AP_ROOT/agents/voice/speakKristin.sh"
    
    echo "✅ Voice scripts configured"
}

# Set up project paths
setup_project_paths() {
    export PROJECT_DIR="$PROJECT_ROOT/$PROJECT_NAME"
    export OBSIDIAN_DIR="$PROJECT_ROOT/$OBSIDIAN_VAULT"
    export COORDINATION_DIR="$OBSIDIAN_DIR/Coordination"
    export SESSIONS_DIR="$OBSIDIAN_DIR/Sessions"
    export RULES_DIR="$OBSIDIAN_DIR/Rules"
    
    echo "✅ Project paths configured"
}

# Main setup
if check_required_vars; then
    setup_voice_scripts
    setup_project_paths
    
    echo ""
    echo "🚀 AP Environment Configured:"
    echo "  Project: $PROJECT_NAME"
    echo "  Root: $PROJECT_ROOT"
    echo "  Obsidian: $OBSIDIAN_VAULT"
    echo "  AP Root: $AP_ROOT"
    echo ""
    echo "Ready for parallel agent development!"
else
    echo "❌ AP environment setup failed"
    return 1
fi