# Task Integration Technology Stack Correction

## Architectural Decision Record (ADR-001)

**Date**: 2025-01-11  
**Status**: Approved  
**Decision Maker**: Architect Agent

## Context

During the implementation of STORY-003 (Map Integration Points), we discovered that all technical implementation examples were written in TypeScript/JavaScript. This is fundamentally misaligned with the AP Mapping's native bash-based architecture.

## Decision

All task integration implementations MUST use the following technology stack:

### 1. Primary Technology: Bash Scripts

**Rationale**: The AP Mapping is a bash-based system that:
- Uses bash scripts for all core functionality (`agentic-setup`, voice scripts)
- Operates on markdown files as the primary data format
- Integrates with Claude Code through bash hooks
- Requires no runtime dependencies beyond standard Unix tools

**Use Cases**:
- Task extraction from markdown files
- Query and update operations on task data
- Integration hooks for Claude Code
- Persona workflow orchestration
- File system operations

### 2. Secondary Technology: Python (Optional)

**Rationale**: Python can be used for:
- Complex data analysis beyond bash capabilities
- Performance modeling and metrics
- Advanced pattern matching with regex
- Data visualization (if required)

**Use Cases**:
- Integration point classification algorithms
- Performance analysis tools
- Complex workflow analysis
- Statistical reporting

### 3. Prohibited Technologies

The following are explicitly NOT part of the AP Mapping tech stack:
- TypeScript/JavaScript
- Node.js/npm ecosystem
- React or any frontend frameworks
- Any compiled languages requiring build steps

## Implementation Guidelines

### Bash Script Standards

```bash
#!/bin/bash
# All AP Mapping scripts should follow this pattern

# Set strict error handling
set -euo pipefail

# Use consistent variable naming
readonly AP_ROOT="${AP_ROOT:-$HOME/.ap-method}"
readonly PROJECT_DOCS="${PROJECT_DOCS:-./project_documentation}"

# Function naming convention
function extract_tasks_from_story() {
    local story_file="$1"
    # Implementation using grep, sed, awk
}

# Error handling
function log_error() {
    echo "[ERROR] $1" >&2
}
```

### Python Integration (When Needed)

```python
#!/usr/bin/env python3
"""
AP Mapping integration analysis tool
Uses standard library only - no external dependencies
"""

import sys
import json
import re
from pathlib import Path

def analyze_integration_points(persona_config_path):
    """Analyze persona configuration for integration opportunities."""
    # Implementation using standard library only
    pass
```

## Migration Plan

1. **Immediate Actions**:
   - Stop all TypeScript implementation in STORY-003
   - Create bash-based reference implementations
   - Update story technical guidance

2. **Story Updates Required**:
   - STORY-003: Complete rewrite of technical implementation
   - STORY-007 through STORY-015: Review and update all code examples
   - All future stories: Use only bash/Python examples

3. **Documentation Updates**:
   - Update all technical templates
   - Create bash scripting guidelines
   - Document Python usage patterns

## Benefits

1. **Zero Dependencies**: No npm, node_modules, or build steps
2. **Native Integration**: Direct compatibility with existing AP infrastructure
3. **Simplicity**: Bash scripts are universally available
4. **Maintainability**: No framework lock-in or version conflicts
5. **Performance**: Direct file operations without runtime overhead

## Risks and Mitigation

**Risk**: Developers familiar with TypeScript may resist bash  
**Mitigation**: Provide comprehensive bash examples and patterns

**Risk**: Complex logic harder to implement in bash  
**Mitigation**: Use Python for complex algorithms while keeping interfaces in bash

## Approval

This architectural decision is effective immediately and applies to all AP Mapping development.

**Approved by**: Architect Agent  
**Date**: 2025-01-11  
**Review Date**: 2025-02-11