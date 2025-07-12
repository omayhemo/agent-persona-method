#!/bin/bash

# AP Mapping Documentation Generator
# Automatically generates comprehensive documentation for installations

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source logging framework
source "$SCRIPT_DIR/logging-framework.sh"

# Initialize logging
init_logging "DOC-GEN" 

# Documentation configuration
DOC_VERSION="1.0.0"
DOCS_DIR=""
PROJECT_ROOT=""
PROJECT_NAME=""
INSTALLATION_DATE=""
INSTALLER_VERSION=""

# Templates for documentation sections
README_TEMPLATE='# {{PROJECT_NAME}}

This project was set up using the AP Mapping installer.

## Installation Information

- **Installation Date**: {{INSTALLATION_DATE}}
- **Installer Version**: {{INSTALLER_VERSION}}
- **Project Root**: {{PROJECT_ROOT}}

## Quick Start

To get started with this project:

1. Review the configuration in `.claude/settings.json`
2. Check available commands in `.claude/commands/`
3. Run the AP orchestrator with `/ap` command

## Configuration

{{CONFIGURATION_SECTION}}

## Project Structure

{{STRUCTURE_SECTION}}

## Available Commands

{{COMMANDS_SECTION}}

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

## Additional Resources

- [Configuration Reference](./CONFIG_REFERENCE.md)
- [API Documentation](./API_REFERENCE.md)
- [Change Log](./CHANGELOG.md)

---
*Documentation generated on {{GENERATION_DATE}} by AP Mapping Documentation Generator v{{DOC_VERSION}}*'

CONFIG_REFERENCE_TEMPLATE='# Configuration Reference

This document provides detailed information about all configuration options.

## Environment Variables

{{ENV_VARS_SECTION}}

## Settings File

The main settings file is located at `.claude/settings.json`.

### Settings Structure

{{SETTINGS_STRUCTURE}}

### Variable Descriptions

{{VARIABLE_DESCRIPTIONS}}

## Variable Types

{{VARIABLE_TYPES}}

## Examples

{{CONFIG_EXAMPLES}}

---
*Generated on {{GENERATION_DATE}}*'

TROUBLESHOOTING_TEMPLATE='# Troubleshooting Guide

This guide helps resolve common issues with the AP Mapping installation.

## Common Issues

{{COMMON_ISSUES}}

## Debug Procedures

### Enable Debug Mode

```bash
LOG_LEVEL=DEBUG ./install-enhanced.sh --debug
```

### Check Logs

Logs are stored in:
- Installation logs: `./logs/`
- Debug reports: `./reports/`

## Error Messages

{{ERROR_REFERENCE}}

## Getting Help

If you cannot resolve an issue:

1. Check the debug log: `./logs/installer-debug.log`
2. Run integrity check: `./install-enhanced.sh --verify`
3. Review the installation report: `./reports/latest-report.txt`

## Contact Support

{{SUPPORT_INFO}}

---
*Generated on {{GENERATION_DATE}}*'

# Initialize documentation generator
init_doc_generator() {
    local project_root="${1:-$PWD}"
    
    log_info "Initializing documentation generator" "INIT"
    start_timer "doc_generator_init"
    
    PROJECT_ROOT="$project_root"
    DOCS_DIR="$PROJECT_ROOT/docs"
    
    # Load project information
    if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
        PROJECT_NAME=$(jq -r '.PROJECT_NAME // "Unknown Project"' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null || echo "Unknown Project")
        log_debug "Loaded project name: $PROJECT_NAME" "INIT"
    fi
    
    # Get installation information
    INSTALLATION_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    INSTALLER_VERSION="${INSTALLER_VERSION:-unknown}"
    
    # Create docs directory if needed
    if [ ! -d "$DOCS_DIR" ]; then
        mkdir -p "$DOCS_DIR"
        log_info "Created documentation directory: $DOCS_DIR" "INIT"
    fi
    
    stop_timer "doc_generator_init"
    return 0
}

# Generate main README
generate_readme() {
    local output_file="${1:-$PROJECT_ROOT/README.md}"
    
    log_info "Generating README.md" "README"
    start_timer "generate_readme"
    
    # Backup existing README if present
    if [ -f "$output_file" ] && [ ! -f "$output_file.backup" ]; then
        cp "$output_file" "$output_file.backup"
        log_debug "Backed up existing README" "README"
    fi
    
    # Generate configuration section
    local config_section=$(generate_config_summary)
    
    # Generate structure section
    local structure_section=$(generate_project_structure)
    
    # Generate commands section
    local commands_section=$(generate_commands_list)
    
    # Create README from template
    local readme_content="$README_TEMPLATE"
    readme_content="${readme_content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    readme_content="${readme_content//\{\{INSTALLATION_DATE\}\}/$INSTALLATION_DATE}"
    readme_content="${readme_content//\{\{INSTALLER_VERSION\}\}/$INSTALLER_VERSION}"
    readme_content="${readme_content//\{\{PROJECT_ROOT\}\}/$PROJECT_ROOT}"
    readme_content="${readme_content//\{\{CONFIGURATION_SECTION\}\}/$config_section}"
    readme_content="${readme_content//\{\{STRUCTURE_SECTION\}\}/$structure_section}"
    readme_content="${readme_content//\{\{COMMANDS_SECTION\}\}/$commands_section}"
    readme_content="${readme_content//\{\{GENERATION_DATE\}\}/$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    readme_content="${readme_content//\{\{DOC_VERSION\}\}/$DOC_VERSION}"
    
    # Write README
    echo "$readme_content" > "$output_file"
    
    log_info "README.md generated successfully" "README"
    stop_timer "generate_readme"
    return 0
}

# Generate configuration summary
generate_config_summary() {
    log_trace "Generating configuration summary" "CONFIG"
    
    local summary="### Key Configuration Values

"
    
    # Read settings if available
    if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
        summary+='```json
'
        summary+=$(jq '.' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null || echo "{}")
        summary+='
```'
    else
        summary+="*No configuration file found*"
    fi
    
    echo "$summary"
}

# Generate project structure
generate_project_structure() {
    log_trace "Generating project structure" "STRUCTURE"
    
    local structure='```
'
    
    # Generate tree view (limited depth)
    if command -v tree >/dev/null 2>&1; then
        structure+=$(cd "$PROJECT_ROOT" && tree -L 3 -I 'node_modules|__pycache__|*.pyc|.git' 2>/dev/null || find . -type d -name .git -prune -o -type d -print | head -20)
    else
        structure+=$(cd "$PROJECT_ROOT" && find . -type d -name .git -prune -o -type d -print | head -20 | sort)
    fi
    
    structure+='
```'
    
    echo "$structure"
}

# Generate commands list
generate_commands_list() {
    log_trace "Generating commands list" "COMMANDS"
    
    local commands=""
    
    # Check for command files
    if [ -d "$PROJECT_ROOT/.claude/commands" ]; then
        commands="The following commands are available:

"
        for cmd_file in "$PROJECT_ROOT/.claude/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                local cmd_name=$(basename "$cmd_file" .md)
                local cmd_desc=$(head -n 3 "$cmd_file" | grep -E "^#|^Description:" | head -1 | sed 's/^#\s*//' | sed 's/^Description:\s*//')
                commands+="- **/$cmd_name**: ${cmd_desc:-No description available}
"
            fi
        done
    else
        commands="*No custom commands found*"
    fi
    
    echo "$commands"
}

# Generate configuration reference
generate_config_reference() {
    local output_file="${1:-$DOCS_DIR/CONFIG_REFERENCE.md}"
    
    log_info "Generating configuration reference" "CONFIG-REF"
    start_timer "generate_config_reference"
    
    # Generate sections
    local env_vars=$(generate_env_vars_docs)
    local settings_structure=$(generate_settings_structure)
    local variable_descriptions=$(generate_variable_descriptions)
    local variable_types=$(generate_variable_types)
    local config_examples=$(generate_config_examples)
    
    # Create document from template
    local config_ref="$CONFIG_REFERENCE_TEMPLATE"
    config_ref="${config_ref//\{\{ENV_VARS_SECTION\}\}/$env_vars}"
    config_ref="${config_ref//\{\{SETTINGS_STRUCTURE\}\}/$settings_structure}"
    config_ref="${config_ref//\{\{VARIABLE_DESCRIPTIONS\}\}/$variable_descriptions}"
    config_ref="${config_ref//\{\{VARIABLE_TYPES\}\}/$variable_types}"
    config_ref="${config_ref//\{\{CONFIG_EXAMPLES\}\}/$config_examples}"
    config_ref="${config_ref//\{\{GENERATION_DATE\}\}/$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    
    # Write file
    echo "$config_ref" > "$output_file"
    
    log_info "Configuration reference generated" "CONFIG-REF"
    stop_timer "generate_config_reference"
    return 0
}

# Generate environment variables documentation
generate_env_vars_docs() {
    log_trace "Generating environment variables documentation" "ENV-VARS"
    
    local docs="### Installation Environment Variables

These variables can be set when running the installer:

| Variable | Description | Default |
|----------|-------------|---------|
| LOG_LEVEL | Logging verbosity (TRACE, DEBUG, INFO, WARN, ERROR) | INFO |
| PERF_TRACKING | Enable performance tracking | true |
| DEBUG_MODE | Enable debug mode | false |
| REPORT_FORMAT | Report output format (text, json, html) | text |

### Runtime Environment Variables

These variables are set by the installation:

"
    
    # Read from variables.json if available
    if [ -f "$SCRIPT_DIR/variables.json" ]; then
        docs+="| Variable | Type | Description |
|----------|------|-------------|
"
        while IFS= read -r line; do
            local var_name=$(echo "$line" | jq -r '.key')
            local var_type=$(echo "$line" | jq -r '.value.type')
            local var_desc=$(echo "$line" | jq -r '.value.description // "No description"')
            docs+="| $var_name | $var_type | $var_desc |
"
        done < <(jq -c '.variables | to_entries[]' "$SCRIPT_DIR/variables.json" 2>/dev/null)
    fi
    
    echo "$docs"
}

# Generate settings structure documentation
generate_settings_structure() {
    log_trace "Generating settings structure documentation" "SETTINGS"
    
    local structure='```json
{
  "PROJECT_NAME": "Your project name",
  "PROJECT_ROOT": "Project root directory",
  "AP_ROOT": "AP Mapping root directory",
  "CLAUDE_DIR": "Claude configuration directory",
  "PROJECT_DOCS": "Project documentation directory",
  "NOTES_TYPE": "Notes storage type (obsidian or local)"
}
```'
    
    echo "$structure"
}

# Generate variable descriptions
generate_variable_descriptions() {
    log_trace "Generating variable descriptions" "VAR-DESC"
    
    local descriptions=""
    
    if [ -f "$SCRIPT_DIR/variables.json" ]; then
        while IFS= read -r line; do
            local var_name=$(echo "$line" | jq -r '.key')
            local var_desc=$(echo "$line" | jq -r '.value.description // "No description"')
            local var_default=$(echo "$line" | jq -r '.value.default // "None"')
            local var_required=$(echo "$line" | jq -r '.value.required // false')
            
            descriptions+="#### $var_name

**Description**: $var_desc  
**Default**: \`$var_default\`  
**Required**: $var_required

"
        done < <(jq -c '.variables | to_entries[]' "$SCRIPT_DIR/variables.json" 2>/dev/null)
    else
        descriptions="*Variable configuration file not found*"
    fi
    
    echo "$descriptions"
}

# Generate variable types documentation
generate_variable_types() {
    log_trace "Generating variable types documentation" "VAR-TYPES"
    
    local types="The following variable types are supported:

- **string**: Text values
- **path**: File system paths (validated for existence)
- **enum**: Predefined set of values
- **boolean**: true/false values
- **number**: Numeric values

### Type Validation

Each type has specific validation rules:

| Type | Validation |
|------|------------|
| string | Non-empty, trimmed |
| path | Must exist or be creatable |
| enum | Must match allowed values |
| boolean | true/false only |
| number | Valid integer or float |"
    
    echo "$types"
}

# Generate configuration examples
generate_config_examples() {
    log_trace "Generating configuration examples" "EXAMPLES"
    
    local examples="### Basic Configuration

\`\`\`bash
# Run with defaults
./install-enhanced.sh /path/to/project --defaults

# Custom configuration
export PROJECT_NAME=\"My Custom Project\"
export NOTES_TYPE=\"obsidian\"
./install-enhanced.sh /path/to/project
\`\`\`

### Advanced Configuration

\`\`\`bash
# Import previous configuration
./install-enhanced.sh /path/to/project --import previous-config.sh

# Export configuration for reuse
./install-enhanced.sh /path/to/project --export my-config.sh

# Debug mode with custom log level
LOG_LEVEL=TRACE ./install-enhanced.sh /path/to/project --debug
\`\`\`"
    
    echo "$examples"
}

# Generate troubleshooting guide
generate_troubleshooting_guide() {
    local output_file="${1:-$DOCS_DIR/TROUBLESHOOTING.md}"
    
    log_info "Generating troubleshooting guide" "TROUBLESHOOT"
    start_timer "generate_troubleshooting"
    
    # Generate sections
    local common_issues=$(generate_common_issues)
    local error_reference=$(generate_error_reference)
    local support_info=$(generate_support_info)
    
    # Create document from template
    local troubleshooting="$TROUBLESHOOTING_TEMPLATE"
    troubleshooting="${troubleshooting//\{\{COMMON_ISSUES\}\}/$common_issues}"
    troubleshooting="${troubleshooting//\{\{ERROR_REFERENCE\}\}/$error_reference}"
    troubleshooting="${troubleshooting//\{\{SUPPORT_INFO\}\}/$support_info}"
    troubleshooting="${troubleshooting//\{\{GENERATION_DATE\}\}/$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    
    # Write file
    echo "$troubleshooting" > "$output_file"
    
    log_info "Troubleshooting guide generated" "TROUBLESHOOT"
    stop_timer "generate_troubleshooting"
    return 0
}

# Generate common issues section
generate_common_issues() {
    log_trace "Generating common issues" "ISSUES"
    
    local issues="### Permission Denied

**Problem**: Installation fails with permission errors.

**Solution**:
\`\`\`bash
# Check directory permissions
ls -la /path/to/project

# Fix permissions
chmod 755 /path/to/project
\`\`\`

### Missing Dependencies

**Problem**: Required commands not found.

**Solution**:
\`\`\`bash
# Install missing dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install python3 git jq

# macOS with Homebrew
brew install python3 git jq
\`\`\`

### Variable Configuration Fails

**Problem**: Variable manager reports validation errors.

**Solution**:
1. Check variables.json for syntax errors
2. Ensure all required variables are set
3. Verify path variables point to valid locations

### Template Processing Errors

**Problem**: Template files not processed correctly.

**Solution**:
\`\`\`bash
# Run with debug mode
./install-enhanced.sh --debug

# Check template syntax
./template-processor-bash.sh --validate template.file
\`\`\`"
    
    echo "$issues"
}

# Generate error reference
generate_error_reference() {
    log_trace "Generating error reference" "ERRORS"
    
    local errors="### Error Codes

| Code | Message | Solution |
|------|---------|----------|
| 1 | Environment check failed | Install missing dependencies |
| 2 | Variable validation failed | Check variable configuration |
| 3 | Template processing failed | Verify template syntax |
| 4 | Backup creation failed | Check disk space and permissions |
| 5 | Installation failed | Review logs for details |

### Log Messages

#### ERROR Level
- **\"Missing required command\"**: Install the missing dependency
- **\"Invalid variable type\"**: Check variables.json configuration
- **\"Permission denied\"**: Fix file/directory permissions

#### WARN Level
- **\"Optional feature not available\"**: Install optional dependencies
- **\"Backup directory exists\"**: Previous installation detected
- **\"Configuration mismatch\"**: Review settings.json"
    
    echo "$errors"
}

# Generate support information
generate_support_info() {
    log_trace "Generating support information" "SUPPORT"
    
    local support="For additional help:

1. **Documentation**: Check the [project documentation]($PROJECT_ROOT/docs/)
2. **Logs**: Review detailed logs in \`$PROJECT_ROOT/logs/\`
3. **Reports**: Check installation reports in \`$PROJECT_ROOT/reports/\`
4. **Debug Mode**: Run with \`--debug\` flag for verbose output

### Reporting Issues

When reporting issues, please include:
- Installation log file
- Error messages
- System information (OS, versions)
- Steps to reproduce"
    
    echo "$support"
}

# Generate API reference
generate_api_reference() {
    local output_file="${1:-$DOCS_DIR/API_REFERENCE.md}"
    
    log_info "Generating API reference" "API-REF"
    start_timer "generate_api_reference"
    
    local api_content="# API Reference

This document provides detailed information about available functions and scripts.

## Core Scripts

### install-enhanced.sh

Main installation script with comprehensive features.

#### Usage
\`\`\`bash
./install-enhanced.sh [PROJECT_ROOT] [OPTIONS]
\`\`\`

#### Options
| Option | Description |
|--------|-------------|
| --debug | Enable debug mode |
| --trace | Enable trace logging |
| --quiet | Suppress console output |
| --defaults | Use default values |
| --verify | Run verification only |

### documentation-generator.sh

Generates project documentation automatically.

#### Functions

##### init_doc_generator()
\`\`\`bash
init_doc_generator \"\$PROJECT_ROOT\"
\`\`\`
Initialize the documentation generator with project root.

##### generate_readme()
\`\`\`bash
generate_readme \"\$OUTPUT_FILE\"
\`\`\`
Generate or update README.md file.

##### generate_config_reference()
\`\`\`bash
generate_config_reference \"\$OUTPUT_FILE\"
\`\`\`
Generate configuration reference documentation.

### variable-manager.sh

Manages project variables and configuration.

#### Functions

##### validate_variables()
Validates all configured variables against their types.

##### export_variables()
Exports variables to a reusable configuration file.

## Integration Examples

### Generate All Documentation
\`\`\`bash
#!/bin/bash
source documentation-generator.sh

init_doc_generator \"\$PROJECT_ROOT\"
generate_readme
generate_config_reference
generate_troubleshooting_guide
\`\`\`

### Custom Documentation
\`\`\`bash
# Generate only specific sections
generate_config_summary > custom-config.md
generate_commands_list > available-commands.md
\`\`\`

---
*Generated on $(date -u +%Y-%m-%dT%H:%M:%SZ)*"
    
    echo "$api_content" > "$output_file"
    
    log_info "API reference generated" "API-REF"
    stop_timer "generate_api_reference"
    return 0
}

# Generate changelog
generate_changelog() {
    local output_file="${1:-$DOCS_DIR/CHANGELOG.md}"
    
    log_info "Generating changelog" "CHANGELOG"
    start_timer "generate_changelog"
    
    local changelog="# Changelog

All notable changes to this installation will be documented in this file.

## [Current] - $(date -u +%Y-%m-%d)

### Added
- Initial installation using AP Mapping installer v$INSTALLER_VERSION
- Project configuration in \`.claude/settings.json\`
- Documentation generated automatically

### Configuration
- Project Name: $PROJECT_NAME
- Installation Date: $INSTALLATION_DATE
- Installer Version: $INSTALLER_VERSION

### Components Installed
"
    
    # List installed components
    if [ -d "$PROJECT_ROOT/.claude" ]; then
        changelog+="- Claude configuration directory
"
    fi
    
    if [ -d "$PROJECT_ROOT/docs" ]; then
        changelog+="- Documentation directory
"
    fi
    
    if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
        changelog+="- Settings configuration
"
    fi
    
    changelog+="
---
*This changelog is automatically maintained by the AP Mapping installer*"
    
    echo "$changelog" > "$output_file"
    
    log_info "Changelog generated" "CHANGELOG"
    stop_timer "generate_changelog"
    return 0
}

# Update all documentation
update_all_documentation() {
    local project_root="${1:-$PROJECT_ROOT}"
    
    log_info "Updating all documentation" "UPDATE-ALL"
    start_timer "update_all_docs"
    
    # Initialize
    init_doc_generator "$project_root"
    
    # Generate all documents
    local errors=0
    
    generate_readme || ((errors++))
    generate_config_reference || ((errors++))
    generate_troubleshooting_guide || ((errors++))
    generate_api_reference || ((errors++))
    generate_changelog || ((errors++))
    
    stop_timer "update_all_docs"
    
    if [ $errors -gt 0 ]; then
        log_error "Documentation update completed with $errors errors" "UPDATE-ALL"
        return 1
    else
        log_info "All documentation updated successfully" "UPDATE-ALL"
        return 0
    fi
}

# Verify documentation
verify_documentation() {
    local project_root="${1:-$PROJECT_ROOT}"
    
    log_info "Verifying documentation" "VERIFY"
    start_timer "verify_docs"
    
    local missing=0
    local outdated=0
    
    # Check required documents
    local required_docs=(
        "README.md"
        "docs/CONFIG_REFERENCE.md"
        "docs/TROUBLESHOOTING.md"
        "docs/API_REFERENCE.md"
        "docs/CHANGELOG.md"
    )
    
    for doc in "${required_docs[@]}"; do
        if [ ! -f "$project_root/$doc" ]; then
            log_warn "Missing documentation: $doc" "VERIFY"
            ((missing++))
        else
            # Check if outdated (older than settings.json)
            if [ -f "$project_root/.claude/settings.json" ]; then
                if [ "$project_root/$doc" -ot "$project_root/.claude/settings.json" ]; then
                    log_warn "Outdated documentation: $doc" "VERIFY"
                    ((outdated++))
                fi
            fi
        fi
    done
    
    stop_timer "verify_docs"
    
    log_info "Documentation verification complete: $missing missing, $outdated outdated" "VERIFY"
    
    if [ $missing -gt 0 ] || [ $outdated -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Export documentation generator functions
export -f init_doc_generator
export -f generate_readme
export -f generate_config_reference
export -f generate_troubleshooting_guide
export -f generate_api_reference
export -f generate_changelog
export -f update_all_documentation
export -f verify_documentation

# Main execution (if run directly)
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Parse command line arguments
    PROJECT_ROOT="${1:-$PWD}"
    COMMAND="${2:-update}"
    
    case "$COMMAND" in
        update)
            update_all_documentation "$PROJECT_ROOT"
            ;;
        verify)
            verify_documentation "$PROJECT_ROOT"
            ;;
        readme)
            init_doc_generator "$PROJECT_ROOT"
            generate_readme
            ;;
        config)
            init_doc_generator "$PROJECT_ROOT"
            generate_config_reference
            ;;
        troubleshoot)
            init_doc_generator "$PROJECT_ROOT"
            generate_troubleshooting_guide
            ;;
        api)
            init_doc_generator "$PROJECT_ROOT"
            generate_api_reference
            ;;
        changelog)
            init_doc_generator "$PROJECT_ROOT"
            generate_changelog
            ;;
        *)
            echo "Usage: $0 [PROJECT_ROOT] [COMMAND]"
            echo "Commands: update, verify, readme, config, troubleshoot, api, changelog"
            exit 1
            ;;
    esac
fi