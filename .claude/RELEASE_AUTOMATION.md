# Release Automation Guide

This document explains how to use the `/release` command to automate the AP Mapping release process.

## Command Usage

The `/release` command automates the entire release process following the documented procedures in `project_documentation/release-process.md`.

### Basic Usage

```
/release 1.1.0
```

This will:
1. Validate the version format
2. Check git status is clean
3. Update version in all files
4. Build the distribution
5. Create git commits and tags
6. Generate release notes template
7. Provide commands for GitHub release

### Pre-release Versions

```
/release 1.2.0-beta.1 --beta
/release 2.0.0-rc.1 --rc
/release 1.3.0-alpha.1 --alpha
```

## Interactive Process

When you run `/release`, I will:

### 1. Pre-flight Checks
- Verify git working directory is clean
- Validate version format
- Check for existing tags
- Ensure build tools are available

### 2. Version Updates
```bash
# Automatically update:
- build-distribution.sh: VERSION="1.1.0"
- README.md: Download URLs
- installer/README.md: Version references
```

### 3. Build Distribution
```bash
./build-distribution.sh
# Creates: dist/ap-method-v1.1.0.tar.gz
```

### 4. Interactive Release Notes

I'll prompt you for:
- Release highlights
- New features (with descriptions)
- Bug fixes
- Improvements
- Breaking changes (if any)
- Migration notes (if needed)

### 5. Git Operations
```bash
# Commit all changes
git add .
git commit -m "Release v1.1.0"

# Create annotated tag
git tag -a v1.1.0 -m "Release version 1.1.0"
```

### 6. GitHub Release Preparation

I'll provide you with:
- Complete release notes
- GitHub CLI command
- Manual upload instructions
- Post-release checklist

## Example Session

```
You: /release 1.1.0

Claude: Starting AP Mapping release process for version 1.1.0...

✓ Git status is clean
✓ Version format is valid
✓ No existing tag for v1.1.0

Updating version references...
✓ Updated build-distribution.sh
✓ Updated README.md URLs
✓ Updated installer/README.md

Building distribution...
✓ Distribution built: dist/ap-method-v1.1.0.tar.gz (276K)

Now I need some information for the release notes:

1. What are the main highlights of this release? (1-2 sentences)
> [Your input]

2. List new features (or 'none'):
> [Your input for each feature]

3. List bug fixes (or 'none'):
> [Your input for each fix]

[... continues interactively ...]

✓ Created git commit
✓ Created tag v1.1.0
✓ Generated RELEASE_NOTES.md

Ready to push! Here are your next steps:

1. Push to GitHub:
   git push origin main
   git push origin v1.1.0

2. Create release:
   gh release create v1.1.0 \
     --title "AP Mapping v1.1.0" \
     --notes-file RELEASE_NOTES.md \
     dist/ap-method-v1.1.0.tar.gz

Would you like me to create a PR for the release? (y/n)
```

## Advanced Options

### Dry Run
See what would be done without making changes:
```
/release 1.1.0 --dry-run
```

### Force Update
Skip git status check (use with caution):
```
/release 1.1.0 --force
```

### Custom Release Notes
Use existing RELEASE_NOTES.md instead of interactive:
```
/release 1.1.0 --notes RELEASE_NOTES.md
```

## Integration with CI/CD

The release process can be partially automated with GitHub Actions:

1. Manual trigger creates release PR
2. Merging PR triggers:
   - Tag creation
   - GitHub release
   - Distribution upload

## Rollback

If something goes wrong:

```bash
# Delete local tag
git tag -d v1.1.0

# Delete remote tag
git push --delete origin v1.1.0

# Reset commits
git reset --hard HEAD~1

# Re-run release process
/release 1.1.0
```

## Best Practices

1. **Always test locally first**
   ```bash
   /release 1.1.0 --dry-run
   ```

2. **Keep release notes user-friendly**
   - Focus on what changed, not how
   - Include migration guides
   - Thank contributors

3. **Test the update path**
   - Install previous version
   - Run ap-manager.sh update
   - Verify it detects and installs new version

4. **Monitor after release**
   - Watch GitHub issues
   - Check download statistics
   - Be ready for hotfixes

## Troubleshooting

### "Working directory not clean"
```bash
git stash
/release 1.1.0
git stash pop  # After release
```

### "Tag already exists"
Either delete the tag or bump to next version

### "Build failed"
Check build-distribution.sh for errors

### "GitHub release failed"
- Check GitHub token: `gh auth status`
- Try manual upload via web UI
- Ensure file size < 2GB