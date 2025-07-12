# Task: Groom Product Backlog

## Metadata
- Agent: Product Owner
- Command: /groom
- Complexity: Complex (Parallel Execution)
- Estimated Time: 5-10 minutes (with parallel processing)

## Description
Comprehensive backlog grooming that analyzes documentation, generates epics and stories, identifies dependencies, and creates an optimized sprint plan - all through parallel subtask execution.

## Prerequisites
- Access to project documentation
- Existing PRD or requirements documents
- Architecture documentation (if available)
- Team velocity data (optional)

## Input Parameters
```bash
/groom [options]
  --source <path>         # Documentation source (default: $PROJECT_DOCS)
  --output <path>         # Output directory (default: $PROJECT_DOCS/backlog)
  --sprint-length <days>  # Sprint duration (default: 14)
  --team-velocity <pts>   # Team velocity (default: 40)
  --focus-areas <list>    # Specific areas to prioritize
```

## Execution Phases

### Phase 1: Parallel Documentation Analysis
Launch all analysis subtasks simultaneously:
1. Domain Analysis - Extract domain models and boundaries
2. Feature Extraction - Identify features and requirements
3. Technical Debt Analysis - Find refactoring opportunities
4. Integration Points Analysis - Map system dependencies
5. Compliance Analysis - Identify constraints and regulations

### Phase 2: Parallel Epic Generation
Based on Phase 1 results, generate epics concurrently:
1. Feature Epics - From functional requirements
2. Technical Epics - From debt and infrastructure needs
3. Integration Epics - From system dependencies
4. Compliance Epics - From regulatory requirements

### Phase 3: Parallel Story Decomposition
Break down each epic into stories simultaneously:
1. Story Breakdown - Create commit-level stories
2. Story Sizing - Estimate complexity and points
3. Story Dependencies - Map relationships

### Phase 4: Optimization & Prioritization
Run analysis for optimal planning:
1. Dependency Graph Generation - Build comprehensive DAG
2. Business Value Scoring - Calculate ROI and priority
3. Risk Assessment - Identify implementation risks
4. Parallel Work Stream Identification - Find independent tracks

### Phase 5: Sprint Planning
Generate final sprint allocation:
1. Sprint Allocation - Distribute stories across sprints
2. Capacity Optimization - Balance team utilization

## Output Artifacts

### 1. Backlog Manifest (backlog-manifest.yaml)
Complete epic and story catalog with metadata

### 2. Dependency Visualization (dependencies.mermaid)
Visual representation of story relationships

### 3. Sprint Plan (sprint-plan.md)
Detailed sprint-by-sprint breakdown

### 4. Parallel Tracks (parallel-tracks.json)
Identified work streams for parallel execution

### 5. Grooming Report (grooming-report.md)
Summary of analysis with key insights

## Subtask Directory Structure
```
agents/tasks/subtasks/po/
├── groom-domain-analysis.md
├── groom-feature-extraction.md
├── groom-technical-debt-analysis.md
├── groom-integration-analysis.md
├── groom-compliance-analysis.md
├── groom-epic-generation.md
├── groom-story-breakdown.md
├── groom-story-sizing.md
├── groom-dependency-graph.md
├── groom-business-value.md
├── groom-risk-assessment.md
├── groom-parallel-streams.md
├── groom-sprint-allocation.md
└── groom-capacity-optimization.md
```

## Success Criteria
- All documentation analyzed systematically
- Epics cover all identified features and requirements
- Stories are atomic and independently deployable
- Dependencies clearly mapped with no cycles
- Parallel work streams identified for efficiency
- Sprint plan respects team capacity and priorities

## Example Usage
```bash
/groom --source $PROJECT_DOCS/requirements --sprint-length 14 --team-velocity 45
```

This will analyze all requirements, generate a complete backlog, and create an optimized sprint plan for a team with 45-point velocity in 14-day sprints.