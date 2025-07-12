# Release AP Mapping

Create a new release of the AP Mapping following the documented release process.

## Usage
```
/release <version> [--beta|--rc|--alpha]
```

## Examples
```
/release 1.1.0
/release 1.2.0-beta.1 --beta
/release 2.0.0-rc.1 --rc
```

## Process

When you run this command, I will:

1. **Validate Version Format**
   - Ensure semantic versioning (MAJOR.MINOR.PATCH)
   - Handle pre-release suffixes if specified

2. **Update Version References**
   - Update VERSION in `build-distribution.sh`
   - Update download URLs in `README.md`
   - Update version in `installer/README.md`

3. **Create/Update CHANGELOG**
   - Prompt for release highlights
   - Collect new features, bug fixes, improvements
   - Generate CHANGELOG entry

4. **Build Distribution**
   - Run `build-distribution.sh`
   - Verify build output in `dist/`

5. **Test Distribution**
   - Create test installation
   - Verify installer works
   - Test update path (if applicable)

6. **Prepare Git Release**
   - Commit all changes
   - Create annotated tag
   - Generate release notes

7. **Create GitHub Release**
   - Provide GitHub CLI command
   - Include release notes template
   - List manual steps for web UI

8. **Post-Release Checklist**
   - Verification steps
   - Update monitoring reminders

## Options

- `--beta`: Create beta pre-release
- `--rc`: Create release candidate
- `--alpha`: Create alpha pre-release
- `--dry-run`: Show what would be done without making changes

## Requirements

- Clean git working directory
- GitHub CLI installed (for automated release)
- Previous version tagged properly (for update testing)

## Notes

- Always test the update path before releasing
- Breaking changes require migration guide
- Release notes should be user-friendly
- Don't forget to push both commits and tags