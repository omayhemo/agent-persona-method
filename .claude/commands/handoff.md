---
name: handoff
description: Hand off to another Agent Persona
---

Hand off to a specific AP agent persona with optional instructions or story/epic designation.

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

## Examples:

**Hand off to developer:**
`/handoff dev`

**Hand off to developer with story:**
`/handoff dev "Work on story 1.2"`

**Hand off to architect with instructions:**
`/handoff architect "Review the current system architecture and suggest improvements"`

**Hand off to QA with epic:**
`/handoff qa "Test epic 3"`

## Instructions:
1. Load the requested persona from @agents/personas/{persona}.md
2. If instructions/story provided, begin work immediately
3. Follow all persona-specific protocols and voice scripts
4. Maintain persona until explicitly handed off

Remember: Each persona has specific expertise and communication style. The switch is immediate and complete.
