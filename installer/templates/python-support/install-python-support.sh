#!/bin/bash
# AP Mapping - Python Support Installer
# This script sets up Python environment for AP Mapping hooks and scripts

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the target directory (where AP Mapping is installed)
TARGET_DIR="${1:-$(pwd)}"

echo -e "${GREEN}AP Mapping - Python Support Setup${NC}"
echo "================================================"
echo "Target directory: $TARGET_DIR"
echo

# Check if Python is installed
echo -n "Checking Python installation... "
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Not found${NC}"
    echo
    echo "Python 3 is required for AP Mapping hooks and scripts."
    echo "Please install Python 3.8 or later, then run this script again."
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
echo -e "${GREEN}Found Python $PYTHON_VERSION${NC}"

# Copy Python support files
echo "Installing Python support files..."

# Create support directory if it doesn't exist
SUPPORT_DIR="$TARGET_DIR/agents/python-support"
mkdir -p "$SUPPORT_DIR"

# Copy files from templates
cp "$(dirname "$0")/setup-python.sh" "$SUPPORT_DIR/"
cp "$(dirname "$0")/python-wrapper.sh" "$SUPPORT_DIR/"
cp "$(dirname "$0")/activate-python.sh" "$SUPPORT_DIR/"
cp "$(dirname "$0")/requirements.txt" "$SUPPORT_DIR/"

# Make scripts executable
chmod +x "$SUPPORT_DIR"/*.sh

echo -e "${GREEN}Python support files installed${NC}"

# Ask if user wants to set up virtual environment now
echo
read -p "Would you like to set up a Python virtual environment now? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting up Python virtual environment..."
    cd "$SUPPORT_DIR"
    ./setup-python.sh
    cd - >/dev/null
else
    echo "You can set up the Python environment later by running:"
    echo "  cd $SUPPORT_DIR && ./setup-python.sh"
fi

echo
echo -e "${GREEN}Python support installation complete!${NC}"
echo
echo "The following Python support tools are now available:"
echo "  - $SUPPORT_DIR/setup-python.sh      # Set up virtual environment"
echo "  - $SUPPORT_DIR/activate-python.sh   # Activate virtual environment"
echo "  - $SUPPORT_DIR/python-wrapper.sh    # Run Python scripts in venv"
echo
echo "AP Mapping hooks will work with system Python by default."
echo "Use the virtual environment for any additional Python packages."