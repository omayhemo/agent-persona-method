#!/bin/bash
# AP Method Release Script
# This script automates the release process

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get version from command line
VERSION="${1:-}"
RELEASE_TYPE="${2:-}"

# Validate version format
validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+\.[0-9]+)?$ ]]; then
        echo -e "${RED}Error: Invalid version format${NC}"
        echo "Expected: MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-PRERELEASE.NUMBER"
        echo "Examples: 1.1.0, 1.2.0-beta.1, 2.0.0-rc.1"
        exit 1
    fi
}

# Check git status
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}Error: Working directory is not clean${NC}"
        echo "Please commit or stash your changes before releasing"
        git status --short
        exit 1
    fi
}

# Update version in files
update_version() {
    local version=$1
    echo -e "${BLUE}Updating version to $version...${NC}"
    
    # Update build-distribution.sh
    sed -i.bak "s/VERSION=\".*\"/VERSION=\"$version\"/" build-distribution.sh
    rm build-distribution.sh.bak
    
    # Update README.md URLs
    sed -i.bak "s/ap-method-v[0-9.]*\(-[a-zA-Z.0-9]*\)?\\.tar\\.gz/ap-method-v$version.tar.gz/g" README.md
    rm README.md.bak
    
    # Update installer README
    sed -i.bak "s/ap-method-v[0-9.]*\(-[a-zA-Z.0-9]*\)?\\.tar\\.gz/ap-method-v$version.tar.gz/g" installer/README.md
    rm installer/README.md.bak
    
    echo -e "${GREEN}✓ Version updated in all files${NC}"
}

# Generate release notes template
generate_release_notes() {
    local version=$1
    local date=$(date +%Y-%m-%d)
    
    cat > RELEASE_NOTES.md << EOF
# AP Method v$version

Released: $date

## 🎉 Highlights

<!-- Brief summary of major changes in this release -->

## ✨ New Features

<!-- List new features with descriptions -->
- **Feature Name**: Description

## 🐛 Bug Fixes

<!-- List bug fixes -->
- Fixed issue where...

## 🔧 Improvements

<!-- List improvements -->
- Enhanced performance of...

## 📚 Documentation

<!-- Documentation updates -->
- Updated guide for...

## 💔 Breaking Changes

_None in this release_

<!-- OR list breaking changes with migration paths -->

## 📦 Installation

### New Installation

\`\`\`bash
curl -L https://github.com/omayhemo/agent-persona-method/releases/download/v$version/ap-method-v$version.tar.gz | tar -xz
./installer/install.sh
\`\`\`

### Updating from Previous Version

\`\`\`bash
agents/scripts/ap-manager.sh update
\`\`\`

## 🔄 Migration Guide

<!-- If applicable, provide migration steps -->

## 📋 Full Changelog

See [CHANGELOG.md](https://github.com/omayhemo/agent-persona-method/blob/main/CHANGELOG.md) for complete history.
EOF

    echo -e "${GREEN}✓ Release notes template created: RELEASE_NOTES.md${NC}"
}

# Build distribution
build_distribution() {
    echo -e "${BLUE}Building distribution...${NC}"
    ./build-distribution.sh
    
    # Verify build
    if [ -f "dist/ap-method-v$VERSION.tar.gz" ]; then
        echo -e "${GREEN}✓ Distribution built successfully${NC}"
        ls -la dist/ap-method-v$VERSION.tar.gz
    else
        echo -e "${RED}Error: Distribution build failed${NC}"
        exit 1
    fi
}

# Create git tag
create_git_tag() {
    local version=$1
    echo -e "${BLUE}Creating git tag v$version...${NC}"
    
    # Commit changes
    git add .
    git commit -m "Release v$version

- Version bumped to $version
- Updated download URLs
- Built distribution package"
    
    # Create annotated tag
    git tag -a "v$version" -m "Release version $version"
    
    echo -e "${GREEN}✓ Git tag created: v$version${NC}"
}

# Show next steps
show_next_steps() {
    local version=$1
    
    echo ""
    echo -e "${GREEN}Release preparation complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo ""
    echo "1. Edit RELEASE_NOTES.md with actual release information"
    echo ""
    echo "2. Push to GitHub:"
    echo "   git push origin main"
    echo "   git push origin v$version"
    echo ""
    echo "3. Create GitHub release:"
    echo ""
    echo "   Using GitHub CLI:"
    echo "   gh release create v$version \\"
    echo "     --title \"AP Method v$version\" \\"
    echo "     --notes-file RELEASE_NOTES.md \\"
    echo "     dist/ap-method-v$version.tar.gz"
    echo ""
    echo "   Or manually:"
    echo "   - Go to https://github.com/omayhemo/agent-persona-method/releases"
    echo "   - Click 'Draft a new release'"
    echo "   - Select tag: v$version"
    echo "   - Upload: dist/ap-method-v$version.tar.gz"
    echo "   - Paste contents of RELEASE_NOTES.md"
    echo ""
    echo "4. Verify the release:"
    echo "   - Test download from GitHub"
    echo "   - Test ap-manager.sh update"
    echo "   - Monitor for issues"
}

# Main execution
main() {
    echo -e "${BLUE}AP Method Release Process${NC}"
    echo "=========================="
    
    # Validate inputs
    if [ -z "$VERSION" ]; then
        echo -e "${RED}Error: Version not specified${NC}"
        echo "Usage: $0 <version> [--beta|--rc|--alpha]"
        exit 1
    fi
    
    validate_version "$VERSION"
    check_git_status
    
    # Confirm with user
    echo ""
    echo "Release version: $VERSION"
    if [ -n "$RELEASE_TYPE" ]; then
        echo "Release type: ${RELEASE_TYPE#--}"
    fi
    echo ""
    read -p "Continue with release? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled"
        exit 0
    fi
    
    # Execute release steps
    update_version "$VERSION"
    generate_release_notes "$VERSION"
    build_distribution
    create_git_tag "$VERSION"
    show_next_steps "$VERSION"
}

# Run main function
main