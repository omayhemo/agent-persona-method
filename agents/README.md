# AP Mapping - Agentic Persona Mapping

The AP (Agentic Persona) Mapping is a project-agnostic approach to orchestrating AI agents for software development. This system provides specialized agent personas, each with specific expertise and responsibilities, working together in a structured workflow to deliver high-quality software projects.

## Quick Start

Launch the orchestrator:
```
/ap
```

Check for updates:
```bash
scripts/ap-manager.sh update
```

## How the AP Mapping Works

### Core Philosophy

The AP Mapping treats software development as a collaborative effort between specialized AI agents, each embodying the expertise and perspective of a specific role. Unlike a single AI trying to handle all aspects, each agent:

- **Maintains Deep Focus**: Each agent specializes in their domain (architecture, development, QA, etc.)
- **Follows Role-Specific Protocols**: Agents operate according to their persona's best practices and methodologies
- **Produces Domain Artifacts**: Each agent creates appropriate documentation and deliverables for their role
- **Enables Handoffs**: Work flows naturally between agents as it would between human team members

### The Orchestration Model

The AP Orchestrator serves as the project's technical lead and coordinator:

1. **Context Management**: Maintains project state and ensures agents have necessary context
2. **Agent Selection**: Determines which specialist is best suited for current tasks
3. **Quality Gates**: Automated by hooks - documents are validated against templates
4. **Memory Persistence**: Automated by hooks - session notes and activity tracking handled automatically

### Key Principles

- **Single Active Persona**: Only one agent is active at a time, ensuring focused expertise
- **Document-Driven**: All decisions and designs are captured in structured documentation
- **Iterative Refinement**: Agents can revisit and improve previous work as understanding deepens
- **Context Preservation**: Session notes and project docs maintain continuity across sessions

## Environment Variables

The following variables are configured in `.claude/settings.json`:

- `$AP_ROOT` - Path to agents directory
- `$PROJECT_DOCS` - Path to project documentation
- `$SPEAK_ORCHESTRATOR` - Orchestrator voice script
- `$SPEAK_DEVELOPER` - Developer voice script
- `$SPEAK_ARCHITECT` - Architect voice script
- `$SPEAK_ANALYST` - Analyst voice script
- `$SPEAK_QA` - QA voice script
- `$SPEAK_PM` - Product Manager voice script
- `$SPEAK_PO` - Product Owner voice script
- `$SPEAK_SM` - Scrum Master voice script

## Available Commands

These commands are available in Claude:

### Core Commands
- `/ap` - Launch AP Orchestrator
- `/handoff` - Hand off to another agent persona (direct transition)
- `/switch` - Compact session and switch to another agent persona
- `/wrap` - Wrap up current session
- `/session-note-setup` - Set up session structure

### Parallel Execution Commands
- `/groom` (Product Owner) - Comprehensive backlog grooming with 18 parallel subtasks
- `/parallel-review` (Developer) - Execute parallel code analysis (security, performance, etc.)
- `/parallel-test` (QA) - Execute parallel test suite (cross-browser, accessibility, etc.)

## The AP Workflow

### Phase 1: Discovery and Analysis

1. **Start with the Orchestrator** (`/ap`)
   - Assess project needs and current state
   - Determine starting point based on available information

2. **Analyst Deep Dive**
   - Research domain and technical requirements
   - Create project brief with findings
   - Identify key challenges and opportunities
   - Output: `project_brief.md`

### Phase 2: Product Definition

3. **Product Manager Planning**
   - Transform brief into product vision
   - Define epics and high-level features
   - Create PRD (Product Requirements Document)
   - Output: `prd.md`, `epic-*.md` files

4. **Product Owner Refinement**
   - Validate requirements feasibility
   - Prioritize backlog items
   - Define acceptance criteria
   - Ensure business value alignment
   - **NEW**: Use `/groom` for comprehensive parallel backlog analysis:
     - Analyzes documentation across 5 phases simultaneously
     - Generates epics, stories, dependencies, and sprint plans
     - Optimizes for parallel development and maximum ROI

### Phase 3: Technical Design

5. **Architect System Design**
   - Create high-level architecture
   - Define technology stack
   - Plan system components and interactions
   - Output: `architecture.md`, `tech_stack.md`

6. **Design Architect Frontend Planning**
   - Design UI/UX architecture
   - Component hierarchy and state management
   - Frontend technology decisions
   - Output: `frontend-architecture.md`, `uxui-spec.md`

### Phase 4: Implementation Planning

7. **Scrum Master Story Generation**
   - Break epics into implementable stories
   - Sequence work for optimal flow
   - Define story-level acceptance criteria
   - Output: `*.story.md` files

### Phase 5: Development and Quality

8. **Developer Implementation**
   - Implement stories following architecture
   - Create clean, maintainable code
   - Follow project conventions
   - Update documentation as needed

9. **QA Validation**
   - Create test strategies and plans
   - Validate implementation meets requirements
   - Ensure quality standards
   - Output: `test-strategy.md`, `test-plan.md`

### Phase 6: Iteration and Refinement

10. **Orchestrator Review**
    - Assess progress and quality
    - Identify areas needing attention
    - Coordinate next iterations
    - Hand off to appropriate specialist

## Agent Personas

### AP Orchestrator
- **Role**: Central coordinator and method expert
- **Focus**: Project oversight, agent coordination, quality assurance
- **Key Activities**: Context management, agent selection, workflow orchestration
- **Outputs**: Session summaries, coordination decisions

### Developer
- **Role**: Implementation specialist
- **Focus**: Clean code, best practices, technical execution
- **Key Activities**: Story implementation, code review, debugging
- **Outputs**: Source code, implementation notes

### Architect
- **Role**: System design expert
- **Focus**: Scalability, maintainability, technical excellence
- **Key Activities**: Architecture design, technology selection, pattern definition
- **Outputs**: Architecture docs, design patterns, technical specifications

### Design Architect
- **Role**: UI/UX and frontend specialist
- **Focus**: User experience, component design, frontend architecture
- **Key Activities**: UI patterns, state management, responsive design
- **Outputs**: Frontend architecture, component specs, UX guidelines

### Analyst
- **Role**: Requirements and research expert
- **Focus**: Domain understanding, requirement gathering, feasibility
- **Key Activities**: Research, stakeholder analysis, requirement documentation
- **Outputs**: Project briefs, research findings, requirement specs

### QA
- **Role**: Quality assurance specialist
- **Focus**: Testing strategy, quality metrics, validation
- **Key Activities**: Test planning, quality gates, defect tracking
- **Outputs**: Test plans, quality reports, validation results

### Product Manager
- **Role**: Market and strategy expert
- **Focus**: Product vision, market fit, feature prioritization
- **Key Activities**: PRD creation, epic definition, roadmap planning
- **Outputs**: PRDs, epics, product strategy docs

### Product Owner
- **Role**: Business requirements expert with parallel grooming capabilities
- **Focus**: Business value, stakeholder needs, acceptance criteria, backlog optimization
- **Key Activities**: Backlog management, requirement validation, priority setting, parallel grooming
- **Outputs**: Refined requirements, acceptance criteria, priority decisions, optimized sprint plans
- **Special Command**: `/groom` - Executes 18 parallel subtasks for comprehensive backlog analysis

### Scrum Master
- **Role**: Process and story management
- **Focus**: Agile practices, story breakdown, team velocity
- **Key Activities**: Story generation, sprint planning, process improvement
- **Outputs**: User stories, sprint plans, velocity tracking

## Voice Scripts

All voice scripts are located in `agents/voice/`:
- Each agent has a dedicated voice script
- Scripts use text-to-speech for audio notifications
- Configured via environment variables for portability

## Session Management

**Note: Session management is now fully automated by Claude Code hooks.**

### Automated Features
- **Activity Tracking**: All file operations logged automatically
- **Session Notes**: Created daily with comprehensive activity logs
- **Quality Validation**: Documents checked against templates in real-time
- **Agent Handoffs**: Validated and documented automatically
- **Session Summaries**: Generated when Claude Code stops

### Storage Locations
- **With Obsidian MCP**: Sessions stored in configured vault
- **Fallback**: Local markdown files at `$PROJECT_DOCS/session_notes/`
- **Logs**: Hook activity logs in `$AP_ROOT/hooks/`

## Troubleshooting

1. **Script not found**: Check script permissions
2. **Voice scripts not working**: Check that scripts are executable
3. **Commands not available**: Verify `.claude/commands` directory exists
4. **Path issues**: All paths use environment variables for portability

## Best Practices for Using APM

### 1. Always Start with Context
- Begin each session by launching `/ap`
- Let the Orchestrator assess current state
- Trust the Orchestrator's agent recommendations

### 2. Embrace the Handoff
- Use `/handoff` to switch between agents naturally
- Provide context when handing off: `/handoff qa "Test the authentication flow"`
- Allow each agent to complete their focused work

### 3. Document Everything
- Agents automatically create appropriate documentation
- Review and refine documentation as project evolves
- Use session notes to track decisions and progress

### 4. Iterate Intelligently
- Don't expect perfection in first pass
- Allow agents to revisit and refine previous work
- Use discoveries from implementation to improve design

### 5. Leverage Specialization
- Let each agent work within their expertise
- Don't ask Developer to make architecture decisions
- Don't ask Architect to implement code
- Trust each agent's domain knowledge

## Common Workflows

### Starting a New Project
```
1. /ap                          # Start with Orchestrator
2. Select Analyst               # Research and understand domain
3. Review project brief         # Understand findings
4. Handoff to PM               # Create product vision
5. Continue through workflow    # Follow natural progression
```

### Adding a New Feature
```
1. /ap                          # Assess current state
2. Select PM or PO              # Define feature requirements  
3. Handoff to Architect        # Design technical approach
4. Handoff to SM               # Break into stories
5. Handoff to Developer        # Implement stories
```

### Fixing Issues
```
1. /ap                          # Understand issue context
2. Select QA                    # Investigate and document issue
3. Handoff to Developer        # Implement fix
4. Handoff back to QA          # Validate fix
```

## Design Philosophy

The AP Mapping is designed to be completely project-agnostic and portable across different codebases. All configuration is stored in `.claude/settings.json` for easy management.

### Why AP Mapping Works

1. **Cognitive Load Distribution**: Each agent maintains deep focus on their domain
2. **Natural Workflow**: Mirrors real software team dynamics
3. **Quality Through Specialization**: Each deliverable benefits from focused expertise
4. **Flexibility**: Adapt the workflow to project needs
5. **Memory Persistence**: Session notes and docs maintain context across time