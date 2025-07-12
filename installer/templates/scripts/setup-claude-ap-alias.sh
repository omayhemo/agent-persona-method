#!/bin/bash
# Setup script for claude-ap alias
# This creates an alias that properly launches Claude with AP orchestrator

cat << 'EOF'
# Add this to your ~/.bashrc or ~/.zshrc file:

# Claude AP Mapping launcher
claude-ap() {
    # Create a temporary prompt file that forces AP execution
    local tmp_prompt=$(mktemp)
    cat > "$tmp_prompt" << 'PROMPT'
Execute the /ap command fully, including all parallel initialization tasks.
PROMPT
    
    # Launch Claude with the prompt
    claude < "$tmp_prompt"
    rm -f "$tmp_prompt"
}

# Alternative: Direct alias (simpler but less reliable)
alias cap='claude "/ap"'

# To use: Just type 'claude-ap' or 'cap' in your terminal
EOF

echo ""
echo "To install, add the above function to your shell configuration file:"
echo "  - For bash: ~/.bashrc"
echo "  - For zsh: ~/.zshrc"
echo ""
echo "Then reload your shell or run: source ~/.bashrc"