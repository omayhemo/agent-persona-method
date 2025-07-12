# AP Mapping Release Process

This document outlines the complete release process for the AP Mapping, including version management, build procedures, and GitHub release creation.

## Overview

The AP Mapping uses GitHub Releases for distribution, with semantic versioning and automated update checking via `ap-manager.sh`.

## Version Management

### Semantic Versioning

We follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, incompatible API changes
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, backward compatible

### Pre-release Versions

For testing and beta releases:
- Beta: `v1.1.0-beta.1`
- Release Candidate: `v1.1.0-rc.1`
- Alpha: `v1.1.0-alpha.1`

## Release Checklist

### Pre-Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in `build-distribution.sh`
- [ ] Migration guide written (if breaking changes)
- [ ] Update path tested from previous version

### Release Steps

#### 1. Update Version

Edit `build-distribution.sh`:
```bash
VERSION="1.1.0"  # Update to new version
```

#### 2. Update Documentation

Update version references in:
- `README.md` (download URLs)
- `installer/README.md`
- `CHANGELOG.md` (add release notes)

#### 3. Build Distribution

```bash
# From project root
./build-distribution.sh

# Verify the build
ls -la dist/
# Should show:
# - ap-method-v1.1.0.tar.gz
# - ap-method-v1.1.0/
# - README.md
```

#### 4. Test the Distribution

```bash
# Test installation in a clean directory
cd /tmp
mkdir test-install
cd test-install
tar -xzf /path/to/dist/ap-method-v1.1.0.tar.gz
./installer/install.sh

# Test update from previous version
# (Set up previous version first, then test update)
```

#### 5. Commit Changes

```bash
git add .
git commit -m "Release v1.1.0

- Add feature X
- Fix bug Y
- Improve Z"
```

#### 6. Create Git Tag

```bash
# Create annotated tag
git tag -a v1.1.0 -m "Release version 1.1.0"

# Verify tag
git tag -l -n
```

#### 7. Push to GitHub

```bash
# Push commits
git push origin main

# Push tag
git push origin v1.1.0
```

#### 8. Create GitHub Release

##### Option A: GitHub Web Interface

1. Navigate to https://github.com/omayhemo/agentic-persona-mapping/releases
2. Click "Draft a new release"
3. Select tag: `v1.1.0`
4. Release title: `AP Mapping v1.1.0`
5. Upload `dist/ap-method-v1.1.0.tar.gz`
6. Paste release notes (see template below)
7. Check "Set as the latest release"
8. Click "Publish release"

##### Option B: GitHub CLI

```bash
# Create release with GitHub CLI
gh release create v1.1.0 \
  --title "AP Mapping v1.1.0" \
  --notes-file RELEASE_NOTES.md \
  dist/ap-method-v1.1.0.tar.gz
```

## Release Notes Template

```markdown
# AP Mapping v1.1.0

Released: YYYY-MM-DD

## 🎉 Highlights

Brief summary of major changes in this release.

## ✨ New Features

- **Feature Name**: Description of the feature
- **Another Feature**: What it does and why it's useful

## 🐛 Bug Fixes

- Fixed issue where...
- Resolved problem with...

## 🔧 Improvements

- Enhanced performance of...
- Improved error handling in...

## 📚 Documentation

- Updated guide for...
- Added examples for...

## 💔 Breaking Changes

_None in this release_

OR

- **Change**: Description and migration path

## 📦 Installation

### New Installation

```bash
curl -L https://github.com/omayhemo/agentic-persona-mapping/releases/download/v1.1.0/ap-method-v1.1.0.tar.gz | tar -xz
./installer/install.sh
```

### Updating from Previous Version

```bash
agents/scripts/ap-manager.sh update
```

## 🔄 Migration Guide

_(If applicable)_

For users upgrading from v1.0.x:
1. Step one
2. Step two

## 🙏 Acknowledgments

Thanks to contributors...

## 📋 Full Changelog

See [CHANGELOG.md](https://github.com/omayhemo/agentic-persona-mapping/blob/main/CHANGELOG.md) for complete history.
```

## Post-Release Tasks

### 1. Verify Release

- [ ] Check GitHub release page
- [ ] Download and test the release artifact
- [ ] Verify `ap-manager.sh update` detects new version
- [ ] Test clean installation
- [ ] Test update from previous version

### 2. Update Documentation

- [ ] Update any version-specific documentation
- [ ] Update installation guide if needed
- [ ] Announce in relevant channels

### 3. Monitor Issues

- [ ] Watch for installation issues
- [ ] Monitor GitHub issues for problems
- [ ] Be ready to create hotfix if needed

## Hotfix Process

For urgent fixes to a released version:

1. Create hotfix branch from tag:
   ```bash
   git checkout -b hotfix/1.1.1 v1.1.0
   ```

2. Make minimal necessary changes

3. Update version to patch release (1.1.1)

4. Follow normal release process

5. Merge hotfix back to main:
   ```bash
   git checkout main
   git merge hotfix/1.1.1
   ```

## Automation Scripts

### Release Helper Script

Create `scripts/prepare-release.sh`:

```bash
#!/bin/bash
# Release preparation helper

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.0"
    exit 1
fi

echo "Preparing release v$VERSION..."

# Update version in build script
sed -i "s/VERSION=\".*\"/VERSION=\"$VERSION\"/" build-distribution.sh

# Update README URLs
sed -i "s/ap-method-v[0-9.]*\.tar\.gz/ap-method-v$VERSION.tar.gz/g" README.md

# Build distribution
./build-distribution.sh

echo "Release preparation complete!"
echo "Next steps:"
echo "1. Review and commit changes"
echo "2. Create tag: git tag -a v$VERSION -m 'Release version $VERSION'"
echo "3. Push tag: git push origin v$VERSION"
echo "4. Create GitHub release"
```

## Version Compatibility

### Update Compatibility Matrix

| From Version | To Version | Update Method | Notes |
|--------------|------------|---------------|-------|
| < 1.0.0      | 1.x.x      | Manual reinstall | Pre-installer versions |
| 1.0.x        | 1.1.x      | ap-manager update | Automatic |
| 1.x.x        | 2.0.0      | See migration guide | Breaking changes |

### Minimum Version Requirements

- `ap-manager.sh update` requires v1.0.0 or later
- Earlier versions must manually install

## Security Considerations

### Release Integrity

1. **HTTPS Only**: All downloads via HTTPS
2. **GitHub Verification**: Releases hosted on GitHub
3. **Future**: Consider GPG signing releases

### API Rate Limits

GitHub API has rate limits:
- Unauthenticated: 60 requests/hour
- Authenticated: 5000 requests/hour

Consider adding auth token support for heavy users.

## Troubleshooting

### Common Release Issues

**Build fails**
- Check all files are committed
- Verify no uncommitted changes
- Ensure build script has correct permissions

**GitHub release upload fails**
- Check file size (< 2GB limit)
- Verify GitHub permissions
- Use CLI if web UI fails

**Update check fails**
- Verify tag format (must be vX.Y.Z)
- Check release is not marked as pre-release
- Ensure release has attached assets

## Future Enhancements

1. **GitHub Actions**: Automate release process
2. **Release Channels**: Separate stable/beta channels
3. **Signed Releases**: GPG signatures for verification
4. **Release Metrics**: Track download statistics
5. **Automated Testing**: Pre-release test suite

## References

- [Semantic Versioning](https://semver.org/)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [GitHub CLI](https://cli.github.com/)
- [Git Tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging)