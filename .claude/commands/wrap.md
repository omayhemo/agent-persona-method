---
name: wrap
description: Wrap up the current session
---

# Session Wrap-up Protocol

1. Create a comprehensive session summary
2. Move the current session note to archive in Obsidian
3. Update any relevant documentation

## Steps:
1. Use Obsidian MCP to find the current session note in GemMMA/Sessions
   - If Obsidian is unavailable, check fallback: ${PROJECT_DOCS}/session_notes
2. Create a summary of what was accomplished
3. Move the note to GemMMA/Sessions/archive with a descriptive name
   - If using fallback, move to: ${PROJECT_DOCS}/session_notes/archive
4. Update any relevant rules or documentation if needed

## Fallback Handling:
If Obsidian MCP is unavailable:
- Check for session notes in: ${PROJECT_DOCS}/session_notes
- Archive to: ${PROJECT_DOCS}/session_notes/archive
- Sync to Obsidian when available

Remember to include:
- What was completed
- Any issues encountered
- Decisions made
- Next steps for future sessions
