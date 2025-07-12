---
name: handoff
description: Hand off to another Agent Persona
---

# AGENT HANDOFF PROTOCOL

## 🚀 PARALLEL CONTEXT TRANSFER (MANDATORY)

**CRITICAL**: When handing off to another agent, you MUST execute parallel context transfer:

```
I'm preparing to hand off to the [Target Agent]. Let me transfer context and initialize the new agent in parallel.

*Executing parallel handoff tasks:*
[Use Task tool - ALL in single function_calls block]
- Task 1: Create handoff summary of current work and decisions
- Task 2: Load target persona configuration from @agents/personas/{persona}.md
- Task 3: Check for work artifacts relevant to target persona
- Task 4: Prepare transition notes for seamless continuation
- Task 5: Load target persona's required templates and checklists
```

### Handoff Task Prompts:
1. "Summarize current work status, key decisions made, and next steps for the incoming agent"
2. "Load the full persona configuration including initialization protocol and capabilities"
3. "Identify and load any work artifacts (stories, designs, code) relevant to the target persona"
4. "Create transition notes highlighting critical context the new agent needs"
5. "Load the target persona's primary templates and checklists for immediate use"

### Post-Handoff Protocol:
After ALL tasks complete:
1. Present handoff summary to user
2. Activate target persona with their initialization protocol
3. Target persona executes their own parallel initialization
4. Confirm: "✓ Handoff complete to [Target Agent] with full context transfer"

## Usage:
`/handoff <persona> [instructions/story]`

## Available Personas:
- `ap` or `orchestrator` - AP Orchestrator (default)
- `dev` or `developer` - Developer agent
- `architect` - System architect
- `design` or `design-architect` - Design/UI architect
- `analyst` - Business/Requirements analyst
- `qa` - Quality assurance
- `pm` - Product manager
- `po` - Product owner
- `sm` - Scrum master

## Direct Activation Alternative:
Each persona now has its own activation command with full initialization:
- `/ap` - AP Orchestrator
- `/analyst` - Analyst
- `/pm` - Product Manager
- `/architect` - System Architect
- `/design-architect` - Design Architect
- `/po` - Product Owner
- `/sm` - Scrum Master
- `/dev` - Developer
- `/qa` - Quality Assurance

Use direct commands for fresh activation with full initialization protocol.

## Handoff Process:

### Phase 1: Context Preservation
The current agent must:
1. Summarize work completed
2. Document key decisions
3. Identify next steps
4. Note any blockers or concerns
5. Package relevant artifacts

### Phase 2: Parallel Transfer
Execute all handoff tasks simultaneously for efficient transition

### Phase 3: Target Activation
The target agent will:
1. Receive the handoff context
2. Execute their own initialization protocol
3. Acknowledge the handoff
4. Continue work based on context + instructions

## Examples:

**Hand off to developer with context:**
`/handoff dev`
→ Current agent summarizes, developer receives context and initializes

**Hand off to developer with specific story:**
`/handoff dev "Work on story 1.2"`
→ Context transfer + specific story focus

**Hand off to architect for review:**
`/handoff architect "Review the current system architecture and suggest improvements"`
→ Context transfer + review directive

**Hand off to QA with epic:**
`/handoff qa "Test epic 3"`
→ Context transfer + epic testing focus

## Best Practices:

1. **Complete Current Work**: Finish or reach a logical stopping point
2. **Document Decisions**: Ensure key decisions are captured
3. **Identify Next Steps**: Be clear about what needs to happen next
4. **Transfer Artifacts**: Ensure relevant files/documents are noted
5. **Clear Instructions**: If providing instructions, be specific

## Context Transfer Format:

The handoff summary should include:
```markdown
## Handoff Summary from [Current Agent] to [Target Agent]

### Work Completed:
- [List of completed items]

### Key Decisions:
- [Important decisions made]

### Current Status:
- [Where things stand]

### Next Steps:
- [What needs to be done]

### Relevant Artifacts:
- [Files, documents, or resources]

### Special Considerations:
- [Any warnings, blockers, or important context]
```

Remember: The goal is seamless continuation of work with full context awareness. The parallel handoff ensures no context is lost and the new agent can begin work immediately with complete understanding.