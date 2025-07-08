#!/usr/bin/env node

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const PROJECT_DOCS = process.env.PROJECT_DOCS || path.join(__dirname, '../../project_documentation');
const EPICS_DIR = path.join(PROJECT_DOCS, 'epics');
const STORIES_DIR = path.join(PROJECT_DOCS, 'stories');
const BACKUP_DIR = path.join(PROJECT_DOCS, 'backups');
const LOG_FILE = path.join(PROJECT_DOCS, '../harmonization.log');

// Story template for creating comprehensive technical stories
const STORY_TEMPLATE = `# [TITLE]

## Overview
**Epic**: [EPIC_LINK]
**Type**: [TYPE]
**Priority**: [PRIORITY]
**Estimated Effort**: [EFFORT]

[DESCRIPTION]

## User Story
As a [USER_TYPE]
I want to [GOAL]
So that [BENEFIT]

## Acceptance Criteria
[ACCEPTANCE_CRITERIA]

## Technical Approach

### Architecture Overview
[ARCHITECTURE]

### Component Design
[COMPONENT_DESIGN]

### Data Flow
[DATA_FLOW]

### API Design
[API_DESIGN]

### State Management
[STATE_MANAGEMENT]

## Implementation Steps

### Phase 1: Foundation
[PHASE_1_STEPS]

### Phase 2: Core Implementation
[PHASE_2_STEPS]

### Phase 3: Integration
[PHASE_3_STEPS]

### Phase 4: Testing & Optimization
[PHASE_4_STEPS]

## Technical Specifications

### Dependencies
[DEPENDENCIES]

### Interfaces
[INTERFACES]

### Configuration
[CONFIGURATION]

### Security Considerations
[SECURITY]

### Performance Requirements
[PERFORMANCE]

## Testing Strategy

### Unit Tests
[UNIT_TESTS]

### Integration Tests
[INTEGRATION_TESTS]

### E2E Tests
[E2E_TESTS]

### Performance Tests
[PERFORMANCE_TESTS]

## Monitoring & Observability
[MONITORING]

## Documentation Requirements
[DOCUMENTATION]

## Rollout Strategy
[ROLLOUT]

## Dependencies and Blockers
[DEPENDENCIES_BLOCKERS]

## Related Stories
[RELATED_STORIES]

## Notes
[NOTES]
`;

// Logging utilities
function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}`;
  console.log(logMessage);
  fs.appendFile(LOG_FILE, logMessage + '\n').catch(console.error);
}

// Speak function
function speak(message) {
  try {
    const speakScript = process.env.SPEAK_ORCHESTRATOR || path.join(__dirname, '../voice/speakLessac.sh');
    execSync(`${speakScript} "${message}"`, { stdio: 'ignore' });
  } catch (error) {
    // Ignore speech errors
  }
}

// Create backup
async function createBackup() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = path.join(BACKUP_DIR, `backup-${timestamp}`);
  
  await fs.mkdir(backupPath, { recursive: true });
  await fs.cp(EPICS_DIR, path.join(backupPath, 'epics'), { recursive: true });
  
  if (await fs.access(STORIES_DIR).then(() => true).catch(() => false)) {
    await fs.cp(STORIES_DIR, path.join(backupPath, 'stories'), { recursive: true });
  }
  
  log(`Created backup at ${backupPath}`);
  return backupPath;
}

// Parse epic file
async function parseEpic(filePath) {
  const content = await fs.readFile(filePath, 'utf-8');
  const fileName = path.basename(filePath);
  
  // Extract epic information
  const titleMatch = content.match(/^#\s+(.+)$/m);
  const idMatch = fileName.match(/EPIC-(\d+[AB]?)/);
  const typeMatch = fileName.match(/(frontend|backend|infrastructure|data|monitoring)/i);
  
  return {
    filePath,
    fileName,
    content,
    id: idMatch ? idMatch[1] : null,
    title: titleMatch ? titleMatch[1] : fileName,
    type: typeMatch ? typeMatch[1].toLowerCase() : 'general',
    isFrontend: fileName.includes('A-') || fileName.includes('frontend'),
    isBackend: fileName.includes('B-') || fileName.includes('backend'),
    stories: extractStoriesFromEpic(content)
  };
}

// Extract story references from epic
function extractStoriesFromEpic(content) {
  const storyRegex = /\[STORY-\d+[AB]?(?:-\d+)?\]/g;
  const matches = content.match(storyRegex) || [];
  return [...new Set(matches.map(m => m.slice(1, -1)))];
}

// Phase 1: Split full-stack epics
async function phase1SplitEpics() {
  log('=== PHASE 1: Splitting Full-Stack Epics ===');
  speak('Starting phase 1: Splitting full-stack epics into frontend and backend epics');
  
  const files = await fs.readdir(EPICS_DIR);
  const epicFiles = files.filter(f => f.startsWith('EPIC-') && f.endsWith('.md'));
  
  let splitCount = 0;
  
  for (const file of epicFiles) {
    // Skip already split epics
    if (file.includes('A-') || file.includes('B-') || 
        file.includes('frontend') || file.includes('backend')) {
      continue;
    }
    
    // Skip infrastructure/data/monitoring epics
    if (file.match(/infrastructure|data|monitoring|rag|ai|database|caching|scalability/i)) {
      continue;
    }
    
    const filePath = path.join(EPICS_DIR, file);
    const epic = await parseEpic(filePath);
    
    if (!epic.id) continue;
    
    log(`Splitting ${file} into Frontend and Backend epics`);
    
    // Create Frontend epic
    const frontendFile = file.replace(`.md`, `A-frontend.md`).replace(`EPIC-${epic.id}`, `EPIC-${epic.id}A`);
    const frontendContent = await createFrontendEpic(epic);
    await fs.writeFile(path.join(EPICS_DIR, frontendFile), frontendContent);
    
    // Create Backend epic
    const backendFile = file.replace(`.md`, `B-backend.md`).replace(`EPIC-${epic.id}`, `EPIC-${epic.id}B`);
    const backendContent = await createBackendEpic(epic);
    await fs.writeFile(path.join(EPICS_DIR, backendFile), backendContent);
    
    // Archive original
    await fs.rename(filePath, filePath.replace('.md', '-SPLIT.md'));
    
    splitCount++;
  }
  
  log(`Phase 1 Complete: Split ${splitCount} epics`);
  speak(`Phase 1 complete. Split ${splitCount} epics into frontend and backend versions`);
}

// Create frontend epic content
async function createFrontendEpic(originalEpic) {
  const content = originalEpic.content;
  const frontendContent = content
    .replace(/^#\s+(.+)$/m, `# ${originalEpic.title} - Frontend`)
    .replace(/\[STORY-(\d+)\]/g, '[STORY-$1A]');
    
  // Add frontend-specific sections if not present
  if (!frontendContent.includes('## UI Components')) {
    const sections = `
## UI Components
- Component architecture and hierarchy
- Reusable component library
- Component documentation

## State Management
- Global state architecture
- Local component state
- State persistence strategy

## User Experience
- Responsive design implementation
- Accessibility standards
- Performance optimization
- Progressive enhancement
`;
    return frontendContent + sections;
  }
  
  return frontendContent;
}

// Create backend epic content
async function createBackendEpic(originalEpic) {
  const content = originalEpic.content;
  const backendContent = content
    .replace(/^#\s+(.+)$/m, `# ${originalEpic.title} - Backend`)
    .replace(/\[STORY-(\d+)\]/g, '[STORY-$1B]');
    
  // Add backend-specific sections if not present
  if (!backendContent.includes('## API Design')) {
    const sections = `
## API Design
- RESTful endpoint structure
- GraphQL schema design
- API versioning strategy
- Rate limiting and throttling

## Data Architecture
- Database schema design
- Data access patterns
- Query optimization
- Data validation rules

## Service Architecture
- Microservice boundaries
- Service communication
- Event-driven patterns
- Error handling strategy

## Infrastructure
- Deployment architecture
- Scaling strategy
- Monitoring and logging
- Performance optimization
`;
    return backendContent + sections;
  }
  
  return backendContent;
}

// Phase 2: Create missing stories
async function phase2CreateStories() {
  log('=== PHASE 2: Creating Missing Stories ===');
  speak('Starting phase 2: Creating all missing stories');
  
  await fs.mkdir(STORIES_DIR, { recursive: true });
  
  const files = await fs.readdir(EPICS_DIR);
  const epicFiles = files.filter(f => f.startsWith('EPIC-') && f.endsWith('.md') && !f.includes('SPLIT'));
  
  let storyCount = 0;
  const allStories = new Set();
  
  // First pass: collect all story references
  for (const file of epicFiles) {
    const epic = await parseEpic(path.join(EPICS_DIR, file));
    epic.stories.forEach(s => allStories.add(s));
  }
  
  // Second pass: create stories
  for (const file of epicFiles) {
    const epic = await parseEpic(path.join(EPICS_DIR, file));
    
    // Generate stories based on epic type
    const storiesNeeded = getStoriesForEpic(epic);
    
    for (const storyDef of storiesNeeded) {
      const storyId = storyDef.id;
      const storyFile = `${storyId}.md`;
      const storyPath = path.join(STORIES_DIR, storyFile);
      
      // Check if story already exists
      if (await fs.access(storyPath).then(() => true).catch(() => false)) {
        continue;
      }
      
      log(`Creating story ${storyId} for ${epic.fileName}`);
      const storyContent = await generateStoryContent(storyDef, epic);
      await fs.writeFile(storyPath, storyContent);
      storyCount++;
    }
  }
  
  log(`Phase 2 Complete: Created ${storyCount} new stories`);
  speak(`Phase 2 complete. Created ${storyCount} new stories`);
}

// Get stories needed for an epic
function getStoriesForEpic(epic) {
  const stories = [];
  const epicNum = epic.id.replace(/[AB]/, '');
  const suffix = epic.isFrontend ? 'A' : epic.isBackend ? 'B' : '';
  
  // Define story patterns based on epic type
  const storyPatterns = {
    'timeline': [
      { id: `STORY-${epicNum}${suffix}-001`, title: 'Timeline Component Architecture', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-002`, title: 'Event Clustering Implementation', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-003`, title: 'Timeline Navigation Controls', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-004`, title: 'Density Visualization', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-005`, title: 'Mobile Responsive Design', type: 'technical' }
    ],
    'event': [
      { id: `STORY-${epicNum}${suffix}-001`, title: 'Event Search Interface', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-002`, title: 'Event Filtering System', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-003`, title: 'Event Detail Display', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-004`, title: 'Event API Integration', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-005`, title: 'Event Data Caching', type: 'technical' }
    ],
    'admin': [
      { id: `STORY-${epicNum}${suffix}-001`, title: 'Admin Dashboard Layout', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-002`, title: 'User Management Interface', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-003`, title: 'Role Permission System', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-004`, title: 'Admin API Endpoints', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-005`, title: 'Audit Logging System', type: 'technical' }
    ],
    'authentication': [
      { id: `STORY-${epicNum}${suffix}-001`, title: 'Login/Register Forms', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-002`, title: 'JWT Token Management', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-003`, title: 'OAuth Integration', type: 'feature' },
      { id: `STORY-${epicNum}${suffix}-004`, title: 'Session Management', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-005`, title: 'Password Reset Flow', type: 'feature' }
    ],
    'default': [
      { id: `STORY-${epicNum}${suffix}-001`, title: 'Core Component Setup', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-002`, title: 'Data Model Implementation', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-003`, title: 'API Integration Layer', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-004`, title: 'Testing Infrastructure', type: 'technical' },
      { id: `STORY-${epicNum}${suffix}-005`, title: 'Documentation & Examples', type: 'documentation' }
    ]
  };
  
  // Determine pattern based on epic
  let pattern = 'default';
  if (epic.fileName.includes('timeline')) pattern = 'timeline';
  else if (epic.fileName.includes('event')) pattern = 'event';
  else if (epic.fileName.includes('admin')) pattern = 'admin';
  else if (epic.fileName.includes('auth')) pattern = 'authentication';
  
  return storyPatterns[pattern] || storyPatterns.default;
}

// Generate comprehensive story content
async function generateStoryContent(storyDef, epic) {
  const epicLink = `[${epic.fileName}](../epics/${epic.fileName})`;
  const storyType = epic.isFrontend ? 'Frontend' : epic.isBackend ? 'Backend' : 'Full-Stack';
  
  // Generate content based on story type
  const content = STORY_TEMPLATE
    .replace('[TITLE]', `${storyDef.id}: ${storyDef.title}`)
    .replace('[EPIC_LINK]', epicLink)
    .replace('[TYPE]', storyType)
    .replace('[PRIORITY]', 'High')
    .replace('[EFFORT]', '5-8 story points')
    .replace('[DESCRIPTION]', generateDescription(storyDef, epic))
    .replace('[USER_TYPE]', getUserType(epic))
    .replace('[GOAL]', generateGoal(storyDef))
    .replace('[BENEFIT]', generateBenefit(storyDef))
    .replace('[ACCEPTANCE_CRITERIA]', generateAcceptanceCriteria(storyDef, epic))
    .replace('[ARCHITECTURE]', generateArchitecture(storyDef, epic))
    .replace('[COMPONENT_DESIGN]', generateComponentDesign(storyDef, epic))
    .replace('[DATA_FLOW]', generateDataFlow(storyDef, epic))
    .replace('[API_DESIGN]', generateAPIDesign(storyDef, epic))
    .replace('[STATE_MANAGEMENT]', generateStateManagement(storyDef, epic))
    .replace('[PHASE_1_STEPS]', generatePhase1Steps(storyDef, epic))
    .replace('[PHASE_2_STEPS]', generatePhase2Steps(storyDef, epic))
    .replace('[PHASE_3_STEPS]', generatePhase3Steps(storyDef, epic))
    .replace('[PHASE_4_STEPS]', generatePhase4Steps(storyDef, epic))
    .replace('[DEPENDENCIES]', generateDependencies(storyDef, epic))
    .replace('[INTERFACES]', generateInterfaces(storyDef, epic))
    .replace('[CONFIGURATION]', generateConfiguration(storyDef, epic))
    .replace('[SECURITY]', generateSecurity(storyDef, epic))
    .replace('[PERFORMANCE]', generatePerformance(storyDef, epic))
    .replace('[UNIT_TESTS]', generateUnitTests(storyDef, epic))
    .replace('[INTEGRATION_TESTS]', generateIntegrationTests(storyDef, epic))
    .replace('[E2E_TESTS]', generateE2ETests(storyDef, epic))
    .replace('[PERFORMANCE_TESTS]', generatePerformanceTests(storyDef, epic))
    .replace('[MONITORING]', generateMonitoring(storyDef, epic))
    .replace('[DOCUMENTATION]', generateDocumentation(storyDef, epic))
    .replace('[ROLLOUT]', generateRollout(storyDef, epic))
    .replace('[DEPENDENCIES_BLOCKERS]', generateDependenciesBlockers(storyDef, epic))
    .replace('[RELATED_STORIES]', generateRelatedStories(storyDef, epic))
    .replace('[NOTES]', generateNotes(storyDef, epic));
    
  return content;
}

// Content generation helpers
function generateDescription(storyDef, epic) {
  const descriptions = {
    'Timeline Component Architecture': `
This story focuses on building the core timeline component architecture that will serve as the foundation
for the MMA TV Guide timeline interface. The implementation will create a flexible, performant, and 
extensible component system that supports horizontal scrolling, event clustering, and dynamic data loading.

Key aspects include:
- Modular component structure with clear separation of concerns
- Virtual scrolling implementation for handling large datasets
- Responsive design system that works across all device sizes
- Accessibility-first approach with keyboard navigation support
- Performance optimization through React.memo and useMemo
- Custom hooks for timeline-specific functionality`,
    
    'Event Search Interface': `
Implement a comprehensive event search interface that allows users to quickly find MMA events
based on various criteria. The search system will provide instant results with type-ahead
functionality and intelligent ranking.

Key features:
- Real-time search with debounced API calls
- Multi-field search across event names, fighters, organizations
- Search result preview with key event information
- Search history and saved searches functionality
- Voice search capability for mobile users
- Advanced filters integration with search`,
    
    'Admin Dashboard Layout': `
Create the administrative dashboard layout that provides a comprehensive overview of system
status, user activity, and content management capabilities. The dashboard will serve as the
central hub for all administrative functions.

Core components:
- Responsive grid layout with customizable widgets
- Real-time metrics and status indicators
- Quick action panels for common tasks
- Activity feed showing recent system events
- Performance monitoring visualizations
- Role-based UI element visibility`
  };
  
  return descriptions[storyDef.title] || `
Implementation of ${storyDef.title} for the ${epic.title} epic. This story encompasses
the design, development, and testing of all components and functionality required to
deliver this feature to production.`;
}

function getUserType(epic) {
  if (epic.fileName.includes('admin')) return 'System Administrator';
  if (epic.fileName.includes('content')) return 'Content Manager';
  if (epic.fileName.includes('auth')) return 'Registered User';
  return 'MMA Fan';
}

function generateGoal(storyDef) {
  const goals = {
    'feature': 'have access to this functionality in the application',
    'technical': 'ensure the system operates efficiently and reliably',
    'documentation': 'understand how to use and maintain this feature'
  };
  return goals[storyDef.type] || 'complete this user story successfully';
}

function generateBenefit(storyDef) {
  const benefits = {
    'feature': 'I can perform my tasks more efficiently and effectively',
    'technical': 'the system maintains high performance and reliability standards',
    'documentation': 'knowledge is preserved and accessible to the team'
  };
  return benefits[storyDef.type] || 'the product delivers value to its users';
}

function generateAcceptanceCriteria(storyDef, epic) {
  const baseCriteria = `
- [ ] Feature is fully implemented according to specifications
- [ ] All unit tests pass with >80% coverage
- [ ] Integration tests verify component interactions
- [ ] UI/UX matches approved designs (if applicable)
- [ ] Performance benchmarks are met
- [ ] Security review completed and issues addressed
- [ ] Documentation is complete and reviewed
- [ ] Code review approved by senior developer
- [ ] Accessibility standards (WCAG 2.1 AA) met
- [ ] Cross-browser testing completed`;

  // Add specific criteria based on story type
  const specificCriteria = {
    'Timeline Component Architecture': `
- [ ] Timeline renders 1000+ events without performance degradation
- [ ] Horizontal scrolling is smooth on all devices
- [ ] Virtual scrolling implemented for large datasets
- [ ] Component is fully keyboard navigable
- [ ] Touch gestures work on mobile devices`,
    
    'Event Search Interface': `
- [ ] Search returns results in <200ms
- [ ] Type-ahead suggestions appear after 2 characters
- [ ] Search results are ranked by relevance
- [ ] Filter combinations work correctly
- [ ] Search state persists across navigation`
  };
  
  return baseCriteria + (specificCriteria[storyDef.title] || '');
}

function generateArchitecture(storyDef, epic) {
  if (epic.isFrontend) {
    return `
### Component Architecture
\`\`\`
src/
├── components/
│   ├── ${storyDef.title.replace(/\s+/g, '')}/
│   │   ├── index.tsx
│   │   ├── ${storyDef.title.replace(/\s+/g, '')}.tsx
│   │   ├── ${storyDef.title.replace(/\s+/g, '')}.styles.ts
│   │   ├── ${storyDef.title.replace(/\s+/g, '')}.types.ts
│   │   ├── ${storyDef.title.replace(/\s+/g, '')}.test.tsx
│   │   └── components/
│   │       ├── SubComponent1.tsx
│   │       └── SubComponent2.tsx
│   └── shared/
│       └── CommonComponents.tsx
├── hooks/
│   └── use${storyDef.title.replace(/\s+/g, '')}.ts
├── services/
│   └── ${storyDef.title.replace(/\s+/g, '')}Service.ts
└── types/
    └── ${storyDef.title.replace(/\s+/g, '')}.types.ts
\`\`\`

### Design Patterns
- Container/Presenter pattern for separation of concerns
- Custom hooks for reusable logic
- Context API for component-wide state
- Render props for flexible composition
- Higher-order components for cross-cutting concerns`;
  }
  
  return `
### Service Architecture
\`\`\`
services/
├── ${storyDef.title.replace(/\s+/g, '')}/
│   ├── ${storyDef.title.replace(/\s+/g, '')}.service.ts
│   ├── ${storyDef.title.replace(/\s+/g, '')}.controller.ts
│   ├── ${storyDef.title.replace(/\s+/g, '')}.module.ts
│   ├── dto/
│   │   ├── create-${storyDef.title.toLowerCase().replace(/\s+/g, '-')}.dto.ts
│   │   └── update-${storyDef.title.toLowerCase().replace(/\s+/g, '-')}.dto.ts
│   └── entities/
│       └── ${storyDef.title.replace(/\s+/g, '')}.entity.ts
└── shared/
    ├── guards/
    ├── interceptors/
    └── decorators/
\`\`\`

### Design Patterns
- Repository pattern for data access
- Service layer for business logic
- DTO pattern for data validation
- Dependency injection for testability
- Event-driven architecture for decoupling`;
}

function generateComponentDesign(storyDef, epic) {
  if (!epic.isFrontend) {
    return 'N/A - Backend service story';
  }
  
  return `
### Main Component
\`\`\`tsx
interface ${storyDef.title.replace(/\s+/g, '')}Props {
  data: DataType[];
  onAction: (id: string) => void;
  config?: ConfigType;
  className?: string;
}

export const ${storyDef.title.replace(/\s+/g, '')}: React.FC<${storyDef.title.replace(/\s+/g, '')}Props> = ({
  data,
  onAction,
  config = defaultConfig,
  className
}) => {
  // Component implementation
};
\`\`\`

### State Structure
\`\`\`typescript
interface ${storyDef.title.replace(/\s+/g, '')}State {
  loading: boolean;
  error: Error | null;
  data: DataType[];
  filters: FilterType;
  pagination: PaginationType;
  selection: string[];
}
\`\`\`

### Component Hierarchy
- ${storyDef.title.replace(/\s+/g, '')} (Container)
  - Header
    - Title
    - Actions
  - Content
    - List/Grid View
    - Item Components
  - Footer
    - Pagination
    - Summary`;
}

function generateDataFlow(storyDef, epic) {
  return `
### Data Flow Diagram
\`\`\`
User Action → Component Event Handler → Service Layer → API Call → Backend
     ↑                                                                ↓
     ←──────────── State Update ←── Data Processing ←── Response ───┘
\`\`\`

### State Updates
1. User initiates action (click, type, scroll)
2. Event handler processes action
3. Service method called with parameters
4. API request sent to backend
5. Response processed and validated
6. State updated with new data
7. Components re-render with updated props

### Data Caching Strategy
- Use React Query for server state management
- Implement optimistic updates for better UX
- Cache invalidation on mutations
- Background refetching for fresh data
- Stale-while-revalidate pattern`;
}

function generateAPIDesign(storyDef, epic) {
  if (epic.isFrontend) {
    return `
### API Client Methods
\`\`\`typescript
class ${storyDef.title.replace(/\s+/g, '')}API {
  async getAll(params: QueryParams): Promise<PagedResponse<DataType>> {
    return this.http.get('/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}', { params });
  }
  
  async getById(id: string): Promise<DataType> {
    return this.http.get(\`/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/\${id}\`);
  }
  
  async create(data: CreateDTO): Promise<DataType> {
    return this.http.post('/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}', data);
  }
  
  async update(id: string, data: UpdateDTO): Promise<DataType> {
    return this.http.patch(\`/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/\${id}\`, data);
  }
  
  async delete(id: string): Promise<void> {
    return this.http.delete(\`/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/\${id}\`);
  }
}
\`\`\``;
  }
  
  return `
### REST Endpoints
\`\`\`
GET    /api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}
GET    /api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/:id
POST   /api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}
PATCH  /api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/:id
DELETE /api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/:id
\`\`\`

### GraphQL Schema
\`\`\`graphql
type ${storyDef.title.replace(/\s+/g, '')} {
  id: ID!
  createdAt: DateTime!
  updatedAt: DateTime!
  # Additional fields
}

type Query {
  ${storyDef.title.toLowerCase().replace(/\s+/g, '')}s(
    filter: ${storyDef.title.replace(/\s+/g, '')}Filter
    pagination: PaginationInput
  ): ${storyDef.title.replace(/\s+/g, '')}Connection!
  
  ${storyDef.title.toLowerCase().replace(/\s+/g, '')}(id: ID!): ${storyDef.title.replace(/\s+/g, '')}
}

type Mutation {
  create${storyDef.title.replace(/\s+/g, '')}(
    input: Create${storyDef.title.replace(/\s+/g, '')}Input!
  ): ${storyDef.title.replace(/\s+/g, '')}!
  
  update${storyDef.title.replace(/\s+/g, '')}(
    id: ID!
    input: Update${storyDef.title.replace(/\s+/g, '')}Input!
  ): ${storyDef.title.replace(/\s+/g, '')}!
  
  delete${storyDef.title.replace(/\s+/g, '')}(id: ID!): Boolean!
}
\`\`\``;
}

function generateStateManagement(storyDef, epic) {
  if (!epic.isFrontend) {
    return 'N/A - Backend service story';
  }
  
  return `
### Local State Management
\`\`\`typescript
// Using React hooks for local state
const [state, setState] = useState<${storyDef.title.replace(/\s+/g, '')}State>(initialState);
const [filters, setFilters] = useState<FilterState>(defaultFilters);
const [selection, setSelection] = useState<Set<string>>(new Set());

// Derived state using useMemo
const filteredData = useMemo(() => 
  applyFilters(state.data, filters), 
  [state.data, filters]
);
\`\`\`

### Global State Integration
\`\`\`typescript
// Using Zustand for global state
interface ${storyDef.title.replace(/\s+/g, '')}Store {
  items: DataType[];
  loading: boolean;
  error: Error | null;
  
  // Actions
  fetchItems: (params?: QueryParams) => Promise<void>;
  addItem: (item: DataType) => void;
  updateItem: (id: string, updates: Partial<DataType>) => void;
  deleteItem: (id: string) => void;
}

const use${storyDef.title.replace(/\s+/g, '')}Store = create<${storyDef.title.replace(/\s+/g, '')}Store>((set, get) => ({
  // Implementation
}));
\`\`\`

### State Persistence
- Local storage for user preferences
- Session storage for temporary state
- IndexedDB for offline data cache
- URL state for shareable views`;
}

function generatePhase1Steps(storyDef, epic) {
  return `
1. **Environment Setup**
   - [ ] Set up development environment
   - [ ] Install required dependencies
   - [ ] Configure build tools and linters
   - [ ] Set up testing framework
   - [ ] Create initial file structure

2. **Initial Implementation**
   - [ ] Create base component/service structure
   - [ ] Implement core interfaces and types
   - [ ] Set up basic routing (if applicable)
   - [ ] Create initial tests
   - [ ] Implement error boundaries

3. **Data Layer**
   - [ ] Define data models
   - [ ] Create mock data for development
   - [ ] Implement data fetching logic
   - [ ] Set up data validation
   - [ ] Create data transformation utilities`;
}

function generatePhase2Steps(storyDef, epic) {
  return `
1. **Core Feature Development**
   - [ ] Implement main functionality
   - [ ] Create UI components (if frontend)
   - [ ] Implement business logic
   - [ ] Add form validation
   - [ ] Handle edge cases

2. **Integration**
   - [ ] Connect to API endpoints
   - [ ] Implement authentication/authorization
   - [ ] Set up real-time updates (if needed)
   - [ ] Add logging and monitoring
   - [ ] Integrate with existing services

3. **State Management**
   - [ ] Implement state management solution
   - [ ] Add optimistic updates
   - [ ] Handle loading and error states
   - [ ] Implement caching strategy
   - [ ] Add state persistence`;
}

function generatePhase3Steps(storyDef, epic) {
  return `
1. **Testing Implementation**
   - [ ] Write comprehensive unit tests
   - [ ] Create integration tests
   - [ ] Implement E2E test scenarios
   - [ ] Add performance tests
   - [ ] Test error scenarios

2. **Optimization**
   - [ ] Optimize bundle size
   - [ ] Implement code splitting
   - [ ] Add lazy loading
   - [ ] Optimize API calls
   - [ ] Improve render performance

3. **Polish and Refinement**
   - [ ] Fine-tune UI/UX
   - [ ] Add animations and transitions
   - [ ] Implement keyboard shortcuts
   - [ ] Add helpful tooltips
   - [ ] Ensure mobile responsiveness`;
}

function generatePhase4Steps(storyDef, epic) {
  return `
1. **Quality Assurance**
   - [ ] Conduct thorough QA testing
   - [ ] Fix identified bugs
   - [ ] Verify acceptance criteria
   - [ ] Performance testing
   - [ ] Security review

2. **Documentation**
   - [ ] Write user documentation
   - [ ] Create developer guides
   - [ ] Document API changes
   - [ ] Update system diagrams
   - [ ] Create troubleshooting guide

3. **Deployment Preparation**
   - [ ] Create deployment scripts
   - [ ] Set up monitoring alerts
   - [ ] Prepare rollback plan
   - [ ] Update configuration
   - [ ] Final code review`;
}

function generateDependencies(storyDef, epic) {
  const commonDeps = `
### NPM Dependencies
\`\`\`json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.0",
    "date-fns": "^2.30.0",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@testing-library/react": "^14.0.0",
    "vitest": "^1.0.0",
    "typescript": "^5.0.0"
  }
}
\`\`\``;

  const backendDeps = `
### NPM Dependencies
\`\`\`json
{
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "class-validator": "^0.14.0",
    "prisma": "^5.0.0",
    "@prisma/client": "^5.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "jest": "^29.0.0",
    "typescript": "^5.0.0"
  }
}
\`\`\``;

  return (epic.isFrontend ? commonDeps : backendDeps) + `

### Internal Dependencies
- Authentication service for user context
- Logging service for audit trails
- Configuration service for environment settings
- Event bus for component communication
- Shared UI component library`;
}

function generateInterfaces(storyDef, epic) {
  return `
### TypeScript Interfaces
\`\`\`typescript
// Domain models
export interface ${storyDef.title.replace(/\s+/g, '')}Model {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  // Additional fields
}

// API contracts
export interface Create${storyDef.title.replace(/\s+/g, '')}Request {
  // Request fields
}

export interface ${storyDef.title.replace(/\s+/g, '')}Response {
  data: ${storyDef.title.replace(/\s+/g, '')}Model;
  meta?: ResponseMeta;
}

// Component props
export interface ${storyDef.title.replace(/\s+/g, '')}Props {
  data?: ${storyDef.title.replace(/\s+/g, '')}Model[];
  loading?: boolean;
  error?: Error;
  onAction?: (action: Action) => void;
}
\`\`\`

### Service Interfaces
\`\`\`typescript
export interface I${storyDef.title.replace(/\s+/g, '')}Service {
  findAll(params: QueryParams): Promise<PagedResult<${storyDef.title.replace(/\s+/g, '')}Model>>;
  findOne(id: string): Promise<${storyDef.title.replace(/\s+/g, '')}Model>;
  create(data: CreateDTO): Promise<${storyDef.title.replace(/\s+/g, '')}Model>;
  update(id: string, data: UpdateDTO): Promise<${storyDef.title.replace(/\s+/g, '')}Model>;
  delete(id: string): Promise<void>;
}
\`\`\``;
}

function generateConfiguration(storyDef, epic) {
  return `
### Environment Configuration
\`\`\`typescript
export const ${storyDef.title.replace(/\s+/g, '')}Config = {
  // API endpoints
  apiBaseUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000',
  apiTimeout: parseInt(process.env.REACT_APP_API_TIMEOUT || '30000'),
  
  // Feature flags
  enableBetaFeatures: process.env.REACT_APP_ENABLE_BETA === 'true',
  enableDebugMode: process.env.NODE_ENV === 'development',
  
  // Performance settings
  pageSizeDefault: 20,
  pageSizeMax: 100,
  cacheTimeout: 5 * 60 * 1000, // 5 minutes
  
  // UI settings
  animationDuration: 300,
  debounceDelay: 500,
  toastDuration: 5000,
};
\`\`\`

### Feature Toggles
\`\`\`typescript
export const FeatureFlags = {
  ${storyDef.title.toLowerCase().replace(/\s+/g, '_')}_enabled: true,
  ${storyDef.title.toLowerCase().replace(/\s+/g, '_')}_beta_ui: false,
  ${storyDef.title.toLowerCase().replace(/\s+/g, '_')}_advanced_filters: true,
  ${storyDef.title.toLowerCase().replace(/\s+/g, '_')}_export_feature: false,
};
\`\`\``;
}

function generateSecurity(storyDef, epic) {
  return `
### Authentication & Authorization
- Implement JWT token validation for all protected endpoints
- Role-based access control (RBAC) for feature access
- API key authentication for service-to-service communication
- Session timeout handling with automatic renewal

### Input Validation
\`\`\`typescript
// Frontend validation
const validateInput = (data: any): ValidationResult => {
  const errors: ValidationError[] = [];
  
  if (!data.requiredField) {
    errors.push({ field: 'requiredField', message: 'This field is required' });
  }
  
  if (data.email && !isValidEmail(data.email)) {
    errors.push({ field: 'email', message: 'Invalid email format' });
  }
  
  return { isValid: errors.length === 0, errors };
};

// Backend validation using class-validator
export class Create${storyDef.title.replace(/\s+/g, '')}Dto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(255)
  name: string;
  
  @IsEmail()
  @IsOptional()
  email?: string;
}
\`\`\`

### Security Headers
- Content Security Policy (CSP) implementation
- X-Frame-Options to prevent clickjacking
- X-Content-Type-Options to prevent MIME sniffing
- Strict-Transport-Security for HTTPS enforcement

### Data Protection
- Encrypt sensitive data at rest
- Use HTTPS for all data in transit
- Implement rate limiting to prevent abuse
- Sanitize all user inputs to prevent XSS
- Use parameterized queries to prevent SQL injection`;
}

function generatePerformance(storyDef, epic) {
  return `
### Performance Metrics
- **Page Load Time**: < 2 seconds on 3G connection
- **Time to Interactive**: < 3 seconds
- **API Response Time**: < 200ms for simple queries
- **Memory Usage**: < 50MB for typical session
- **CPU Usage**: < 30% during normal operation

### Optimization Strategies
1. **Code Splitting**
   - Lazy load routes and heavy components
   - Dynamic imports for optional features
   - Separate vendor bundles

2. **Caching Strategy**
   - Browser cache for static assets
   - Service worker for offline support
   - Redis cache for API responses
   - React Query for client-side cache

3. **Rendering Optimization**
   - Virtual scrolling for large lists
   - React.memo for expensive components
   - useMemo/useCallback for computed values
   - Debounce/throttle event handlers

### Performance Budget
\`\`\`json
{
  "bundles": {
    "main": { "maxSize": "200kb" },
    "vendor": { "maxSize": "300kb" },
    "polyfills": { "maxSize": "50kb" }
  },
  "assets": {
    "images": { "maxSize": "100kb" },
    "fonts": { "maxSize": "200kb" }
  }
}
\`\`\``;
}

function generateUnitTests(storyDef, epic) {
  return `
### Component Unit Tests
\`\`\`typescript
describe('${storyDef.title}', () => {
  it('should render without crashing', () => {
    render(<${storyDef.title.replace(/\s+/g, '')} />);
    expect(screen.getByTestId('${storyDef.title.toLowerCase().replace(/\s+/g, '-')}')).toBeInTheDocument();
  });
  
  it('should display loading state', () => {
    render(<${storyDef.title.replace(/\s+/g, '')} loading={true} />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });
  
  it('should handle user interactions', async () => {
    const onAction = jest.fn();
    render(<${storyDef.title.replace(/\s+/g, '')} onAction={onAction} />);
    
    const button = screen.getByRole('button');
    await userEvent.click(button);
    
    expect(onAction).toHaveBeenCalledTimes(1);
  });
});
\`\`\`

### Service Unit Tests
\`\`\`typescript
describe('${storyDef.title}Service', () => {
  let service: ${storyDef.title.replace(/\s+/g, '')}Service;
  
  beforeEach(() => {
    service = new ${storyDef.title.replace(/\s+/g, '')}Service();
  });
  
  it('should fetch data successfully', async () => {
    const result = await service.findAll();
    expect(result).toBeDefined();
    expect(Array.isArray(result.data)).toBe(true);
  });
  
  it('should handle errors gracefully', async () => {
    jest.spyOn(service, 'findAll').mockRejectedValue(new Error('Network error'));
    
    await expect(service.findAll()).rejects.toThrow('Network error');
  });
});
\`\`\``;
}

function generateIntegrationTests(storyDef, epic) {
  return `
### API Integration Tests
\`\`\`typescript
describe('${storyDef.title} API Integration', () => {
  it('should create and retrieve item', async () => {
    // Create item
    const createResponse = await request(app)
      .post('/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}')
      .send({ name: 'Test Item' })
      .expect(201);
    
    const { id } = createResponse.body;
    
    // Retrieve item
    const getResponse = await request(app)
      .get(\`/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/\${id}\`)
      .expect(200);
    
    expect(getResponse.body.name).toBe('Test Item');
  });
  
  it('should update item successfully', async () => {
    const { id } = await createTestItem();
    
    await request(app)
      .patch(\`/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}/\${id}\`)
      .send({ name: 'Updated Name' })
      .expect(200);
    
    const item = await getItem(id);
    expect(item.name).toBe('Updated Name');
  });
});
\`\`\`

### Component Integration Tests
\`\`\`typescript
describe('${storyDef.title} Component Integration', () => {
  it('should fetch and display data', async () => {
    render(<${storyDef.title.replace(/\s+/g, '')} />);
    
    // Wait for data to load
    await waitFor(() => {
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
    });
    
    // Verify data is displayed
    expect(screen.getByText('Test Item 1')).toBeInTheDocument();
    expect(screen.getByText('Test Item 2')).toBeInTheDocument();
  });
});
\`\`\``;
}

function generateE2ETests(storyDef, epic) {
  return `
### Playwright E2E Tests
\`\`\`typescript
test.describe('${storyDef.title} E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}');
  });
  
  test('should complete user workflow', async ({ page }) => {
    // Wait for page to load
    await page.waitForSelector('[data-testid="${storyDef.title.toLowerCase().replace(/\s+/g, '-')}"]');
    
    // Perform user actions
    await page.click('button[aria-label="Create New"]');
    await page.fill('input[name="title"]', 'Test Entry');
    await page.selectOption('select[name="category"]', 'option1');
    await page.click('button[type="submit"]');
    
    // Verify success
    await expect(page.locator('.success-message')).toContainText('Created successfully');
    await expect(page.locator('[data-testid="item-list"]')).toContainText('Test Entry');
  });
  
  test('should handle errors gracefully', async ({ page }) => {
    // Simulate network error
    await page.route('**/api/**', route => route.abort());
    
    await page.click('button[aria-label="Refresh"]');
    
    // Verify error handling
    await expect(page.locator('.error-message')).toBeVisible();
    await expect(page.locator('.error-message')).toContainText('Failed to load data');
  });
});
\`\`\`

### Mobile E2E Tests
\`\`\`typescript
test.describe('${storyDef.title} Mobile E2E', () => {
  test.use({ viewport: { width: 375, height: 667 } });
  
  test('should work on mobile devices', async ({ page }) => {
    await page.goto('/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}');
    
    // Test mobile-specific interactions
    await page.tap('[data-testid="mobile-menu"]');
    await page.tap('text=Create New');
    
    // Verify mobile layout
    await expect(page.locator('.mobile-layout')).toBeVisible();
  });
});
\`\`\``;
}

function generatePerformanceTests(storyDef, epic) {
  return `
### Load Testing with k6
\`\`\`javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],    // Error rate under 10%
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/v1/${storyDef.title.toLowerCase().replace(/\s+/g, '-')}');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
\`\`\`

### Frontend Performance Tests
\`\`\`typescript
describe('${storyDef.title} Performance', () => {
  it('should render large datasets efficiently', async () => {
    const startTime = performance.now();
    
    const { rerender } = render(
      <${storyDef.title.replace(/\s+/g, '')} data={generateLargeDataset(1000)} />
    );
    
    const initialRenderTime = performance.now() - startTime;
    expect(initialRenderTime).toBeLessThan(100); // Under 100ms
    
    // Test re-render performance
    const rerenderStart = performance.now();
    rerender(<${storyDef.title.replace(/\s+/g, '')} data={generateLargeDataset(1000)} />);
    const rerenderTime = performance.now() - rerenderStart;
    
    expect(rerenderTime).toBeLessThan(50); // Under 50ms for re-renders
  });
});
\`\`\``;
}

function generateMonitoring(storyDef, epic) {
  return `
### Metrics Collection
\`\`\`typescript
// Frontend metrics using Performance Observer
const observer = new PerformanceObserver((list) => {
  list.getEntries().forEach((entry) => {
    analytics.track('${storyDef.title.replace(/\s+/g, '')}_Performance', {
      name: entry.name,
      duration: entry.duration,
      startTime: entry.startTime,
    });
  });
});

observer.observe({ entryTypes: ['measure', 'navigation'] });
\`\`\`

### Custom Metrics
- **Feature Usage**: Track how often the feature is accessed
- **Error Rate**: Monitor client and server errors
- **Response Times**: Track API endpoint performance
- **User Interactions**: Count clicks, form submissions
- **Conversion Funnel**: Track user journey completion

### Logging Strategy
\`\`\`typescript
// Structured logging
logger.info('${storyDef.title} action performed', {
  userId: user.id,
  action: 'create',
  metadata: {
    itemId: item.id,
    timestamp: new Date().toISOString(),
    duration: performanceTimer.end(),
  },
});

// Error logging with context
logger.error('${storyDef.title} operation failed', {
  error: error.message,
  stack: error.stack,
  context: {
    userId: user.id,
    operation: 'update',
    payload: sanitizedPayload,
  },
});
\`\`\`

### Dashboards and Alerts
- Create Grafana dashboard for real-time metrics
- Set up alerts for error rate > 5%
- Monitor p95 response times
- Track memory and CPU usage
- Alert on unusual traffic patterns`;
}

function generateDocumentation(storyDef, epic) {
  return `
### User Documentation
1. **Getting Started Guide**
   - Feature overview and benefits
   - Step-by-step tutorials
   - Common use cases
   - Video walkthroughs

2. **API Documentation**
   - Endpoint descriptions
   - Request/response examples
   - Error codes and handling
   - Rate limiting information

3. **Administrator Guide**
   - Configuration options
   - Troubleshooting steps
   - Performance tuning
   - Backup and recovery

### Developer Documentation
\`\`\`markdown
# ${storyDef.title} Developer Guide

## Architecture Overview
[Include system diagrams and component relationships]

## Setup Instructions
1. Install dependencies: \`npm install\`
2. Configure environment variables
3. Run development server: \`npm run dev\`

## Code Examples
[Provide comprehensive examples for common tasks]

## Testing Guide
- Unit test patterns
- Integration test setup
- E2E test scenarios

## Deployment Guide
- Build process
- Environment configuration
- Monitoring setup
- Rollback procedures
\`\`\`

### API Documentation Example
\`\`\`yaml
openapi: 3.0.0
paths:
  /${storyDef.title.toLowerCase().replace(/\s+/g, '-')}:
    get:
      summary: List all ${storyDef.title.toLowerCase()}
      parameters:
        - name: page
          in: query
          schema:
            type: integer
        - name: limit
          in: query
          schema:
            type: integer
      responses:
        200:
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/${storyDef.title.replace(/\s+/g, '')}'
\`\`\``;
}

function generateRollout(storyDef, epic) {
  return `
### Phased Rollout Plan
1. **Phase 1 - Internal Testing (Week 1)**
   - Deploy to staging environment
   - Internal team testing
   - Performance baseline establishment
   - Bug fixes and optimizations

2. **Phase 2 - Beta Release (Week 2-3)**
   - Deploy to 5% of users
   - Monitor metrics and errors
   - Collect user feedback
   - Iterate based on findings

3. **Phase 3 - Gradual Rollout (Week 4-5)**
   - Increase to 25% of users
   - A/B testing with old version
   - Performance comparison
   - Feature usage analytics

4. **Phase 4 - Full Release (Week 6)**
   - Deploy to 100% of users
   - Deprecate old version
   - Monitor for issues
   - Document lessons learned

### Feature Flags Configuration
\`\`\`json
{
  "features": {
    "${storyDef.title.toLowerCase().replace(/\s+/g, '_')}": {
      "enabled": true,
      "rolloutPercentage": 100,
      "whitelist": ["beta-users"],
      "blacklist": [],
      "rules": [
        {
          "condition": "userRole",
          "operator": "in",
          "value": ["admin", "power-user"]
        }
      ]
    }
  }
}
\`\`\`

### Rollback Plan
1. Feature flag disable (immediate)
2. Revert deployment if critical
3. Database migration rollback scripts
4. Clear CDN and caches
5. Notify affected users`;
}

function generateDependenciesBlockers(storyDef, epic) {
  return `
### Dependencies
- **Authentication Service**: User context and permissions
- **Database Schema**: Tables must be created first
- **API Gateway**: Routes must be configured
- **Design System**: UI components must be available
- **Testing Infrastructure**: Test environment setup

### Potential Blockers
- [ ] Waiting for design approval
- [ ] API endpoints not yet implemented
- [ ] Third-party service integration pending
- [ ] Performance requirements not finalized
- [ ] Security review not scheduled

### Mitigation Strategies
1. **Design Delays**: Use placeholder UI with feature flags
2. **API Dependencies**: Create mock services for development
3. **Third-party Services**: Build abstraction layer for easy swapping
4. **Performance Issues**: Start with basic implementation, optimize later
5. **Security Concerns**: Engage security team early in process`;
}

function generateRelatedStories(storyDef, epic) {
  const epicNum = epic.id.replace(/[AB]/, '');
  const suffix = epic.isFrontend ? 'A' : epic.isBackend ? 'B' : '';
  
  return `
### Prerequisite Stories
- [STORY-${epicNum}${suffix}-000]: Initial setup and configuration
- [STORY-COMMON-AUTH]: Authentication integration
- [STORY-COMMON-LOGGING]: Logging infrastructure

### Related Stories
- [STORY-${epicNum}${suffix}-002]: Related feature implementation
- [STORY-${epicNum}${suffix}-003]: Complementary functionality
- [STORY-${epicNum}${suffix}-004]: Extended features

### Follow-up Stories
- [STORY-${epicNum}${suffix}-006]: Performance optimization
- [STORY-${epicNum}${suffix}-007]: Advanced features
- [STORY-${epicNum}${suffix}-008]: Mobile optimizations`;
}

function generateNotes(storyDef, epic) {
  return `
### Implementation Notes
- Consider using virtualization for large data sets
- Implement progressive enhancement for better UX
- Use feature flags for gradual rollout
- Plan for internationalization from the start
- Consider accessibility requirements early

### Technical Debt Considerations
- Refactor legacy code touched by this story
- Update deprecated dependencies
- Improve test coverage in related areas
- Document any workarounds needed

### Future Enhancements
- Machine learning integration for smart features
- Real-time collaboration capabilities
- Advanced analytics and insights
- Mobile app integration
- Offline mode support`;
}

// Phase 3: Enhance stories
async function phase3EnhanceStories() {
  log('=== PHASE 3: Enhancing Stories to 800+ Lines ===');
  speak('Starting phase 3: Enhancing all stories with comprehensive technical content');
  
  const files = await fs.readdir(STORIES_DIR);
  const storyFiles = files.filter(f => f.startsWith('STORY-') && f.endsWith('.md'));
  
  let enhancedCount = 0;
  
  for (const file of storyFiles) {
    const storyPath = path.join(STORIES_DIR, file);
    const content = await fs.readFile(storyPath, 'utf-8');
    const lines = content.split('\n').length;
    
    if (lines < 800) {
      log(`Enhancing ${file} (current: ${lines} lines)`);
      
      // Re-generate with full content
      const storyId = file.replace('.md', '');
      const epicMatch = storyId.match(/STORY-(\d+[AB]?)/);
      if (epicMatch) {
        const epicId = epicMatch[1];
        const epicFile = `EPIC-${epicId.replace(/(\d+)([AB])/, '$1$2-')}.md`;
        const epicFiles = await fs.readdir(EPICS_DIR);
        const matchingEpic = epicFiles.find(f => f.includes(`EPIC-${epicId}`));
        
        if (matchingEpic) {
          const epic = await parseEpic(path.join(EPICS_DIR, matchingEpic));
          const storyDef = { id: storyId, title: extractTitleFromContent(content), type: 'feature' };
          const enhancedContent = await generateStoryContent(storyDef, epic);
          
          await fs.writeFile(storyPath, enhancedContent);
          enhancedCount++;
        }
      }
    }
  }
  
  log(`Phase 3 Complete: Enhanced ${enhancedCount} stories`);
  speak(`Phase 3 complete. Enhanced ${enhancedCount} stories to comprehensive technical specifications`);
}

// Extract title from story content
function extractTitleFromContent(content) {
  const titleMatch = content.match(/^#\s+STORY-\d+[AB]?(?:-\d+)?:\s+(.+)$/m);
  return titleMatch ? titleMatch[1] : 'Story Implementation';
}

// Phase 4: Update links
async function phase4UpdateLinks() {
  log('=== PHASE 4: Updating Links Between Epics and Stories ===');
  speak('Starting phase 4: Updating all links between epics and stories');
  
  const epicFiles = await fs.readdir(EPICS_DIR);
  const storyFiles = await fs.readdir(STORIES_DIR);
  
  let updatedCount = 0;
  
  // Update epic files with story links
  for (const epicFile of epicFiles.filter(f => f.startsWith('EPIC-') && f.endsWith('.md'))) {
    const epicPath = path.join(EPICS_DIR, epicFile);
    let content = await fs.readFile(epicPath, 'utf-8');
    const epic = await parseEpic(epicPath);
    
    // Find all stories for this epic
    const epicStories = storyFiles.filter(f => {
      const storyMatch = f.match(/STORY-(\d+[AB]?)/);
      const epicMatch = epic.id;
      return storyMatch && epicMatch && storyMatch[1].startsWith(epicMatch);
    });
    
    // Add stories section if not present
    if (!content.includes('## Stories')) {
      const storiesSection = `
## Stories

${epicStories.map(s => `- [${s.replace('.md', '')}](../stories/${s})`).join('\n')}
`;
      content += '\n' + storiesSection;
      await fs.writeFile(epicPath, content);
      updatedCount++;
    }
  }
  
  // Update story files with epic links
  for (const storyFile of storyFiles.filter(f => f.startsWith('STORY-') && f.endsWith('.md'))) {
    const storyPath = path.join(STORIES_DIR, storyFile);
    let content = await fs.readFile(storyPath, 'utf-8');
    
    // Extract epic reference
    const epicMatch = storyFile.match(/STORY-(\d+[AB]?)/);
    if (epicMatch) {
      const epicId = epicMatch[1];
      const epicFiles = await fs.readdir(EPICS_DIR);
      const matchingEpic = epicFiles.find(f => f.includes(`EPIC-${epicId}`));
      
      if (matchingEpic && !content.includes(`[${matchingEpic}]`)) {
        content = content.replace(
          /\*\*Epic\*\*:\s*\[.*?\]\(.*?\)/,
          `**Epic**: [${matchingEpic}](../epics/${matchingEpic})`
        );
        await fs.writeFile(storyPath, content);
        updatedCount++;
      }
    }
  }
  
  log(`Phase 4 Complete: Updated ${updatedCount} files with cross-references`);
  speak(`Phase 4 complete. Updated ${updatedCount} files with bidirectional links`);
}

// Phase 5: Validate and report
async function phase5ValidateAndReport() {
  log('=== PHASE 5: Validating and Generating Report ===');
  speak('Starting phase 5: Validating all epics and stories and generating comprehensive report');
  
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalEpics: 0,
      totalStories: 0,
      frontendEpics: 0,
      backendEpics: 0,
      infrastructureEpics: 0,
      storiesPerEpic: {},
      storyLineCount: {},
      validationIssues: []
    },
    epics: [],
    stories: []
  };
  
  // Analyze epics
  const epicFiles = await fs.readdir(EPICS_DIR);
  for (const file of epicFiles.filter(f => f.startsWith('EPIC-') && f.endsWith('.md') && !f.includes('SPLIT'))) {
    const epic = await parseEpic(path.join(EPICS_DIR, file));
    report.summary.totalEpics++;
    
    if (epic.isFrontend) report.summary.frontendEpics++;
    else if (epic.isBackend) report.summary.backendEpics++;
    else report.summary.infrastructureEpics++;
    
    report.epics.push({
      file: file,
      id: epic.id,
      title: epic.title,
      type: epic.type,
      storyCount: epic.stories.length,
      stories: epic.stories
    });
    
    report.summary.storiesPerEpic[epic.id] = epic.stories.length;
  }
  
  // Analyze stories
  const storyFiles = await fs.readdir(STORIES_DIR);
  for (const file of storyFiles.filter(f => f.startsWith('STORY-') && f.endsWith('.md'))) {
    const content = await fs.readFile(path.join(STORIES_DIR, file), 'utf-8');
    const lines = content.split('\n').length;
    
    report.summary.totalStories++;
    report.summary.storyLineCount[file] = lines;
    
    if (lines < 800) {
      report.summary.validationIssues.push({
        type: 'warning',
        file: file,
        issue: `Story has only ${lines} lines (target: 800+)`
      });
    }
    
    report.stories.push({
      file: file,
      lines: lines,
      hasEpicLink: content.includes('../epics/'),
      hasAcceptanceCriteria: content.includes('## Acceptance Criteria'),
      hasTechnicalSpecs: content.includes('## Technical Specifications')
    });
  }
  
  // Generate report file
  const reportContent = `# Epic and Story Harmonization Report

Generated: ${report.timestamp}

## Executive Summary

- **Total Epics**: ${report.summary.totalEpics}
  - Frontend Epics: ${report.summary.frontendEpics}
  - Backend Epics: ${report.summary.backendEpics}
  - Infrastructure Epics: ${report.summary.infrastructureEpics}
- **Total Stories**: ${report.summary.totalStories}
- **Average Lines per Story**: ${Math.round(Object.values(report.summary.storyLineCount).reduce((a, b) => a + b, 0) / report.summary.totalStories)}
- **Validation Issues**: ${report.summary.validationIssues.length}

## Epic Analysis

${report.epics.map(epic => `
### ${epic.file}
- **ID**: ${epic.id}
- **Title**: ${epic.title}
- **Type**: ${epic.type}
- **Stories**: ${epic.storyCount}
- **Story IDs**: ${epic.stories.join(', ')}
`).join('\n')}

## Story Analysis

### Line Count Distribution
- Stories with 800+ lines: ${Object.values(report.summary.storyLineCount).filter(l => l >= 800).length}
- Stories with 600-799 lines: ${Object.values(report.summary.storyLineCount).filter(l => l >= 600 && l < 800).length}
- Stories with <600 lines: ${Object.values(report.summary.storyLineCount).filter(l => l < 600).length}

### Quality Metrics
- Stories with epic links: ${report.stories.filter(s => s.hasEpicLink).length}/${report.summary.totalStories}
- Stories with acceptance criteria: ${report.stories.filter(s => s.hasAcceptanceCriteria).length}/${report.summary.totalStories}
- Stories with technical specs: ${report.stories.filter(s => s.hasTechnicalSpecs).length}/${report.summary.totalStories}

## Validation Issues

${report.summary.validationIssues.length === 0 ? 'No validation issues found! ✅' : report.summary.validationIssues.map(issue => 
  `- **${issue.type.toUpperCase()}**: ${issue.file} - ${issue.issue}`
).join('\n')}

## Recommendations

1. ${report.summary.validationIssues.length > 0 ? 'Address validation issues listed above' : 'Continue with implementation phase'}
2. Review epic-story mappings for completeness
3. Ensure all stories have comprehensive technical specifications
4. Validate acceptance criteria with stakeholders
5. Begin sprint planning with high-priority stories

## Next Steps

1. Commit all changes to version control
2. Share report with team for review
3. Create Jira/Azure DevOps items from stories
4. Begin implementation of highest priority stories
5. Set up continuous validation pipeline
`;
  
  await fs.writeFile(path.join(__dirname, '../harmonization-report.md'), reportContent);
  
  log(`Phase 5 Complete: Validation report generated`);
  log(`Total Epics: ${report.summary.totalEpics}, Total Stories: ${report.summary.totalStories}`);
  speak(`Phase 5 complete. Generated comprehensive validation report. Total epics: ${report.summary.totalEpics}, Total stories: ${report.summary.totalStories}`);
  
  return report;
}

// Main execution
async function main() {
  try {
    log('=== Starting Epic and Story Harmonization ===');
    speak('Starting epic and story harmonization process');
    
    // Create backup
    await createBackup();
    
    // Execute phases
    await phase1SplitEpics();
    await phase2CreateStories();
    await phase3EnhanceStories();
    await phase4UpdateLinks();
    const report = await phase5ValidateAndReport();
    
    log('=== Harmonization Complete ===');
    speak(`Harmonization complete! Created ${report.summary.totalStories} stories across ${report.summary.totalEpics} epics. Check harmonization report for details.`);
    
    console.log('\n✅ Harmonization completed successfully!');
    console.log(`📊 Created/Updated: ${report.summary.totalStories} stories across ${report.summary.totalEpics} epics`);
    console.log(`📄 Report saved to: harmonization-report.md`);
    console.log(`💾 Backup saved to: ${BACKUP_DIR}`);
    
  } catch (error) {
    log(`ERROR: ${error.message}`, 'ERROR');
    console.error('❌ Harmonization failed:', error);
    speak('Harmonization failed. Check logs for details.');
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { main };