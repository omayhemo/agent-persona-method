# AP Method Installation Guide

## Overview

The `Install-APM.ps1` script is a comprehensive installation tool that creates the complete AP (Agent Persona) Method directory structure and all associated files in any target directory.

## What is Included

The script creates:
- **93 core files** from the AP Method framework
- **5 additional scripts** that were deleted from git history but are essential for the framework
- Complete directory structure including:
  - `/agents/` - Main directory
  - `/agents/checklists/` - Quality checklists for each agent role (17 files)
  - `/agents/data/` - Knowledge base and technical preferences (2 files)
  - `/agents/personas/` - Agent persona definitions (10 files)
  - `/agents/scripts/` - Utility and automation scripts (7 files including restored)
  - `/agents/tasks/` - Reusable task definitions (28 files)
  - `/agents/templates/` - Document templates (19 files)
  - `/agents/voice/` - Voice notification scripts (10 files)
  - Configuration files and README documentation

## Usage

### Windows PowerShell

```powershell
# Install in current directory
.\Install-APM.ps1

# Install in specific directory
.\Install-APM.ps1 -TargetPath "C:\MyProject"

# Force overwrite existing files
.\Install-APM.ps1 -TargetPath "C:\MyProject" -Force
```

### Cross-Platform (PowerShell Core)

```bash
# Install PowerShell Core if not already installed
# Ubuntu/Debian: sudo apt-get install powershell
# macOS: brew install powershell
# Other: https://github.com/PowerShell/PowerShell

# Run the script
pwsh Install-APM.ps1 -TargetPath /path/to/project
```

## Post-Installation Steps

1. **Make scripts executable (Unix/Linux/macOS):**
   ```bash
   chmod +x agents/agentic-setup agents/scripts/*.sh agents/voice/*.sh
   ```

2. **Run the AP setup wizard:**
   ```bash
   ./agents/agentic-setup
   ```

3. **Launch AP Orchestrator:**
   - In your IDE, use the `/ap` command
   - Or use the `ap` alias after sourcing the environment

## Script Details

- **Size:** ~692 KB
- **Files Created:** 98 total (93 core + 5 restored)
- **Encoding:** UTF-8
- **Compatible with:** Windows PowerShell 5.1+ and PowerShell Core 7+

## Features

- **Safe Installation:** Checks for existing files and prompts before overwriting
- **Force Mode:** Use `-Force` to overwrite without prompting
- **Progress Tracking:** Shows creation of each file
- **Complete Package:** Includes all files needed for the AP Method
- **Cross-Platform:** Works on Windows, Linux, and macOS with PowerShell Core

## Troubleshooting

### "agents directory already exists" Error
- Use the `-Force` parameter to overwrite
- Or manually remove the existing `agents` directory

### Script Execution Policy (Windows)
If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### File Encoding Issues
All files are created with UTF-8 encoding. If you experience encoding issues, ensure your editor supports UTF-8.

## What's Next?

After installation:
1. Review the `/agents/README.md` for an overview of the AP Method
2. Run `agentic-setup` to configure your project
3. Start with the Analyst agent to create a project brief
4. Follow the AP workflow through each phase

## Support

For issues or questions:
- Review documentation in `/agents/` subdirectories
- Check task definitions in `/agents/tasks/`
- Consult the orchestrator configuration in `/agents/ide-ap-orchestrator.cfg.md`

The AP Method is designed to streamline AI-assisted software development through specialized agent personas and structured workflows.