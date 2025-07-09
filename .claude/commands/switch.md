---
name: switch
description: Compact session and switch to another Agent Persona
---

Compact the current session and switch to a specific AP agent persona with optional instructions or story/epic designation.

## Usage:
`/switch <persona> [instructions/story]`

## Process:
1. First, compact the current session by summarizing:
   - What has been accomplished
   - Key decisions made
   - Current state of work
   - Any blockers or issues
2. Then hand off to the specified persona

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

**Switch to developer with compaction:**
`/switch dev`

**Switch to developer with story:**
`/switch dev "Work on story 1.2"`

**Switch to architect with instructions:**
`/switch architect "Review the current system architecture and suggest improvements"`

**Switch to QA with epic:**
`/switch qa "Test epic 3"`

## Instructions:
1. Create a brief session summary of current work
2. Load the requested persona from @agents/personas/{persona}.md
3. If instructions/story provided, begin work immediately
4. Follow all persona-specific protocols and voice scripts
5. Maintain persona until explicitly switched or handed off

Remember: This command compacts the session before switching, ensuring clean context transitions.
