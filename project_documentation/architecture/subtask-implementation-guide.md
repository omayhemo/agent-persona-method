# Subtask Implementation Guide

**Purpose:** Step-by-step guide for implementing Claude Code subtask integration  
**Architect:** AP Architect  
**Date:** 2025-01-11

## Quick Implementation Checklist

### Step 1: Create Directory Structure (5 minutes)
```bash
# From project root
mkdir -p agents/tasks/subtasks/{_templates,analysis,research,validation,generation,synthesis/{patterns,formats}}
mkdir -p agents/tasks/orchestration
```

### Step 2: Create Base Template (10 minutes)
Create `agents/tasks/subtasks/_templates/base-subtask.md`:
```markdown
# [Subtask Name]

## Metadata
- **Category**: [analysis|research|validation|generation]
- **Complexity**: [low|medium|high]
- **Est. Duration**: [time estimate]

## Instructions
[Clear, specific instructions for the subtask]

## Output Format
```yaml
status: success|partial|failure
summary: One-line summary of findings
findings:
  - category: [type]
    severity: [critical|high|medium|low]
    description: [clear description]
    recommendation: [actionable recommendation]
```
```

### Step 3: Create First Analysis Subtask (10 minutes)
Create `agents/tasks/subtasks/analysis/code-quality.md`:
```markdown
# Code Quality Analysis Subtask

## Metadata
- **Category**: analysis
- **Complexity**: medium
- **Est. Duration**: 3-5 minutes

## Instructions
Analyze the provided code/component for quality issues:

1. **Structure Analysis**
   - Check module organization and cohesion
   - Evaluate separation of concerns
   - Assess dependency relationships

2. **Best Practices Review**
   - Verify naming conventions
   - Check error handling patterns
   - Evaluate documentation coverage

3. **Maintainability Assessment**
   - Calculate cyclomatic complexity
   - Identify code duplication
   - Find refactoring opportunities

## Output Format
```yaml
status: success
summary: Code quality analysis complete with X critical, Y medium issues found
findings:
  - category: structure
    severity: high
    description: "Circular dependency between modules A and B"
    recommendation: "Extract shared functionality to new module C"
  - category: maintainability
    severity: medium
    description: "Function X has cyclomatic complexity of 15"
    recommendation: "Break down into smaller functions"
metrics:
  - name: "Total Issues"
    value: 12
  - name: "Critical Issues"
    value: 2
  - name: "Code Coverage"
    value: "67%"
```
```

### Step 4: Create Synthesis Pattern (10 minutes)
Create `agents/tasks/subtasks/synthesis/patterns/weighted.md`:
```markdown
# Weighted Synthesis Pattern

## When to Use
When subtask results have different importance levels or confidence scores.

## Synthesis Process

1. **Assign Weights**
   - Critical findings: Weight 3
   - High findings: Weight 2
   - Medium findings: Weight 1
   - Low findings: Weight 0.5

2. **Aggregate Findings**
   - Group by category
   - Calculate weighted severity
   - Identify consensus items

3. **Generate Summary**
   - List critical consensus items first
   - Include high-confidence findings
   - Note areas of disagreement

## Output Template
```markdown
## Synthesis Report

### Critical Findings (Consensus)
- [Finding with evidence from multiple subtasks]

### High Priority Items
- [Weighted high-severity findings]

### Recommendations
1. [Highest weighted recommendation]
2. [Next priority recommendation]

### Metrics Summary
- Total Issues: [sum]
- Critical Issues: [count]
- Consensus Rate: [percentage]
```
```

### Step 5: Update Architect Persona (5 minutes)
Add to `agents/personas/architect.md` after line 44:
```markdown
## Parallel Analysis Capability

When analyzing complex systems, I leverage Claude Code's Task tool for parallel execution:

### Supported Parallel Analyses
1. **System Architecture Review**
   - Database design analysis
   - API architecture assessment
   - Frontend structure evaluation
   - Security pattern review

2. **Code Quality Assessment**
   - Multi-module quality checks
   - Performance bottleneck identification
   - Dependency analysis

### Invocation Pattern
```
I'll perform a parallel analysis of the system architecture.

*Spawning subtasks:*
- Task("Analyze database design using the code quality template from agents/tasks/subtasks/analysis/code-quality.md")
- Task("Review API architecture for REST compliance and security patterns")
- Task("Assess frontend architecture for component reusability and state management")

*Synthesizing results using weighted pattern...*
```

### Best Practices
- Limit to 5-7 parallel subtasks per analysis
- Use consistent output formats for easy synthesis
- Always provide clear synthesis of findings
```

### Step 6: Create README (10 minutes)
Create `agents/tasks/subtasks/README.md`:
```markdown
# AP Mapping Subtask System

This directory contains templates for Claude Code Task tool integration.

## Quick Start

1. **Choose a Template**: Browse categories for appropriate subtask
2. **Invoke via Task Tool**: Use template instructions in Task() call
3. **Synthesize Results**: Apply patterns from synthesis/ directory

## Directory Structure

- `_templates/`: Base templates and examples
- `analysis/`: Code and system analysis subtasks
- `research/`: Information gathering subtasks
- `validation/`: Checking and verification subtasks
- `generation/`: Content creation subtasks
- `synthesis/`: Result combination patterns

## Usage Example

```
# In agent conversation:
I'll analyze your authentication system using parallel subtasks.

Task("Review authentication code quality using agents/tasks/subtasks/analysis/code-quality.md focusing on security patterns")
Task("Analyze authentication flow for OWASP compliance")
Task("Check session management for security vulnerabilities")

# After results return, synthesize findings...
```

## Best Practices

1. **Independence**: Each subtask must be self-contained
2. **Clarity**: Provide specific, unambiguous instructions
3. **Consistency**: Use standard output formats
4. **Efficiency**: Limit scope to maintain fast execution

## Creating New Subtasks

1. Copy base template from `_templates/base-subtask.md`
2. Customize for specific analysis type
3. Test with real scenarios
4. Document in appropriate category

## Synthesis Patterns

- **Unanimous**: All subtasks must agree
- **Majority**: Most common findings win
- **Weighted**: Priority-based aggregation
- **Expert**: Specialized opinion matters most
```

## Verification Steps

### 1. Directory Creation
```bash
# Verify structure created
ls -la agents/tasks/subtasks/
```

### 2. Template Validation
- Ensure base template has all required sections
- Check subtask follows standard format
- Verify synthesis pattern is complete

### 3. Integration Test
1. Open Architect persona
2. Attempt simple parallel analysis
3. Verify Task tool accepts templates
4. Check synthesis produces coherent output

## Next Actions

1. **Immediate**: Create directory structure and base files
2. **Today**: Test with Architect on real architecture review
3. **This Week**: Add 5 more subtask templates
4. **Next Week**: Expand to Developer and QA agents

## Success Criteria

- ✅ Directory structure exists
- ✅ Base template created
- ✅ First subtask template complete
- ✅ Synthesis pattern defined
- ✅ Architect persona updated
- ✅ README provides clear guidance

---

**Ready for Implementation!** Follow steps 1-6 to have working subtask system in ~45 minutes.