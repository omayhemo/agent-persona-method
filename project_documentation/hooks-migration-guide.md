# AP Method Hooks Migration Guide

## Overview

This guide helps teams transition from manual AP Method processes to the automated hooks system. It maps traditional manual steps to their automated equivalents and provides guidance for adapting workflows.

## What's Changed

### From Manual to Automated

The Claude Code hooks system now automates many routine tasks that previously required manual attention:

| Manual Process | Automated Hook | When It Runs |
|----------------|----------------|--------------|
| Check session notes | capture-session-activity.sh | Every file operation |
| Create session notes | capture-session-activity.sh | Automatically on file changes |
| Validate prerequisites | task-pre-hook.sh | Before task execution |
| Run checklists | checklist-validator.sh | After document creation |
| Track progress | task-post-hook.sh | After task completion |
| Create handoffs | task-post-hook.sh | When task completes |
| Validate documents | document-validator.sh | On document save |
| Check story sequence | story-validator.sh | During story creation |

## Task-by-Task Migration

### 1. Checklist Validation (checklist-run-task.md)

**Before (Manual):**
```markdown
1. Check checklist-mappings for available checklists
2. Ask user which checklist to use
3. Work through each section manually
4. Document pass/fail status
5. Create validation report
```

**After (Automated):**
```markdown
1. Hooks automatically detect document type
2. Appropriate checklist runs automatically
3. Validation report generated instantly
4. Focus on interpreting results and strategic decisions
```

**What You Do Now:**
- Review automated reports
- Make strategic quality decisions
- Guide remediation priorities
- Communicate findings to stakeholders

### 2. Story Creation (create-next-story-task.md)

**Before (Manual):**
```markdown
1. Review stories/ directory for highest number
2. Check if previous story is "Done"
3. Verify prerequisites from epic
4. Present alerts for incomplete stories
5. Manually validate story format
```

**After (Automated):**
```markdown
1. Hooks check sequence automatically
2. Prerequisites validated in background
3. Warnings appear if issues detected
4. Format validation runs on save
5. Handoff document created automatically
```

**What You Do Now:**
- Focus on story content and clarity
- Address any warnings from hooks
- Ensure acceptance criteria are comprehensive
- Review automated validation report

### 3. Requirements Validation (validate-requirements.md)

**Before (Manual):**
```markdown
1. Check each requirement for completeness
2. Verify testability manually
3. Cross-check consistency
4. Document all findings
5. Create validation report
```

**After (Automated):**
```markdown
1. Hooks validate document structure
2. Format compliance checked automatically
3. Cross-document consistency verified
4. Reports generated automatically
```

**What You Do Now:**
- Strategic quality assessment
- Business alignment validation
- Risk identification
- Stakeholder communication

### 4. PRD Creation (create-prd.md)

**Before (Manual):**
```markdown
1. Work through template sections
2. Run PM checklist manually
3. Document completion status
4. Address deficiencies iteratively
```

**After (Automated):**
```markdown
1. Section validation runs as you write
2. PM checklist executes automatically
3. Quality reports generated
4. Next agent recommended
```

**What You Do Now:**
- Focus on strategic product definition
- Address validation warnings
- Ensure business value clarity
- Review automated recommendations

### 5. Architecture Creation (create-architecture.md)

**Before (Manual):**
```markdown
1. Create architecture document
2. Run architect checklist item by item
3. Document findings
4. Make updates based on gaps
```

**After (Automated):**
```markdown
1. Prerequisites checked automatically
2. Architect checklist runs on completion
3. Validation report generated
4. Handoff prepared automatically
```

**What You Do Now:**
- Focus on architectural decisions
- Address complex trade-offs
- Review automated findings
- Ensure technical soundness

## Working with Automated Reports

### Report Locations

All automated reports are saved to predictable locations:

```
$AP_ROOT/hooks/
├── task-hooks/
│   ├── checklist-report-*.md      # Checklist validation reports
│   ├── story-validation-*.md      # Story validation reports
│   ├── document-validation-*.md   # Document validation reports
│   ├── handoff-*.md              # Agent handoff documents
│   └── workspaces/               # Task-specific workspaces
├── session-activity.log          # All file operations
├── agent-init.log               # Agent initialization logs
└── quality.log                  # Quality check results
```

### Understanding Hook Output

Automated reports follow consistent formats:

```markdown
# Validation Report
**Status**: PASS/FAIL/WARNING
**Completion Rate**: XX%

## Summary
- Total items: X
- Passed: Y
- Failed: Z

## Detailed Findings
- Specific issues found
- Recommendations
- Next steps
```

## Best Practices for the New Workflow

### 1. Trust the Automation

- Let hooks handle routine validation
- Focus your expertise on strategic decisions
- Don't duplicate automated checks manually

### 2. Respond to Warnings

- Take hook warnings seriously
- Address issues before proceeding
- Use manual override sparingly

### 3. Leverage Reports

- Review all generated reports
- Use them for stakeholder communication
- Track trends over time

### 4. Focus on Value-Add

Your role has shifted from mechanical validation to strategic guidance:

**Less Time On:**
- Checking prerequisites
- Running checklists
- Tracking progress
- Creating handoffs
- Validating formats

**More Time On:**
- Strategic thinking
- Quality decisions
- Stakeholder alignment
- Complex problem solving
- Process improvement

## Troubleshooting

### If Hooks Aren't Running

1. Check `.claude/settings.json` has hook configurations
2. Verify hook scripts have execute permissions
3. Check hook logs for errors
4. Ensure `jq` is installed

### If Reports Aren't Generated

1. Check task completion status
2. Look in workspace directories
3. Review hook logs for errors
4. Verify write permissions

### Manual Fallback

If you need to run validations manually:

```bash
# Run specific validator directly
$AP_ROOT/hooks/task-hooks/story-validator.sh <story-file>
$AP_ROOT/hooks/task-hooks/checklist-validator.sh <document> <checklist>
$AP_ROOT/hooks/task-hooks/document-validator.sh <document>
```

## Migration Checklist

Use this checklist to ensure smooth transition:

- [ ] Review updated task documentation
- [ ] Understand what's automated vs manual
- [ ] Locate report directories
- [ ] Practice interpreting automated reports
- [ ] Adjust workflows to leverage automation
- [ ] Train team on new processes
- [ ] Document any custom adaptations

## Summary

The hooks system transforms the AP Method from a manual process to an intelligent, automated workflow. By understanding what's automated and focusing on strategic value-add, teams can deliver higher quality results more efficiently.

Remember: Automation handles the routine. You provide the expertise.