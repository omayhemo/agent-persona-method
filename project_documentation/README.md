# Project Documentation Structure

This directory contains all project-specific documentation generated and used by the AP Mapping agents.

## Directory Structure

### base/
Core project documents that serve as the foundation for all development work:
- `prd.md` - Product Requirements Document (created by PM agent)
- `architecture.md` - System Architecture Document (created by Architect agent)
- `frontend-architecture.md` - Frontend Architecture Document (created by Design Architect)
- `project_structure.md` - Project file/folder organization
- `development_workflow.md` - Development process and workflows
- `tech_stack.md` - Technology stack and dependencies
- `data-models.md` - Data structures and models
- `environment-vars.md` - Environment variable documentation

### epics/
Contains epic-level documentation:
- `epic-{n}.md` - Individual epic documents
- `epic-orchestration-guide.md` - Guide for managing epics

### stories/
User story documentation:
- `{epicNum}.{storyNum}.story.md` - Individual story files
- Stories are generated from epics by the SM agent

### qa/
Quality assurance documentation:
- `test-strategy.md` - Overall testing strategy
- `test-plan.md` - Detailed test plans
- `test-report.md` - Test execution reports
- `automation-plan.md` - Test automation plans
- `deployment-plan.md` - Deployment procedures
- `test-plans/` - Individual test plan documents
- `automation/` - Automation scripts and documentation

### index.md
Master index linking all documentation for easy navigation.

## Usage by Agents

- **Analyst**: Creates initial project briefs and research documents
- **PM**: Generates PRD and manages epic documentation
- **Architect**: Creates and maintains architecture documents
- **Design Architect**: Produces frontend architecture and UI/UX specs
- **PO**: Validates and organizes documentation alignment
- **SM**: Generates stories from epics, maintains story documentation
- **Developer**: References all documentation during implementation
- **QA**: Creates and maintains test documentation

## Important Notes

1. All paths in agent configurations use the $PROJECT_DOCS environment variable
2. Documents follow specific templates found in $AP_ROOT/agents/templates/
3. The structure supports both new projects and incremental feature development
4. Documentation is meant to be version controlled alongside code
