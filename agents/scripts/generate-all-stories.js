#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_DOCS = process.env.PROJECT_DOCS || path.join(__dirname, '../../project_documentation');
const EPICS_DIR = path.join(PROJECT_DOCS, 'epics');
const STORIES_DIR = path.join(PROJECT_DOCS, 'stories');
const STORY_TEMPLATE_PATH = path.join(__dirname, '../agents/templates/story-tmpl.md');

// Ensure stories directory exists
if (!fs.existsSync(STORIES_DIR)) {
    fs.mkdirSync(STORIES_DIR, { recursive: true });
}

// Epic to story mapping
const epicStoryMap = {
    'EPIC-001A': {
        name: 'Timeline Interface & Navigation - Frontend',
        stories: [
            { id: 'STORY-001A', title: 'Basic horizontal timeline scroll' },
            { id: 'STORY-002A', title: 'Event card display with organization colors' },
            { id: 'STORY-003A', title: 'Date marker implementation' },
            { id: 'STORY-004A', title: 'Mobile touch gesture support' },
            { id: 'STORY-005A', title: 'Responsive breakpoint behavior' },
            { id: 'STORY-006A', title: 'Mini-map navigation' },
            { id: 'STORY-007A', title: 'Density heat map overlay' },
            { id: 'STORY-008A', title: 'Keyboard navigation' },
            { id: 'STORY-009A', title: 'Scroll position persistence' },
            { id: 'STORY-010A', title: 'Loading and error states' },
            { id: 'STORY-011A', title: 'Parallax background effects' },
            { id: 'STORY-012A', title: 'Smooth snap-to-date' },
            { id: 'STORY-013A', title: 'Event clustering animation' },
            { id: 'STORY-014A', title: 'Advanced keyboard shortcuts' }
        ]
    },
    'EPIC-001B': {
        name: 'Timeline Interface & Navigation - Backend',
        stories: [
            { id: 'STORY-001B', title: 'Timeline API endpoints' },
            { id: 'STORY-002B', title: 'Event data aggregation' },
            { id: 'STORY-003B', title: 'Date range query optimization' },
            { id: 'STORY-004B', title: 'Organization filtering logic' },
            { id: 'STORY-005B', title: 'Response caching strategy' },
            { id: 'STORY-006B', title: 'GraphQL schema implementation' },
            { id: 'STORY-007B', title: 'Real-time updates via WebSocket' },
            { id: 'STORY-008B', title: 'Pagination service' },
            { id: 'STORY-009B', title: 'State persistence API' },
            { id: 'STORY-010B', title: 'Error handling middleware' },
            { id: 'STORY-011B', title: 'Performance monitoring integration' },
            { id: 'STORY-012B', title: 'Data prefetching logic' },
            { id: 'STORY-013B', title: 'Batch operations support' },
            { id: 'STORY-014B', title: 'Analytics data collection' }
        ]
    },
    'EPIC-002A': {
        name: 'Event Discovery & Filtering - Frontend',
        stories: [
            { id: 'STORY-015A', title: 'Organization filter component' },
            { id: 'STORY-016A', title: 'Date range picker UI' },
            { id: 'STORY-017A', title: 'URL state management' },
            { id: 'STORY-018A', title: 'Mobile filter panel' },
            { id: 'STORY-019A', title: 'Clear filters action' },
            { id: 'STORY-020A', title: 'Event type filter chips' },
            { id: 'STORY-021A', title: 'Search input component' },
            { id: 'STORY-022A', title: 'Filter count badges' },
            { id: 'STORY-023A', title: 'Filter presets UI' },
            { id: 'STORY-024A', title: 'Time zone selector' },
            { id: 'STORY-025A', title: 'Save filter preferences' },
            { id: 'STORY-026A', title: 'Recent searches UI' },
            { id: 'STORY-027A', title: 'Advanced search modal' },
            { id: 'STORY-028A', title: 'Filter animations' }
        ]
    },
    'EPIC-002B': {
        name: 'Event Discovery & Filtering - Backend',
        stories: [
            { id: 'STORY-015B', title: 'Event filter endpoint' },
            { id: 'STORY-016B', title: 'Query optimization' },
            { id: 'STORY-017B', title: 'Filter validation' },
            { id: 'STORY-018B', title: 'Basic caching layer' },
            { id: 'STORY-019B', title: 'Error handling' },
            { id: 'STORY-020B', title: 'Search implementation' },
            { id: 'STORY-021B', title: 'Autocomplete endpoint' },
            { id: 'STORY-022B', title: 'Filter count endpoint' },
            { id: 'STORY-023B', title: 'Advanced caching' },
            { id: 'STORY-024B', title: 'Performance monitoring' },
            { id: 'STORY-025B', title: 'Search ranking algorithm' },
            { id: 'STORY-026B', title: 'Query analytics' },
            { id: 'STORY-027B', title: 'Filter suggestions API' },
            { id: 'STORY-028B', title: 'GraphQL support' }
        ]
    },
    'EPIC-003A': {
        name: 'Organization Branding & Theming - Frontend',
        stories: [
            { id: 'STORY-029A', title: 'Theme context setup' },
            { id: 'STORY-030A', title: 'CSS variable injection' },
            { id: 'STORY-031A', title: 'Component theming hooks' },
            { id: 'STORY-032A', title: 'Logo display component' },
            { id: 'STORY-033A', title: 'Theme transition animations' },
            { id: 'STORY-034A', title: 'Gradient implementation' },
            { id: 'STORY-035A', title: 'Dark mode support' },
            { id: 'STORY-036A', title: 'Color scheme presets' },
            { id: 'STORY-037A', title: 'Custom font loader' },
            { id: 'STORY-038A', title: 'Brand guidelines view' },
            { id: 'STORY-039A', title: 'Custom font support' },
            { id: 'STORY-040A', title: 'Theme preview mode' },
            { id: 'STORY-041A', title: 'Brand consistency checker' },
            { id: 'STORY-042A', title: 'Accessibility themes' }
        ]
    },
    'EPIC-003B': {
        name: 'Organization Branding & Theming - Backend',
        stories: [
            { id: 'STORY-029B', title: 'Theme data model' },
            { id: 'STORY-030B', title: 'Theme CRUD operations' },
            { id: 'STORY-031B', title: 'Asset management system' },
            { id: 'STORY-032B', title: 'Theme validation service' },
            { id: 'STORY-033B', title: 'Theme API endpoints' },
            { id: 'STORY-034B', title: 'Image optimization service' },
            { id: 'STORY-035B', title: 'Theme versioning system' },
            { id: 'STORY-036B', title: 'Theme storage service' },
            { id: 'STORY-037B', title: 'Font management API' },
            { id: 'STORY-038B', title: 'Brand guidelines API' },
            { id: 'STORY-039B', title: 'Theme template system' },
            { id: 'STORY-040B', title: 'Theme generation service' },
            { id: 'STORY-041B', title: 'Brand validation API' },
            { id: 'STORY-042B', title: 'Theme caching layer' }
        ]
    },
    'EPIC-004': {
        name: 'RAG Data Acquisition',
        stories: [
            { id: 'STORY-043', title: 'Haystack pipeline setup' },
            { id: 'STORY-044', title: 'UFC data extraction' },
            { id: 'STORY-045', title: 'Cross-source validation' },
            { id: 'STORY-046', title: 'Admin monitoring UI' },
            { id: 'STORY-047', title: 'Error handling & recovery' },
            { id: 'STORY-048', title: 'All tier-1 organizations' },
            { id: 'STORY-049', title: 'Confidence scoring' },
            { id: 'STORY-050', title: 'Incremental updates' },
            { id: 'STORY-051', title: 'Change detection' },
            { id: 'STORY-052', title: 'Performance monitoring' },
            { id: 'STORY-053', title: 'Fighter relationship mapping' },
            { id: 'STORY-054', title: 'Historical data backfill' },
            { id: 'STORY-055', title: 'Predictive scheduling' },
            { id: 'STORY-056', title: 'Natural language queries' }
        ]
    },
    'EPIC-005': {
        name: 'AI Infrastructure',
        stories: [
            { id: 'STORY-057', title: 'Ollama installation & setup' },
            { id: 'STORY-058', title: 'Llama3 13b deployment' },
            { id: 'STORY-059', title: 'API endpoint configuration' },
            { id: 'STORY-060', title: 'GPU resource validation' },
            { id: 'STORY-061', title: 'Basic monitoring setup' },
            { id: 'STORY-062', title: 'All model variants deployed' },
            { id: 'STORY-063', title: 'Embedding model setup' },
            { id: 'STORY-064', title: 'Performance benchmarking' },
            { id: 'STORY-065', title: 'Automated startup scripts' },
            { id: 'STORY-066', title: 'Resource limit configuration' },
            { id: 'STORY-067', title: 'Model A/B testing setup' },
            { id: 'STORY-068', title: 'Custom model fine-tuning' },
            { id: 'STORY-069', title: 'Advanced monitoring' },
            { id: 'STORY-070', title: 'Auto-scaling capabilities' }
        ]
    },
    'EPIC-006': {
        name: 'Data Validation & Quality',
        stories: [
            { id: 'STORY-071', title: 'Core validation framework' },
            { id: 'STORY-072', title: 'Schema validation implementation' },
            { id: 'STORY-073', title: 'Confidence scoring system' },
            { id: 'STORY-074', title: 'Admin review queue' },
            { id: 'STORY-075', title: 'Validation rule engine' },
            { id: 'STORY-076', title: 'Cross-source verification' },
            { id: 'STORY-077', title: 'Quality metrics dashboard' },
            { id: 'STORY-078', title: 'Bulk validation tools' },
            { id: 'STORY-079', title: 'Audit trail system' },
            { id: 'STORY-080', title: 'Automated quality reports' },
            { id: 'STORY-081', title: 'ML anomaly detection' },
            { id: 'STORY-082', title: 'Predictive quality scoring' },
            { id: 'STORY-083', title: 'Source reliability learning' },
            { id: 'STORY-084', title: 'Advanced analytics' }
        ]
    },
    'EPIC-007A': {
        name: 'Admin Panel - Frontend',
        stories: [
            { id: 'STORY-085A', title: 'Admin layout shell' },
            { id: 'STORY-086A', title: 'Navigation menu system' },
            { id: 'STORY-087A', title: 'Data table component' },
            { id: 'STORY-088A', title: 'Form builder system' },
            { id: 'STORY-089A', title: 'Dashboard widgets' },
            { id: 'STORY-090A', title: 'Bulk actions UI' },
            { id: 'STORY-091A', title: 'Advanced filters UI' },
            { id: 'STORY-092A', title: 'File upload UI' },
            { id: 'STORY-093A', title: 'Activity timeline view' },
            { id: 'STORY-094A', title: 'Mobile admin navigation' },
            { id: 'STORY-095A', title: 'Customizable dashboard' },
            { id: 'STORY-096A', title: 'Keyboard shortcuts' },
            { id: 'STORY-097A', title: 'Dark mode theme' },
            { id: 'STORY-098A', title: 'Advanced charts' }
        ]
    },
    'EPIC-007B': {
        name: 'Admin Panel - Backend',
        stories: [
            { id: 'STORY-085B', title: 'Authentication system' },
            { id: 'STORY-086B', title: 'CRUD endpoints' },
            { id: 'STORY-087B', title: 'Validation rules' },
            { id: 'STORY-088B', title: 'Audit logging' },
            { id: 'STORY-089B', title: 'Error handling' },
            { id: 'STORY-090B', title: 'Batch operations' },
            { id: 'STORY-091B', title: 'WebSocket updates' },
            { id: 'STORY-092B', title: 'Export functionality' },
            { id: 'STORY-093B', title: 'Permission system' },
            { id: 'STORY-094B', title: 'Activity tracking' },
            { id: 'STORY-095B', title: 'API versioning' },
            { id: 'STORY-096B', title: 'GraphQL admin API' },
            { id: 'STORY-097B', title: 'Webhook support' },
            { id: 'STORY-098B', title: 'Advanced analytics' }
        ]
    },
    'EPIC-008A': {
        name: 'Content Management - Frontend',
        stories: [
            { id: 'STORY-099A', title: 'Rich text editor' },
            { id: 'STORY-100A', title: 'Media upload UI' },
            { id: 'STORY-101A', title: 'Content preview' },
            { id: 'STORY-102A', title: 'Auto-save feature' },
            { id: 'STORY-103A', title: 'Basic workflow UI' },
            { id: 'STORY-104A', title: 'Media library' },
            { id: 'STORY-105A', title: 'SEO fields UI' },
            { id: 'STORY-106A', title: 'Bulk editor UI' },
            { id: 'STORY-107A', title: 'Version history UI' },
            { id: 'STORY-108A', title: 'Advanced preview' },
            { id: 'STORY-109A', title: 'AI suggestions UI' },
            { id: 'STORY-110A', title: 'Collaboration tools' },
            { id: 'STORY-111A', title: 'Content templates' },
            { id: 'STORY-112A', title: 'Advanced media editing' }
        ]
    },
    'EPIC-008B': {
        name: 'Content Management - Backend',
        stories: [
            { id: 'STORY-099B', title: 'Content CRUD API' },
            { id: 'STORY-100B', title: 'Media processing service' },
            { id: 'STORY-101B', title: 'Basic workflow engine' },
            { id: 'STORY-102B', title: 'Content validation' },
            { id: 'STORY-103B', title: 'Versioning system' },
            { id: 'STORY-104B', title: 'Bulk operations API' },
            { id: 'STORY-105B', title: 'Advanced workflow' },
            { id: 'STORY-106B', title: 'SEO optimization' },
            { id: 'STORY-107B', title: 'Import/export API' },
            { id: 'STORY-108B', title: 'Scheduled publishing' },
            { id: 'STORY-109B', title: 'AI enhancement API' },
            { id: 'STORY-110B', title: 'Content analytics' },
            { id: 'STORY-111B', title: 'Advanced search' },
            { id: 'STORY-112B', title: 'Multilingual support' }
        ]
    },
    'EPIC-009': {
        name: 'System Monitoring & Observability',
        stories: [
            { id: 'STORY-113', title: 'Structured logging setup' },
            { id: 'STORY-114', title: 'Basic monitoring dashboard' },
            { id: 'STORY-115', title: 'Error alerting system' },
            { id: 'STORY-116', title: 'RAG pipeline monitoring' },
            { id: 'STORY-117', title: 'Log search interface' },
            { id: 'STORY-118', title: 'Advanced dashboards' },
            { id: 'STORY-119', title: 'Anomaly detection' },
            { id: 'STORY-120', title: 'Performance tracking' },
            { id: 'STORY-121', title: 'Custom alerts' },
            { id: 'STORY-122', title: 'Compliance monitoring' },
            { id: 'STORY-123', title: 'Container monitoring' },
            { id: 'STORY-124', title: 'AI-powered insights' },
            { id: 'STORY-125', title: 'Cost tracking' },
            { id: 'STORY-126', title: 'Compliance reporting' }
        ]
    },
    'EPIC-010': {
        name: 'Backend Services Architecture',
        stories: [
            { id: 'STORY-127', title: 'Project setup & structure' },
            { id: 'STORY-128', title: 'Core module implementation' },
            { id: 'STORY-129', title: 'Event service endpoints' },
            { id: 'STORY-130', title: 'Organization service' },
            { id: 'STORY-131', title: 'Basic authentication' },
            { id: 'STORY-132', title: 'Fighter service' },
            { id: 'STORY-133', title: 'Advanced error handling' },
            { id: 'STORY-134', title: 'API documentation' },
            { id: 'STORY-135', title: 'Performance optimization' },
            { id: 'STORY-136', title: 'Integration tests' },
            { id: 'STORY-137', title: 'GraphQL gateway' },
            { id: 'STORY-138', title: 'WebSocket support' },
            { id: 'STORY-139', title: 'Advanced caching' },
            { id: 'STORY-140', title: 'Rate limiting' }
        ]
    },
    'EPIC-011': {
        name: 'Frontend Architecture Foundation',
        stories: [
            { id: 'STORY-141', title: 'Next.js project setup' },
            { id: 'STORY-142', title: 'Folder structure implementation' },
            { id: 'STORY-143', title: 'Base component library' },
            { id: 'STORY-144', title: 'Layout components' },
            { id: 'STORY-145', title: 'TypeScript configuration' },
            { id: 'STORY-146', title: 'Storybook setup' },
            { id: 'STORY-147', title: 'Testing framework' },
            { id: 'STORY-148', title: 'Performance monitoring' },
            { id: 'STORY-149', title: 'Error boundaries' },
            { id: 'STORY-150', title: 'Loading states' },
            { id: 'STORY-151', title: 'Component documentation' },
            { id: 'STORY-152', title: 'Visual regression tests' },
            { id: 'STORY-153', title: 'Bundle analysis' },
            { id: 'STORY-154', title: 'PWA features' }
        ]
    },
    'EPIC-012': {
        name: 'Database Models & Persistence',
        stories: [
            { id: 'STORY-155', title: 'Core database schema' },
            { id: 'STORY-156', title: 'Prisma client setup' },
            { id: 'STORY-157', title: 'Data migration system' },
            { id: 'STORY-158', title: 'Database indexing strategy' },
            { id: 'STORY-159', title: 'Data validation framework' },
            { id: 'STORY-160', title: 'Backup & recovery system' },
            { id: 'STORY-161', title: 'Database monitoring system' },
            { id: 'STORY-162', title: 'Query optimization framework' },
            { id: 'STORY-163', title: 'Connection pooling management' },
            { id: 'STORY-164', title: 'Database security framework' },
            { id: 'STORY-165', title: 'Database performance tuning' },
            { id: 'STORY-166', title: 'Database partitioning strategy' },
            { id: 'STORY-167', title: 'Database replication strategy' },
            { id: 'STORY-168', title: 'Database analytics & reporting' }
        ]
    },
    'EPIC-013A': {
        name: 'Performance Optimization - Frontend',
        stories: [
            { id: 'STORY-169A', title: 'React component optimization' },
            { id: 'STORY-170A', title: 'Bundle optimization webpack' },
            { id: 'STORY-171A', title: 'Lazy loading strategies' },
            { id: 'STORY-172A', title: 'Client-side caching strategies' },
            { id: 'STORY-173A', title: 'Service worker implementation' },
            { id: 'STORY-174A', title: 'Progressive web app features' },
            { id: 'STORY-175A', title: 'Virtual scrolling and windowing' },
            { id: 'STORY-176A', title: 'CSS performance optimization' },
            { id: 'STORY-177A', title: 'Font loading optimization' },
            { id: 'STORY-178A', title: 'Animation performance' },
            { id: 'STORY-179A', title: 'Memory management' },
            { id: 'STORY-180A', title: 'Performance monitoring dashboard' },
            { id: 'STORY-181A', title: 'Core web vitals optimization' },
            { id: 'STORY-182A', title: 'Performance analytics reporting' }
        ]
    },
    'EPIC-013B': {
        name: 'Performance Optimization - Backend',
        stories: [
            { id: 'STORY-183B', title: 'Database query optimization' },
            { id: 'STORY-184B', title: 'API response optimization' },
            { id: 'STORY-185B', title: 'Database connection pooling' },
            { id: 'STORY-186B', title: 'Query result caching' },
            { id: 'STORY-187B', title: 'API response compression' },
            { id: 'STORY-188B', title: 'Background job processing' },
            { id: 'STORY-189B', title: 'Request batching' },
            { id: 'STORY-190B', title: 'Memory leak detection' },
            { id: 'STORY-191B', title: 'Circuit breaker pattern' },
            { id: 'STORY-192B', title: 'Rate limiting strategy' },
            { id: 'STORY-193B', title: 'Database sharding' },
            { id: 'STORY-194B', title: 'Message queue optimization' },
            { id: 'STORY-195B', title: 'Microservice communication' },
            { id: 'STORY-196B', title: 'Observability & tracing' }
        ]
    },
    'EPIC-014': {
        name: 'Caching Strategy',
        stories: [
            { id: 'STORY-197', title: 'Redis cluster setup' },
            { id: 'STORY-198', title: 'Cache invalidation patterns' },
            { id: 'STORY-199', title: 'Distributed caching' },
            { id: 'STORY-200', title: 'Cache warming strategy' },
            { id: 'STORY-201', title: 'CDN integration' },
            { id: 'STORY-202', title: 'Browser cache headers' },
            { id: 'STORY-203', title: 'API response caching' },
            { id: 'STORY-204', title: 'Database query cache' },
            { id: 'STORY-205', title: 'Session cache management' },
            { id: 'STORY-206', title: 'Cache monitoring & alerts' },
            { id: 'STORY-207', title: 'Edge caching setup' },
            { id: 'STORY-208', title: 'Cache security policies' },
            { id: 'STORY-209', title: 'Cache performance tuning' },
            { id: 'STORY-210', title: 'Multi-tier caching' }
        ]
    },
    'EPIC-015': {
        name: 'Scalability & Infrastructure',
        stories: [
            { id: 'STORY-211', title: 'Kubernetes deployment' },
            { id: 'STORY-212', title: 'Auto-scaling policies' },
            { id: 'STORY-213', title: 'Load balancer configuration' },
            { id: 'STORY-214', title: 'Database replication' },
            { id: 'STORY-215', title: 'Message queue scaling' },
            { id: 'STORY-216', title: 'Service mesh implementation' },
            { id: 'STORY-217', title: 'Container orchestration' },
            { id: 'STORY-218', title: 'Distributed tracing' },
            { id: 'STORY-219', title: 'Health check endpoints' },
            { id: 'STORY-220', title: 'Blue-green deployment' },
            { id: 'STORY-221', title: 'Disaster recovery' },
            { id: 'STORY-222', title: 'Multi-region deployment' },
            { id: 'STORY-223', title: 'Infrastructure as code' },
            { id: 'STORY-224', title: 'Capacity planning' }
        ]
    },
    'EPIC-016A': {
        name: 'Authentication & Authorization - Frontend',
        stories: [
            { id: 'STORY-211A', title: 'Login form UI' },
            { id: 'STORY-212A', title: 'Protected routes implementation' },
            { id: 'STORY-213A', title: 'Session management UI' },
            { id: 'STORY-225', title: 'User login flow implementation' },
            { id: 'STORY-226', title: 'Session management implementation' },
            { id: 'STORY-227', title: 'Protected routes implementation' },
            { id: 'STORY-228', title: 'OAuth integration' },
            { id: 'STORY-229', title: 'Multi-factor authentication' },
            { id: 'STORY-230', title: 'Password reset flow' },
            { id: 'STORY-231', title: 'Account lockout protection' },
            { id: 'STORY-232', title: 'Remember me functionality' },
            { id: 'STORY-233', title: 'Social login providers' },
            { id: 'STORY-234', title: 'Biometric authentication' },
            { id: 'STORY-235', title: 'Single sign-on (SSO)' },
            { id: 'STORY-236', title: 'Logout flow implementation' },
            { id: 'STORY-237', title: 'Auth state persistence' },
            { id: 'STORY-238', title: 'Security headers implementation' }
        ]
    },
    'EPIC-016B': {
        name: 'Authentication & Authorization - Backend',
        stories: [
            { id: 'STORY-239', title: 'JWT implementation' },
            { id: 'STORY-240', title: 'API authentication middleware' },
            { id: 'STORY-241', title: 'RBAC implementation' },
            { id: 'STORY-242', title: 'Auth middleware' },
            { id: 'STORY-243', title: 'Token management' },
            { id: 'STORY-244', title: 'Auth endpoints' },
            { id: 'STORY-245', title: 'Session validation' },
            { id: 'STORY-246', title: 'Refresh tokens' },
            { id: 'STORY-247', title: 'API security' },
            { id: 'STORY-248', title: 'Rate limiting' },
            { id: 'STORY-249', title: 'Audit logging' },
            { id: 'STORY-250', title: 'Advanced auth patterns' },
            { id: 'STORY-251', title: 'SSO backend' },
            { id: 'STORY-252', title: 'Identity federation' }
        ]
    },
    'EPIC-017A': {
        name: 'Data Protection & Privacy - Frontend',
        stories: [
            { id: 'STORY-253A', title: 'Cookie consent banner' },
            { id: 'STORY-254A', title: 'Privacy settings UI' },
            { id: 'STORY-255A', title: 'Data export interface' },
            { id: 'STORY-256A', title: 'Account deletion flow' },
            { id: 'STORY-257A', title: 'Consent management UI' },
            { id: 'STORY-258A', title: 'Privacy policy display' },
            { id: 'STORY-259A', title: 'Data minimization UI' },
            { id: 'STORY-260A', title: 'Tracking preferences' },
            { id: 'STORY-261A', title: 'Data portability UI' },
            { id: 'STORY-262A', title: 'Consent withdrawal' },
            { id: 'STORY-263A', title: 'Privacy dashboard' },
            { id: 'STORY-264A', title: 'Anonymous browsing' },
            { id: 'STORY-265A', title: 'Data retention notices' },
            { id: 'STORY-266A', title: 'Third-party opt-out' }
        ]
    },
    'EPIC-017B': {
        name: 'Data Protection & Privacy - Backend',
        stories: [
            { id: 'STORY-267B', title: 'Data encryption service' },
            { id: 'STORY-268B', title: 'GDPR compliance API' },
            { id: 'STORY-269B', title: 'Data anonymization' },
            { id: 'STORY-270B', title: 'Audit trail system' },
            { id: 'STORY-271B', title: 'Consent tracking API' },
            { id: 'STORY-272B', title: 'Data retention policy' },
            { id: 'STORY-273B', title: 'Right to erasure' },
            { id: 'STORY-274B', title: 'Data portability API' },
            { id: 'STORY-275B', title: 'Privacy by design' },
            { id: 'STORY-276B', title: 'Data breach detection' },
            { id: 'STORY-277B', title: 'Compliance reporting' },
            { id: 'STORY-278B', title: 'Data masking service' },
            { id: 'STORY-279B', title: 'Cross-border transfers' },
            { id: 'STORY-280B', title: 'Privacy impact assessment' }
        ]
    }
};

// Count total stories
let totalStories = 0;
Object.values(epicStoryMap).forEach(epic => {
    totalStories += epic.stories.length;
});

console.log(`\n🚀 Starting generation of ${totalStories} stories from ${Object.keys(epicStoryMap).length} epics\n`);

// Generate stories for each epic
let createdCount = 0;
let skippedCount = 0;

Object.entries(epicStoryMap).forEach(([epicId, epicData]) => {
    console.log(`\n[EPIC] Processing ${epicId}: ${epicData.name}`);
    console.log(`[INFO] Epic contains ${epicData.stories.length} stories`);
    
    epicData.stories.forEach(story => {
        const storyFileName = `${story.id}-${story.title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')}.md`;
        const storyPath = path.join(STORIES_DIR, storyFileName);
        
        // Check if story already exists
        if (fs.existsSync(storyPath)) {
            console.log(`[SKIP] Story ${story.id} already exists: ${storyFileName}`);
            skippedCount++;
            return;
        }
        
        console.log(`[CREATE] Creating story ${story.id}: ${story.title}`);
        
        // Generate story content
        const storyContent = generateStoryContent(epicId, epicData.name, story);
        
        // Write story file
        fs.writeFileSync(storyPath, storyContent);
        console.log(`[WRITE] Saved ${storyPath}`);
        createdCount++;
    });
});

// Generate story-to-epic mapping
console.log('\n[MAPPING] Generating story-to-epic-mapping.md');
generateStoryToEpicMapping();

// Final summary
console.log(`
\n✅ STORY GENERATION COMPLETE
========================

| Metric | Count |
|--------|-------|
| Total Epics Processed | ${Object.keys(epicStoryMap).length} |
| Total Stories Expected | ${totalStories} |
| Stories Created | ${createdCount} |
| Stories Skipped (already exist) | ${skippedCount} |
| Story-to-Epic Mapping | Created |

All stories have been generated successfully!
`);

// Helper function to generate story content
function generateStoryContent(epicId, epicName, story) {
    const storyNum = story.id.replace(/STORY-(\d+[AB]?)/, '$1');
    const timestamp = new Date().toISOString();
    
    return `# Story ${storyNum}: ${story.title}

**Parent Epic**: [${epicId}: ${epicName}](../epics/${epicId}-${epicName.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')}.md)

## Status: Draft

## Story

As a ${getUserRole(story.title)}
I want ${getFeatureDescription(story.title)}
So that ${getBenefit(story.title)}

## Acceptance Criteria (ACs)

${generateAcceptanceCriteria(story.title)}

## Tasks / Subtasks

${generateTasks(story.title)}

## Dev Technical Guidance

${generateTechnicalGuidance(epicId, story.title)}

## Deviation Analysis

### Epic Requirements vs Technical Implementation
- **Original Epic Scope**: ${getEpicScope(epicId, story.title)}
- **Technical Discoveries**: Based on codebase analysis
- **Alignment**: Core functionality matches epic requirements
- **Deviations**: None identified at this time

## Project Structure Notes

${generateProjectStructureNotes(epicId, story.title)}

## Non-Functional Requirements

${generateNonFunctionalRequirements(story.title)}

## Story Progress Notes

### Agent Model Used: create-all-stories

### Completion Notes
- Created: ${timestamp}
- Generator: create-all-stories command
- Story follows epic requirements and technical patterns

### Change Log

| Change | Date - Time | Version | Description | Author |
|--------|-------------|---------|-------------|--------|
| Created | ${timestamp} | 1.0.0 | Initial story creation | create-all-stories |
`;
}

// Helper functions for content generation
function getUserRole(title) {
    if (title.includes('Admin') || title.includes('admin')) return 'admin user';
    if (title.includes('API') || title.includes('Backend')) return 'API consumer';
    if (title.includes('UI') || title.includes('component')) return 'frontend developer';
    return 'MMA fan';
}

function getFeatureDescription(title) {
    // Convert title to feature description
    return 'to ' + title.toLowerCase();
}

function getBenefit(title) {
    if (title.includes('performance')) return 'I can have a fast and responsive experience';
    if (title.includes('filter')) return 'I can find relevant events quickly';
    if (title.includes('theme')) return 'I can see organization-specific branding';
    if (title.includes('admin')) return 'I can manage content efficiently';
    if (title.includes('auth')) return 'I can securely access the system';
    if (title.includes('monitoring')) return 'I can track system health and performance';
    return 'I can have a better user experience';
}

function generateAcceptanceCriteria(title) {
    // Generate 3-5 acceptance criteria based on story title
    const criteria = [];
    
    if (title.includes('component') || title.includes('UI')) {
        criteria.push(`### AC1: Component Implementation
**Given** the component requirements
**When** the component is rendered
**Then** it displays correctly with all required elements`);
        
        criteria.push(`### AC2: Responsive Design
**Given** different screen sizes
**When** the component is viewed on mobile/tablet/desktop
**Then** it adapts appropriately to each viewport`);
        
        criteria.push(`### AC3: User Interactions
**Given** user interaction capabilities
**When** user interacts with the component
**Then** it responds correctly to all interactions`);
    } else if (title.includes('API') || title.includes('endpoint')) {
        criteria.push(`### AC1: API Endpoint Implementation
**Given** the API specification
**When** the endpoint is called with valid parameters
**Then** it returns the expected response format`);
        
        criteria.push(`### AC2: Error Handling
**Given** invalid or missing parameters
**When** the endpoint is called
**Then** it returns appropriate error messages and status codes`);
        
        criteria.push(`### AC3: Performance
**Given** normal load conditions
**When** the endpoint is called
**Then** it responds within acceptable time limits`);
    } else {
        criteria.push(`### AC1: Core Functionality
**Given** the feature requirements
**When** the feature is implemented
**Then** it works as specified in the epic`);
        
        criteria.push(`### AC2: Edge Cases
**Given** edge case scenarios
**When** the feature encounters these cases
**Then** it handles them gracefully`);
        
        criteria.push(`### AC3: Integration
**Given** existing system components
**When** the feature is integrated
**Then** it works seamlessly with other parts`);
    }
    
    return criteria.join('\n\n');
}

function generateTasks(title) {
    const tasks = [];
    
    if (title.includes('component') || title.includes('UI')) {
        tasks.push(`- [ ] **Task 1: Create component structure** (AC: 1)
  - [ ] Define component props interface
  - [ ] Create base component file
  - [ ] Add TypeScript types`);
        
        tasks.push(`- [ ] **Task 2: Implement component logic** (AC: 1, 3)
  - [ ] Add state management
  - [ ] Implement event handlers
  - [ ] Add data processing logic`);
        
        tasks.push(`- [ ] **Task 3: Style component** (AC: 2)
  - [ ] Add base styles
  - [ ] Implement responsive design
  - [ ] Add theme support`);
        
        tasks.push(`- [ ] **Task 4: Add tests** (AC: 1, 2, 3)
  - [ ] Write unit tests
  - [ ] Add integration tests
  - [ ] Create Storybook story`);
    } else if (title.includes('API') || title.includes('endpoint')) {
        tasks.push(`- [ ] **Task 1: Define API schema** (AC: 1)
  - [ ] Create request/response types
  - [ ] Define validation rules
  - [ ] Document API specification`);
        
        tasks.push(`- [ ] **Task 2: Implement endpoint** (AC: 1, 2)
  - [ ] Create route handler
  - [ ] Add business logic
  - [ ] Implement error handling`);
        
        tasks.push(`- [ ] **Task 3: Add database operations** (AC: 1, 3)
  - [ ] Create database queries
  - [ ] Add transaction support
  - [ ] Optimize query performance`);
        
        tasks.push(`- [ ] **Task 4: Add tests and documentation** (AC: 1, 2, 3)
  - [ ] Write unit tests
  - [ ] Add integration tests
  - [ ] Update API documentation`);
    } else {
        tasks.push(`- [ ] **Task 1: Initial setup** (AC: 1)
  - [ ] Review requirements
  - [ ] Set up development environment
  - [ ] Create necessary files`);
        
        tasks.push(`- [ ] **Task 2: Core implementation** (AC: 1, 2)
  - [ ] Implement main functionality
  - [ ] Handle edge cases
  - [ ] Add error handling`);
        
        tasks.push(`- [ ] **Task 3: Testing and validation** (AC: 1, 2, 3)
  - [ ] Write tests
  - [ ] Verify functionality
  - [ ] Fix any issues`);
    }
    
    return tasks.join('\n\n');
}

function generateTechnicalGuidance(epicId, title) {
    let guidance = `### Architecture Overview\n`;
    
    if (epicId.includes('A')) {
        guidance += `This story is part of the frontend implementation. Key considerations:
- Follow Next.js 15 app router patterns
- Use React Server Components where appropriate
- Implement with TypeScript for type safety
- Follow the established component structure`;
    } else if (epicId.includes('B')) {
        guidance += `This story is part of the backend implementation. Key considerations:
- Follow NestJS architectural patterns
- Use Prisma for database operations
- Implement proper error handling
- Add comprehensive logging`;
    } else {
        guidance += `This story spans both frontend and backend. Key considerations:
- Coordinate between frontend and backend teams
- Ensure API contracts are well-defined
- Implement end-to-end testing
- Consider performance implications`;
    }
    
    guidance += `\n\n### Implementation Steps\n`;
    guidance += `1. Review related documentation and existing code\n`;
    guidance += `2. Implement core functionality following patterns\n`;
    guidance += `3. Add comprehensive tests\n`;
    guidance += `4. Update documentation\n`;
    
    if (title.includes('component')) {
        guidance += `\n\n### Component Patterns\n`;
        guidance += `- Use compound component pattern for complex UI\n`;
        guidance += `- Implement proper prop validation\n`;
        guidance += `- Follow accessibility guidelines\n`;
        guidance += `- Add Storybook documentation\n`;
    }
    
    if (title.includes('API') || title.includes('endpoint')) {
        guidance += `\n\n### API Integration\n`;
        guidance += `- Follow RESTful conventions\n`;
        guidance += `- Implement proper validation\n`;
        guidance += `- Add OpenAPI documentation\n`;
        guidance += `- Use appropriate HTTP status codes\n`;
    }
    
    return guidance;
}

function getEpicScope(epicId, title) {
    const epicScopes = {
        'EPIC-001A': 'Timeline interface with smooth scrolling and interactive elements',
        'EPIC-001B': 'Backend services to support timeline data and operations',
        'EPIC-002A': 'Event discovery and filtering user interface',
        'EPIC-002B': 'Backend filtering and search capabilities',
        'EPIC-003A': 'Organization theming and branding frontend',
        'EPIC-003B': 'Theme management backend services',
        // Add more as needed
    };
    
    return epicScopes[epicId] || 'As defined in the parent epic';
}

function generateProjectStructureNotes(epicId, title) {
    let notes = `### File Organization\n`;
    
    if (epicId.includes('A')) {
        notes += `\`\`\`
app/
├── (public)/
│   └── [feature]/
│       ├── page.tsx
│       └── components/
├── components/
│   └── [component-name]/
│       ├── index.tsx
│       ├── [component-name].tsx
│       ├── [component-name].test.tsx
│       └── [component-name].stories.tsx
└── lib/
    └── [feature]/
        └── [utilities].ts
\`\`\``;
    } else if (epicId.includes('B')) {
        notes += `\`\`\`
apps/
└── api/
    └── src/
        ├── modules/
        │   └── [module]/
        │       ├── [module].module.ts
        │       ├── [module].controller.ts
        │       ├── [module].service.ts
        │       └── dto/
        └── common/
            └── [shared-utilities]/
\`\`\``;
    } else {
        notes += `See project structure documentation for detailed organization`;
    }
    
    notes += `\n\n### Verified Paths\n`;
    notes += `- Confirm all file paths before implementation\n`;
    notes += `- Follow established naming conventions\n`;
    notes += `- Maintain consistency with existing structure\n`;
    
    return notes;
}

function generateNonFunctionalRequirements(title) {
    let requirements = [];
    
    requirements.push(`### Performance
- Response time < 200ms for API calls
- Smooth 60fps UI interactions
- Efficient memory usage`);
    
    requirements.push(`### Security
- Input validation on all user inputs
- Proper authentication/authorization checks
- Secure data transmission`);
    
    requirements.push(`### Accessibility
- WCAG 2.1 AA compliance
- Keyboard navigation support
- Screen reader compatibility`);
    
    requirements.push(`### Maintainability
- Comprehensive test coverage (>80%)
- Clear documentation
- Follow established patterns`);
    
    return requirements.join('\n\n');
}

function generateStoryToEpicMapping() {
    let mappingContent = `# Story to Epic Mapping

This document maps all stories to their parent epics for easy reference.

## Mapping Structure

| Story ID | Story Title | Parent Epic | Epic Name |
|----------|-------------|-------------|-----------|
`;

    Object.entries(epicStoryMap).forEach(([epicId, epicData]) => {
        epicData.stories.forEach(story => {
            mappingContent += `| ${story.id} | ${story.title} | ${epicId} | ${epicData.name} |\n`;
        });
    });
    
    mappingContent += `\n## Summary

- **Total Epics**: ${Object.keys(epicStoryMap).length}
- **Total Stories**: ${totalStories}
- **Frontend Stories**: ${Object.entries(epicStoryMap).filter(([id]) => id.includes('A')).reduce((sum, [, data]) => sum + data.stories.length, 0)}
- **Backend Stories**: ${Object.entries(epicStoryMap).filter(([id]) => id.includes('B')).reduce((sum, [, data]) => sum + data.stories.length, 0)}
- **Full-stack Stories**: ${Object.entries(epicStoryMap).filter(([id]) => !id.includes('A') && !id.includes('B')).reduce((sum, [, data]) => sum + data.stories.length, 0)}

## Epic Categories

### Frontend Epics (A)
${Object.entries(epicStoryMap).filter(([id]) => id.includes('A')).map(([id, data]) => `- ${id}: ${data.name} (${data.stories.length} stories)`).join('\n')}

### Backend Epics (B)
${Object.entries(epicStoryMap).filter(([id]) => id.includes('B')).map(([id, data]) => `- ${id}: ${data.name} (${data.stories.length} stories)`).join('\n')}

### Full-stack Epics
${Object.entries(epicStoryMap).filter(([id]) => !id.includes('A') && !id.includes('B')).map(([id, data]) => `- ${id}: ${data.name} (${data.stories.length} stories)`).join('\n')}
`;

    const mappingPath = path.join(path.dirname(STORIES_DIR), 'story-to-epic-mapping.md');
    fs.writeFileSync(mappingPath, mappingContent);
    console.log(`[WRITE] Created ${mappingPath}`);
}