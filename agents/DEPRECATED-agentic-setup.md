# DEPRECATED: agentic-setup

**This script has been deprecated and replaced by the comprehensive installer system.**

## Migration Guide

If you were using `agents/agentic-setup`, please use the new installer instead:

### From Distribution Package:
```bash
curl -L https://github.com/omayhemo/agent-persona-method/raw/main/dist/ap-method-v1.0.0.tar.gz | tar -xz
./installer/install.sh
```

### From Source:
```bash
git clone https://github.com/omayhemo/agent-persona-method.git
cd agent-persona-method
./build-distribution.sh
cd dist && tar -xzf ap-method-v*.tar.gz
./installer/install.sh
```

## Why the Change?

The new installer provides:
- Comprehensive error handling and recovery
- Version management and update capabilities
- Backup and rollback functionality
- Better logging and debugging
- Integrity verification
- Clean uninstall process
- Preserved installer for future management

The old `agentic-setup` script is kept for reference but should not be used for new installations.

## For Existing Installations

If you have an existing installation created with `agentic-setup`:
1. Your installation will continue to work
2. You can manually install ap-manager.sh from the latest release
3. Or reinstall using the new installer (backup your work first)