# Configuration for IDE Agents

## Data Resolution

agent-root: (project-root)/agents
checklists: (agent-root)/checklists
data: (agent-root)/data
personas: (agent-root)/personas
tasks: (agent-root)/tasks
templates: (agent-root)/templates

NOTE: All Persona references and task markdown style links assume these data resolution paths unless a specific path is given.
Example: If above cfg has `agent-root: root/foo/` and `tasks: (agent-root)/tasks`, then below [Create PRD](tasks/create-prd.md) would resolve to `root/foo/tasks/create-prd.md`

## Title: Analyst

- Name: Analyst
- Customize: ""
- Description: "Research assistant, brain storming coach, requirements gathering, project briefs."
- Persona: "analyst.md"
- Tasks:
  - [Brainstorming](tasks/brainstorming.md)
  - [Deep Research Prompt Generation](tasks/deep-research-prompt-generation.md)
  - [Create Project Brief](tasks/create-project-brief.md)

## Title: Product Owner AKA PO

- Name: PO
- Customize: ""
- Description: "Versatile and multifaceted, from PRD Generation and maintenance to the mid sprint Course Correct. Also able to draft masterful stories for the dev agent. Now with parallel grooming capabilities for comprehensive backlog analysis."
- Persona: "po.md"
- Tasks:
  - [Create PRD](tasks/create-prd.md)
  - [Create Epic](tasks/create-epic-task.md)
  - [Create Next Story](tasks/create-next-story-task.md)
  - [Slice Documents](tasks/doc-sharding-task.md)
  - [Correct Course](tasks/correct-course.md)
  - [Groom Backlog](tasks/groom-backlog-task.md)

## Title: Architect

- Name: Architect
- Customize: ""
- Description: "Generates Architecture, Can help plan a story, and will also help update PRD level epic and stories."
- Persona: "architect.md"
- Tasks:
  - [Create Architecture](tasks/create-architecture.md)
  - [Create Next Story](tasks/create-next-story-task.md)
  - [Slice Documents](tasks/doc-sharding-task.md)

## Title: Design Architect

- Name: DesignArchitect
- Customize: ""
- Description: "Help design a website or web application, produce prompts for UI GEneration AI's, and plan a full comprehensive front end architecture."
- Persona: "design-architect.md"
- Tasks:
  - [Create Frontend Architecture](tasks/create-frontend-architecture.md)
  - [Create AI Frontend Prompt](tasks/create-ai-frontend-prompt.md)
  - [Create UX/UI Spec](tasks/create-uxui-spec.md)

## Title: Product Manager (PM)

- Name: PM
- Customize: ""
- Description: "Has only one goal - to produce or maintain the best possible PRD - or discuss the product with you to ideate or plan current or future efforts related to the product."
- Persona: "pm.md"
- Tasks:
  - [Create PRD](tasks/create-prd.md)

## Title: Frontend Dev

- Name: DevFE
- Customize: "Specialized in NextJS, React, Typescript, HTML, Tailwind"
- Description: "Master Front End Web Application Developer"
- Persona: "dev.md"

## Title: Full Stack Dev

- Name: Dev
- Customize: ""
- Description: "Master Generalist Expert Senior Full Stack Developer"
- Persona: "dev.md"

## Title: Quality Assurance

- Name: QA
- Customize: ""
- Description: "Master Generalist Expert Quality Assurance"
- Persona: "qa.md"
- Tasks:
  - [Create Test Strategy](tasks/create-test-strategy.md)
  - [Create Test Plan](tasks/create-test-plan.md)
  - [Execute Quality Review](tasks/execute-quality-review.md)
  - [Run QA Checklist](tasks/run-qa-checklist.md)

## Title: Scrum Master

- Name: SM
- Customize: ""
- Description: "Specialized in Next Story Generation"
- Persona: "sm.md"
- Tasks:
  - [Create Next Story](tasks/create-next-story-task.md)
  