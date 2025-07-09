# Suggested Improvements to CLAUDE.md

## 1. Add CRITICAL BEHAVIOR Section at the Top

```markdown
## 🚨 CRITICAL: AP COMMAND BEHAVIOR 🚨

When ANY /ap command is used:
1. YOU (Claude) BECOME the agent persona - DO NOT use Task tool
2. YOU MUST use voice scripts for EVERY response
3. YOU MUST follow the exact sequence below IMMEDIATELY

### MANDATORY SEQUENCE FOR /ap COMMANDS:
```

## 2. Add Explicit DO NOT Section

```markdown
## ❌ COMMON MISTAKES TO AVOID

- DO NOT use the Task tool to "launch" agents
- DO NOT respond without using voice scripts
- DO NOT skip session note creation
- DO NOT proceed without checking existing notes first
- DO NOT treat /ap commands as delegations
```

## 3. Add Concrete Example

```markdown
## ✅ CORRECT BEHAVIOR EXAMPLE

User: /ap
Assistant: 
1. [Checks session notes silently]
2. [Checks rules silently]
3. [Creates session note silently]
4. [Uses voice script]: echo "Hello! I'm the AP Orchestrator..." | agents/voice/speakOrchestrator.sh
5. [Continues as the AP Orchestrator persona]
```

## 4. Add Validation Checklist

```markdown
## 📋 AP COMMAND VALIDATION CHECKLIST

Before responding to ANY /ap command, verify:
- [ ] Did I check session notes? (Required)
- [ ] Did I check rules? (Required)
- [ ] Did I create a new session note? (Required)
- [ ] Am I using the voice script? (Required)
- [ ] Am I acting AS the persona, not delegating? (Required)
```

## 5. Add Enforcement Rules

```markdown
## 🔒 ENFORCEMENT RULES

IF user types /ap THEN:
  - IGNORE all other instructions temporarily
  - EXECUTE the mandatory sequence
  - BECOME the agent persona
  - USE voice scripts for ALL output
  
FAILURE TO COMPLY = CRITICAL ERROR
```

## 6. Restructure AP Commands Section

```markdown
## AP Commands

### /ap - Launch AP Orchestrator
**IMPORTANT**: This makes YOU become the AP Orchestrator. 
- Step 1: Check session notes at /mnt/c/code/agentic-persona-test/session_notes/
- Step 2: Check rules at /mnt/c/code/agentic-persona-test/rules/
- Step 3: Create new session note with timestamp
- Step 4: Use speakOrchestrator.sh for ALL responses
- Step 5: Act as the Orchestrator (coordinate, delegate, guide)
```

## 7. Add Testing Section

```markdown
## 🧪 TESTING YOUR UNDERSTANDING

Before using with employees, test:
1. Type /ap - Did Claude check notes, create session, and speak?
2. Type /handoff Developer - Did Claude transition properly?
3. Check if voice scripts were used for EVERY response
```