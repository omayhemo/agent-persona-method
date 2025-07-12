---
name: personas
description: List all available AP Mapping personas
---

# Available AP Mapping Personas

## Direct Activation Commands

Each persona has its own activation command with full initialization protocol:

### Core Orchestration
- `/ap` - AP Orchestrator (central coordinator)

### Specialist Personas
- `/analyst` - Business/Requirements Analyst
- `/pm` - Product Manager
- `/architect` - System Architect
- `/design-architect` - UI/UX Design Architect
- `/po` - Product Owner
- `/sm` - Scrum Master
- `/dev` or `/developer` - Developer Agent
- `/qa` - Quality Assurance

## Activation Methods

### Direct Activation (Recommended)
Use the persona-specific command:
```
/analyst
/pm
/architect
```

### Via Orchestrator
Activate through AP Orchestrator:
```
/ap
Then: "Activate [persona]"
```

### Handoff Between Personas
Direct transfer without session summary:
```
/handoff [persona]
/handoff dev "Implement story 1.2"
```

### Switch with Summary
Compact session and switch:
```
/switch [persona]
/switch qa "Test epic 3"
```

## Initialization Protocol

All personas follow a standardized initialization:
1. Parallel loading of 5 context sources
2. Voice announcement of activation
3. Confirmation message
4. Presentation of capabilities

This ensures consistent, fast activation with full context awareness.

## Persona Specializations

Some personas support specialization:
- Developer: Frontend, Backend, Mobile, DevOps
- Architect: Cloud, Security, Data, Integration

Specify during activation:
```
/dev "Specialize as Frontend Developer"
/architect "Focus on cloud architecture"
```

## Quick Reference

| Command | Role | Primary Focus |
|---------|------|---------------|
| `/ap` | Orchestrator | Method guidance, coordination |
| `/analyst` | Analyst | Research, requirements, briefs |
| `/pm` | Product Manager | PRDs, epics, strategy |
| `/architect` | Architect | System design, technical decisions |
| `/design-architect` | Design Architect | UI/UX, frontend architecture |
| `/po` | Product Owner | Backlog, prioritization |
| `/sm` | Scrum Master | Stories, sprint management |
| `/dev` | Developer | Implementation, code quality |
| `/qa` | QA | Testing, quality assurance |

Use `/wrap` to conclude any session with a summary.