#!/bin/bash

# Build script for creating AP Mapping distribution package
# This creates a versioned tar.gz file with all necessary components

set -e

# Configuration
# Read version from VERSION file if it exists
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
else
    VERSION="1.0.0"
fi
DIST_NAME="ap-mapping-v$VERSION"
DIST_DIR="dist/$DIST_NAME"

echo "=========================================="
echo "Building AP Mapping Distribution v$VERSION"
echo "=========================================="
echo ""

# Clean previous builds
if [ -d "dist" ]; then
    echo "Cleaning previous builds..."
    rm -rf dist
fi

# Create distribution directory
echo "Creating distribution structure..."
mkdir -p "$DIST_DIR"

# Copy agents directory
echo "Copying agents directory..."
cp -r agents "$DIST_DIR/"

# Clean up files that shouldn't be distributed
echo "Cleaning up distribution..."

# Count files before cleanup
LOG_COUNT=$(find "$DIST_DIR/agents" -name "*.log" -type f | wc -l)
TEMP_COUNT=$(find "$DIST_DIR/agents" \( -name "*~" -o -name "*.tmp" \) -type f | wc -l)
DS_COUNT=$(find "$DIST_DIR/agents" -name ".DS_Store" -type f | wc -l)

# Remove all log files
find "$DIST_DIR/agents" -name "*.log" -type f -delete
[ "$LOG_COUNT" -gt 0 ] && echo "  - Removed $LOG_COUNT log files"

# Remove any .DS_Store files (macOS)
find "$DIST_DIR/agents" -name ".DS_Store" -type f -delete
[ "$DS_COUNT" -gt 0 ] && echo "  - Removed $DS_COUNT .DS_Store files"

# Remove any temporary files
find "$DIST_DIR/agents" -name "*~" -type f -delete
find "$DIST_DIR/agents" -name "*.tmp" -type f -delete
[ "$TEMP_COUNT" -gt 0 ] && echo "  - Removed $TEMP_COUNT temporary files"

# Note: Hook scripts are now in installer/templates/hooks as Python files
# The old agents/hooks directory has been removed

# Remove any git files that might have been copied
find "$DIST_DIR/agents" -name ".gitignore" -type f -delete
find "$DIST_DIR/agents" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# Create VERSION file
echo "$VERSION" > "$DIST_DIR/VERSION"

# Copy installer directory with templates
echo "Copying installer directory..."
cp -r installer "$DIST_DIR/"

# Copy README from installer directory
echo "Copying distribution README..."
cp installer/README.md "$DIST_DIR/README.md"

# Create LICENSE file
echo "Creating LICENSE file..."
cat > "$DIST_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 AP Mapping Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create the tar.gz archive
echo ""
echo "Creating distribution archive..."
cd "$DIST_DIR"
tar -czf "../$DIST_NAME.tar.gz" .
cd ../..

# Copy README to dist directory for easy access
cp "$DIST_DIR/README.md" "dist/README.md"

# Calculate file size
FILE_SIZE=$(ls -lh "dist/$DIST_NAME.tar.gz" | awk '{print $5}')

# Count files in distribution
FILE_COUNT=$(find "$DIST_DIR" -type f | wc -l)

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Distribution Details:"
echo "- Package: dist/$DIST_NAME.tar.gz"
echo "- Size: $FILE_SIZE"
echo "- Files: $FILE_COUNT"
echo ""
echo "Installation Instructions:"
echo "1. Extract: tar -xzf $DIST_NAME.tar.gz"
echo "2. Install: ./installer/install.sh"
echo ""
echo "Distribution ready for release!"