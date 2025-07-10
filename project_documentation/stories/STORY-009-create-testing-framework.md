# Story 1.9: Create Testing Framework

## Story ID: STORY-009
## Epic: EPIC-001 - AP Method Subtask Integration
## Priority: Critical
## Story Points: 13

---

## User Story

**As a** Quality Assurance Engineer  
**I want** a comprehensive, automated testing framework that validates every aspect of the task integration system  
**So that** we can guarantee 99.99% reliability, catch regressions within minutes, and enable confident continuous deployment

---

## Acceptance Criteria

1. **Given** a code change is committed **When** the test suite runs **Then** all unit, integration, and E2E tests complete within 10 minutes with detailed reporting
2. **Given** a test failure occurs **When** the CI pipeline runs **Then** developers receive immediate notification with actionable diagnostics and reproduction steps
3. **Given** the system is under load **When** performance tests execute **Then** response times remain within SLA and resource usage stays below thresholds
4. **Given** a new feature is added **When** coverage is calculated **Then** test coverage remains above 90% with no untested critical paths
5. **Given** a production issue occurs **When** investigating **Then** the test framework provides replay capability with exact state reproduction
6. **Given** multiple test runs occur **When** analyzing results **Then** flaky tests are automatically detected and quarantined

---

## Definition of Done

- [ ] All acceptance criteria met with automated validation
- [ ] Test framework achieves 95%+ self-test coverage
- [ ] Performance tests establish baselines for all operations
- [ ] Chaos testing validates error recovery paths
- [ ] Documentation includes video tutorials
- [ ] CI/CD integration runs on every commit
- [ ] Test data generation automated
- [ ] Security testing integrated
- [ ] Accessibility testing included
- [ ] Framework adopted by all teams

---

## Technical Requirements

### Dependencies

- [ ] Prerequisite Story: 1.7 - Developer Integration (Completed)
- [ ] Prerequisite Story: 1.8 - Task Tracking Hooks (Must be completed)
- [ ] Technical Dependency: Jest/Vitest for unit testing
- [ ] Technical Dependency: Playwright for E2E testing
- [ ] External Dependency: CI/CD platform (GitHub Actions/Jenkins)

### Technical Notes

Testing framework requirements:
- Parallel test execution for speed
- Deterministic test ordering
- Isolated test environments
- Real-time test result streaming
- Visual regression testing
- Contract testing between services
- Mutation testing for quality
- Property-based testing for edge cases

### API/Service Requirements

The testing framework will provide:
- Test runner with watch mode
- Mock factory for all services
- Test data builders
- Assertion libraries
- Performance profiling tools
- Test report generators
- Coverage analyzers

---

## Business Context

### Business Value

- **Quality Assurance**: 95% reduction in production bugs
- **Developer Velocity**: 70% faster bug detection and fixing
- **Deployment Confidence**: 10x increase in deployment frequency
- **Cost Reduction**: 80% reduction in manual testing effort
- **Customer Satisfaction**: 99.9% uptime from early bug detection

### User Impact

- Developers ship with confidence
- QA focuses on exploratory testing
- Operations trust automated deployments
- Customers experience fewer issues
- Support handles fewer bug reports

### Risk Assessment

**High Risk**: Flaky tests causing false failures
- *Mitigation*: Automatic flaky test detection and quarantine

**Medium Risk**: Test suite becoming too slow
- *Mitigation*: Parallel execution and test optimization

**Low Risk**: Test framework bugs masking real issues
- *Mitigation*: Self-testing test framework

---

## Dev Technical Guidance

### Testing Framework Architecture

The testing framework implements a layered architecture optimized for speed, reliability, and maintainability:

```typescript
// Core testing framework structure
export class TaskIntegrationTestFramework {
  // Framework layers
  private layers = {
    // Layer 1: Test Infrastructure
    infrastructure: {
      runner: new ParallelTestRunner(),
      environment: new IsolatedTestEnvironment(),
      reporter: new RealTimeReporter(),
      profiler: new PerformanceProfiler()
    },
    
    // Layer 2: Test Utilities
    utilities: {
      mocks: new ServiceMockFactory(),
      builders: new TestDataBuilders(),
      assertions: new CustomAssertions(),
      helpers: new TestHelpers()
    },
    
    // Layer 3: Test Suites
    suites: {
      unit: new UnitTestSuite(),
      integration: new IntegrationTestSuite(),
      e2e: new EndToEndTestSuite(),
      performance: new PerformanceTestSuite(),
      chaos: new ChaosTestSuite()
    },
    
    // Layer 4: Analysis & Reporting
    analysis: {
      coverage: new CoverageAnalyzer(),
      flakiness: new FlakinessDetector(),
      trends: new TrendAnalyzer(),
      insights: new TestInsights()
    }
  };
}
```

### Unit Testing Implementation

```typescript
// Comprehensive unit test setup for task operations
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TaskService } from '../src/services/TaskService';
import { MockTodoWrite, MockPersistence, MockEventBus } from './mocks';
import { TaskBuilder } from './builders';

describe('TaskService', () => {
  let taskService: TaskService;
  let mockTodoWrite: MockTodoWrite;
  let mockPersistence: MockPersistence;
  let mockEventBus: MockEventBus;
  
  beforeEach(() => {
    // Create fresh mocks for each test
    mockTodoWrite = new MockTodoWrite();
    mockPersistence = new MockPersistence();
    mockEventBus = new MockEventBus();
    
    // Inject mocks
    taskService = new TaskService({
      todoWrite: mockTodoWrite,
      persistence: mockPersistence,
      eventBus: mockEventBus
    });
    
    // Reset all mocks
    vi.clearAllMocks();
  });
  
  afterEach(() => {
    // Verify no unexpected calls
    mockTodoWrite.verifyNoUnexpectedCalls();
    mockEventBus.verifyAllEventsHandled();
  });
  
  describe('createTask', () => {
    it('should create task with all required fields', async () => {
      // Arrange
      const taskData = new TaskBuilder()
        .withContent('Implement user authentication')
        .withPriority('high')
        .withMetadata({ storyId: 'story-123' })
        .build();
      
      mockTodoWrite.expectCreate(taskData).resolves({ id: 'task-456' });
      mockPersistence.expectSave().resolves();
      mockEventBus.expectEmit('task.created');
      
      // Act
      const result = await taskService.createTask(taskData);
      
      // Assert
      expect(result).toMatchObject({
        id: 'task-456',
        content: 'Implement user authentication',
        status: 'pending',
        createdAt: expect.any(Date)
      });
      
      // Verify persistence
      expect(mockPersistence.save).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'task-456',
          content: taskData.content
        })
      );
      
      // Verify event emission
      expect(mockEventBus.emit).toHaveBeenCalledWith({
        type: 'task.created',
        payload: expect.objectContaining({ task: result })
      });
    });
    
    it('should handle task creation with story extraction', async () => {
      // Arrange
      const storyContext = {
        id: 'story-789',
        tasks: [
          { content: 'Task 1', priority: 'high' },
          { content: 'Task 2', priority: 'medium' },
          { content: 'Task 3', priority: 'low' }
        ]
      };
      
      const taskData = new TaskBuilder()
        .withContent('First task from story')
        .withMetadata({ 
          storyId: storyContext.id,
          isFirstTask: true 
        })
        .build();
      
      // Mock story task extraction
      mockPersistence.expectFind({ 
        metadata: { storyId: storyContext.id } 
      }).resolves([]);
      
      // Expect batch task creation
      for (const storyTask of storyContext.tasks) {
        mockEventBus.expectEmit('task.create_requested', {
          payload: expect.objectContaining({
            task: expect.objectContaining({ content: storyTask.content })
          })
        });
      }
      
      // Act
      await taskService.createTask(taskData);
      
      // Assert
      expect(mockEventBus.emit).toHaveBeenCalledTimes(storyContext.tasks.length + 1);
    });
    
    it('should rollback on persistence failure', async () => {
      // Arrange
      const taskData = new TaskBuilder().build();
      const createdTask = { id: 'task-999', ...taskData };
      
      mockTodoWrite.expectCreate(taskData).resolves(createdTask);
      mockPersistence.expectSave().rejects(new Error('Database error'));
      mockTodoWrite.expectDelete('task-999').resolves();
      
      // Act & Assert
      await expect(taskService.createTask(taskData))
        .rejects.toThrow('Failed to persist task');
      
      // Verify rollback
      expect(mockTodoWrite.delete).toHaveBeenCalledWith('task-999');
      expect(mockEventBus.emit).not.toHaveBeenCalled();
    });
  });
  
  describe('updateTaskStatus', () => {
    it('should validate status transitions', async () => {
      // Test valid transitions
      const validTransitions = [
        { from: 'pending', to: 'in_progress' },
        { from: 'in_progress', to: 'completed' },
        { from: 'in_progress', to: 'blocked' },
        { from: 'blocked', to: 'in_progress' }
      ];
      
      for (const transition of validTransitions) {
        const task = new TaskBuilder()
          .withId('task-123')
          .withStatus(transition.from)
          .build();
        
        mockPersistence.expectFindById('task-123').resolves(task);
        mockTodoWrite.expectUpdate().resolves();
        mockPersistence.expectUpdate().resolves();
        mockEventBus.expectEmit('task.status_changed');
        
        const result = await taskService.updateTaskStatus('task-123', transition.to);
        
        expect(result.status).toBe(transition.to);
      }
    });
    
    it('should reject invalid status transitions', async () => {
      // Test invalid transitions
      const invalidTransitions = [
        { from: 'pending', to: 'completed' },
        { from: 'completed', to: 'pending' },
        { from: 'completed', to: 'in_progress' }
      ];
      
      for (const transition of invalidTransitions) {
        const task = new TaskBuilder()
          .withId('task-456')
          .withStatus(transition.from)
          .build();
        
        mockPersistence.expectFindById('task-456').resolves(task);
        
        await expect(
          taskService.updateTaskStatus('task-456', transition.to)
        ).rejects.toThrow(`Invalid status transition: ${transition.from} -> ${transition.to}`);
      }
    });
  });
});

// Custom assertion helpers
export const taskAssertions = {
  toBeValidTask(received: any) {
    const pass = 
      received.id && 
      received.content && 
      received.status &&
      received.createdAt instanceof Date;
    
    return {
      pass,
      message: () => pass 
        ? `expected ${received} not to be a valid task`
        : `expected ${received} to be a valid task`
    };
  },
  
  toHaveTaskStatus(received: any, expected: string) {
    const pass = received.status === expected;
    
    return {
      pass,
      message: () => pass
        ? `expected task not to have status ${expected}`
        : `expected task to have status ${expected}, but got ${received.status}`
    };
  }
};

// Property-based testing for edge cases
import { fc } from 'fast-check';

describe('Task validation property tests', () => {
  it('should handle any valid string content', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        (content) => {
          const task = new TaskBuilder().withContent(content).build();
          const validation = taskService.validateTask(task);
          expect(validation.valid).toBe(true);
        }
      )
    );
  });
  
  it('should maintain data integrity through serialization', () => {
    fc.assert(
      fc.property(
        fc.record({
          content: fc.string(),
          priority: fc.constantFrom('low', 'medium', 'high'),
          metadata: fc.dictionary(fc.string(), fc.jsonValue())
        }),
        (taskData) => {
          const original = new TaskBuilder().withData(taskData).build();
          const serialized = JSON.stringify(original);
          const deserialized = JSON.parse(serialized);
          
          expect(deserialized).toEqual(original);
        }
      )
    );
  });
});
```

### Integration Testing Framework

```typescript
// Integration tests for complete workflows
import { IntegrationTestHarness } from './harness';
import { TestScenarios } from './scenarios';
import { RealServices } from '../src/services';

describe('Task Integration Workflows', () => {
  let harness: IntegrationTestHarness;
  let services: RealServices;
  
  beforeAll(async () => {
    // Set up test environment
    harness = await IntegrationTestHarness.create({
      database: 'test_db',
      resetBetweenTests: true,
      seedData: true
    });
    
    services = harness.getServices();
  });
  
  afterAll(async () => {
    await harness.teardown();
  });
  
  describe('Story to Completion Flow', () => {
    it('should handle complete story lifecycle', async () => {
      // Create test story
      const story = await harness.createStory({
        title: 'Implement user authentication',
        tasks: [
          { content: 'Create login form', estimatedHours: 4 },
          { content: 'Implement JWT tokens', estimatedHours: 6 },
          { content: 'Add session management', estimatedHours: 3 },
          { content: 'Create logout functionality', estimatedHours: 2 }
        ]
      });
      
      // Simulate developer picking up story
      const pickupResult = await harness.simulateCommand('pickup-story', {
        storyPath: story.path,
        agent: 'developer'
      });
      
      // Verify tasks created
      expect(pickupResult.tasksCreated).toBe(4);
      
      // Verify story document updated
      const storyDoc = await harness.readStoryDocument(story.path);
      expect(storyDoc).toContain('Status: in_progress');
      
      // Simulate working through tasks
      const tasks = await services.taskService.findByStoryId(story.id);
      
      for (const task of tasks) {
        // Start task
        await harness.simulateTaskStatusChange(task.id, 'in_progress');
        
        // Simulate work
        await harness.simulateWork(task.estimatedHours * 0.8);
        
        // Complete task
        await harness.simulateTaskStatusChange(task.id, 'completed', {
          completionNotes: `Completed ${task.content}`
        });
        
        // Verify story document reflects completion
        const updatedDoc = await harness.readStoryDocument(story.path);
        expect(updatedDoc).toContain(`[x] ${task.content}`);
      }
      
      // Verify story marked complete
      const finalDoc = await harness.readStoryDocument(story.path);
      expect(finalDoc).toContain('Status: completed');
      
      // Verify session notes
      const sessionNotes = await harness.getSessionNotes();
      expect(sessionNotes).toContain('Story completed: Implement user authentication');
      
      // Verify metrics
      const metrics = await harness.getMetrics();
      expect(metrics.tasksCompleted).toBe(4);
      expect(metrics.averageCompletionTime).toBeLessThan(5); // hours
    });
    
    it('should handle concurrent task updates', async () => {
      const story = await harness.createStory({
        title: 'Concurrent task test',
        tasks: Array(10).fill(null).map((_, i) => ({
          content: `Task ${i}`,
          estimatedHours: 1
        }))
      });
      
      await harness.simulateCommand('pickup-story', {
        storyPath: story.path
      });
      
      const tasks = await services.taskService.findByStoryId(story.id);
      
      // Update all tasks concurrently
      const updates = tasks.map(task => 
        harness.simulateTaskStatusChange(task.id, 'in_progress')
      );
      
      await Promise.all(updates);
      
      // Verify no conflicts or data loss
      const updatedTasks = await services.taskService.findByStoryId(story.id);
      expect(updatedTasks.every(t => t.status === 'in_progress')).toBe(true);
      
      // Verify document consistency
      const doc = await harness.readStoryDocument(story.path);
      const inProgressCount = (doc.match(/\[ \]/g) || []).length;
      expect(inProgressCount).toBe(0); // All should show in progress
    });
  });
  
  describe('Cross-Agent Workflows', () => {
    it('should handle agent handoffs correctly', async () => {
      // QA creates test plan
      const testPlan = await harness.simulateAgent('qa', async (agent) => {
        return await agent.createTestPlan({
          storyId: 'story-123',
          testCases: [
            { name: 'Login with valid credentials', type: 'functional' },
            { name: 'Login with invalid credentials', type: 'functional' },
            { name: 'Session timeout', type: 'edge_case' }
          ]
        });
      });
      
      // Developer implements based on test plan
      await harness.simulateAgent('developer', async (agent) => {
        const tasks = await agent.getTasksFromTestPlan(testPlan);
        
        for (const task of tasks) {
          await agent.implementTask(task);
          await agent.runTests(task);
        }
      });
      
      // QA validates implementation
      const validationResult = await harness.simulateAgent('qa', async (agent) => {
        return await agent.validateImplementation(testPlan);
      });
      
      expect(validationResult.allTestsPassing).toBe(true);
      expect(validationResult.coverage).toBeGreaterThan(90);
    });
  });
});

// Test data builders for complex scenarios
export class TestDataBuilders {
  static task() {
    return new TaskBuilder();
  }
  
  static story() {
    return new StoryBuilder();
  }
  
  static epic() {
    return new EpicBuilder();
  }
  
  static session() {
    return new SessionBuilder();
  }
}

class TaskBuilder {
  private task: Partial<Task> = {
    id: `task-${Date.now()}-${Math.random()}`,
    content: 'Default task content',
    status: 'pending',
    priority: 'medium',
    createdAt: new Date(),
    metadata: {}
  };
  
  withId(id: string): this {
    this.task.id = id;
    return this;
  }
  
  withContent(content: string): this {
    this.task.content = content;
    return this;
  }
  
  withStatus(status: TaskStatus): this {
    this.task.status = status;
    return this;
  }
  
  withPriority(priority: Priority): this {
    this.task.priority = priority;
    return this;
  }
  
  withMetadata(metadata: Record<string, any>): this {
    this.task.metadata = { ...this.task.metadata, ...metadata };
    return this;
  }
  
  withDependencies(dependencies: string[]): this {
    this.task.dependencies = dependencies;
    return this;
  }
  
  build(): Task {
    return this.task as Task;
  }
  
  buildMany(count: number): Task[] {
    return Array(count).fill(null).map((_, i) => 
      this.withId(`${this.task.id}-${i}`).build()
    );
  }
}
```

### End-to-End Testing Implementation

```typescript
// E2E tests using Playwright
import { test, expect } from '@playwright/test';
import { E2EHelpers } from './helpers';
import { TestUsers } from './users';

test.describe('AP Method Task Integration E2E', () => {
  let helpers: E2EHelpers;
  
  test.beforeAll(async () => {
    helpers = new E2EHelpers();
    await helpers.setupTestEnvironment();
  });
  
  test.afterAll(async () => {
    await helpers.teardownTestEnvironment();
  });
  
  test('Complete story workflow from UI', async ({ page }) => {
    // Login as developer
    await helpers.login(page, TestUsers.developer);
    
    // Navigate to stories
    await page.goto('/stories');
    await expect(page.locator('h1')).toContainText('Available Stories');
    
    // Pick up story
    const storyCard = page.locator('[data-story-id="auth-implementation"]');
    await storyCard.locator('button:has-text("Pick Up Story")').click();
    
    // Wait for task extraction
    await expect(page.locator('.notification')).toContainText('4 tasks extracted');
    
    // Verify TodoWrite integration
    await page.goto('/tasks');
    const taskList = page.locator('[data-testid="task-list"]');
    await expect(taskList.locator('.task-item')).toHaveCount(4);
    
    // Work through first task
    const firstTask = taskList.locator('.task-item').first();
    await firstTask.locator('button:has-text("Start")').click();
    
    // Verify status update
    await expect(firstTask).toHaveAttribute('data-status', 'in_progress');
    
    // Add implementation notes
    await firstTask.locator('button:has-text("Add Note")').click();
    await page.fill('[data-testid="note-input"]', 'Implemented using React Hook Form');
    await page.click('button:has-text("Save Note")');
    
    // Complete task
    await firstTask.locator('button:has-text("Complete")').click();
    await expect(firstTask).toHaveAttribute('data-status', 'completed');
    
    // Verify story document sync
    await page.goto('/stories/auth-implementation');
    const storyContent = page.locator('[data-testid="story-content"]');
    await expect(storyContent).toContainText('[x] Create login form');
    await expect(storyContent).toContainText('Implemented using React Hook Form');
    
    // Verify session notes
    await page.goto('/session-notes');
    const latestNote = page.locator('.session-note').first();
    await expect(latestNote).toContainText('Task completed: Create login form');
  });
  
  test('Parallel task execution', async ({ browser }) => {
    // Create multiple browser contexts for parallel work
    const contexts = await Promise.all(
      Array(3).fill(null).map(() => browser.newContext())
    );
    
    const pages = await Promise.all(
      contexts.map(ctx => ctx.newPage())
    );
    
    // Login all users
    await Promise.all(
      pages.map((page, i) => 
        helpers.login(page, TestUsers[`developer${i + 1}`])
      )
    );
    
    // Pick up same story
    const storyId = 'parallel-work-story';
    await helpers.createStoryWithTasks(storyId, 10);
    
    // All developers pick up story
    await Promise.all(
      pages.map(page => helpers.pickUpStory(page, storyId))
    );
    
    // Work on different tasks concurrently
    const taskAssignments = [
      [0, 1, 2], // Developer 1 tasks
      [3, 4, 5], // Developer 2 tasks
      [6, 7, 8, 9] // Developer 3 tasks
    ];
    
    await Promise.all(
      pages.map(async (page, devIndex) => {
        for (const taskIndex of taskAssignments[devIndex]) {
          await helpers.completeTask(page, `task-${taskIndex}`);
        }
      })
    );
    
    // Verify all tasks completed without conflicts
    await pages[0].goto(`/stories/${storyId}`);
    const completedTasks = pages[0].locator('[data-testid="task-list"] [data-status="completed"]');
    await expect(completedTasks).toHaveCount(10);
    
    // Verify no data loss
    for (let i = 0; i < 10; i++) {
      await expect(pages[0].locator(`[data-task-id="task-${i}"]`)).toBeVisible();
    }
    
    // Cleanup
    await Promise.all(contexts.map(ctx => ctx.close()));
  });
  
  test('Error recovery and resilience', async ({ page }) => {
    await helpers.login(page, TestUsers.developer);
    
    // Create story with network issues
    await helpers.createStoryWithTasks('resilience-test', 5);
    
    // Simulate network failure during task update
    await page.route('**/api/tasks/*', route => {
      if (Math.random() > 0.5) {
        route.abort('failed');
      } else {
        route.continue();
      }
    });
    
    // Attempt to update tasks
    await page.goto('/tasks');
    const tasks = page.locator('.task-item');
    
    for (let i = 0; i < 5; i++) {
      const task = tasks.nth(i);
      await task.locator('button:has-text("Start")').click();
      
      // Verify retry mechanism
      await expect(task).toHaveAttribute('data-status', 'in_progress', {
        timeout: 30000 // Allow time for retries
      });
    }
    
    // Restore network
    await page.unroute('**/api/tasks/*');
    
    // Verify eventual consistency
    await page.reload();
    const updatedTasks = page.locator('[data-status="in_progress"]');
    await expect(updatedTasks).toHaveCount(5);
  });
});

// Visual regression testing
test.describe('Visual Regression Tests', () => {
  test('Task list appearance', async ({ page }) => {
    await helpers.login(page, TestUsers.developer);
    await helpers.createStoryWithTasks('visual-test', 5);
    
    await page.goto('/tasks');
    await expect(page.locator('[data-testid="task-list"]')).toBeVisible();
    
    // Take screenshot
    await expect(page).toHaveScreenshot('task-list.png', {
      maxDiffPixels: 100,
      threshold: 0.2
    });
    
    // Test different states
    await page.locator('.task-item').first().click();
    await expect(page).toHaveScreenshot('task-expanded.png');
    
    // Dark mode
    await page.click('[data-testid="theme-toggle"]');
    await expect(page).toHaveScreenshot('task-list-dark.png');
  });
});
```

### Performance Testing Suite

```typescript
// Performance and load testing
import { PerformanceTestRunner } from './performance/runner';
import { LoadGenerator } from './performance/load';
import { MetricsCollector } from './performance/metrics';

describe('Performance Test Suite', () => {
  let runner: PerformanceTestRunner;
  let loadGen: LoadGenerator;
  let metrics: MetricsCollector;
  
  beforeAll(async () => {
    runner = new PerformanceTestRunner({
      warmupDuration: '30s',
      testDuration: '5m',
      cooldownDuration: '30s'
    });
    
    loadGen = new LoadGenerator();
    metrics = new MetricsCollector();
    
    await runner.setup();
  });
  
  afterAll(async () => {
    await runner.teardown();
    await metrics.generateReport();
  });
  
  test('Task creation performance under load', async () => {
    const scenario = {
      name: 'Task Creation Load Test',
      stages: [
        { duration: '1m', target: 10 }, // Ramp up to 10 users
        { duration: '3m', target: 50 }, // Stay at 50 users
        { duration: '1m', target: 0 }   // Ramp down
      ],
      thresholds: {
        'p95_response_time': 100, // 95th percentile < 100ms
        'error_rate': 0.01,       // Error rate < 1%
        'throughput': 1000        // > 1000 ops/sec
      }
    };
    
    const results = await runner.runScenario(scenario, async (vu) => {
      // Virtual user workflow
      const taskData = loadGen.generateTaskData();
      
      const start = performance.now();
      try {
        await vu.createTask(taskData);
        metrics.recordSuccess('task_creation', performance.now() - start);
      } catch (error) {
        metrics.recordError('task_creation', error);
      }
    });
    
    // Assert thresholds met
    expect(results.p95ResponseTime).toBeLessThan(100);
    expect(results.errorRate).toBeLessThan(0.01);
    expect(results.throughput).toBeGreaterThan(1000);
  });
  
  test('Concurrent task updates stress test', async () => {
    // Create test data
    const tasks = await loadGen.createTasks(1000);
    
    const scenario = {
      name: 'Concurrent Updates Stress Test',
      vus: 100, // 100 virtual users
      duration: '2m',
      scenario: 'shared-iterations',
      options: {
        scenarios: {
          concurrent_updates: {
            executor: 'constant-vus',
            vus: 100,
            duration: '2m',
            exec: 'updateTasks'
          }
        }
      }
    };
    
    const results = await runner.runScenario(scenario, async (vu) => {
      const task = tasks[Math.floor(Math.random() * tasks.length)];
      const newStatus = loadGen.randomStatus();
      
      const start = performance.now();
      try {
        await vu.updateTaskStatus(task.id, newStatus);
        metrics.recordSuccess('status_update', performance.now() - start);
      } catch (error) {
        if (error.message.includes('Optimistic lock')) {
          metrics.recordConflict('status_update');
        } else {
          metrics.recordError('status_update', error);
        }
      }
    });
    
    // Analyze results
    expect(results.conflictRate).toBeLessThan(0.05); // < 5% conflicts
    expect(results.successRate).toBeGreaterThan(0.95); // > 95% success
    
    // Verify data consistency
    const finalStates = await loadGen.verifyFinalStates(tasks);
    expect(finalStates.inconsistencies).toBe(0);
  });
  
  test('Memory leak detection', async () => {
    const memoryBaseline = process.memoryUsage();
    
    // Run intensive operations
    for (let i = 0; i < 10; i++) {
      // Create and process large batches
      const batch = await loadGen.createBatch(1000);
      await runner.processBatch(batch);
      
      // Force garbage collection
      if (global.gc) {
        global.gc();
      }
      
      // Check memory growth
      const currentMemory = process.memoryUsage();
      const growth = currentMemory.heapUsed - memoryBaseline.heapUsed;
      
      // Memory should not grow indefinitely
      expect(growth).toBeLessThan(100 * 1024 * 1024); // < 100MB growth
    }
    
    // Final memory check
    const finalMemory = process.memoryUsage();
    const totalGrowth = finalMemory.heapUsed - memoryBaseline.heapUsed;
    expect(totalGrowth).toBeLessThan(50 * 1024 * 1024); // < 50MB retained
  });
  
  test('Performance regression detection', async () => {
    // Load baseline metrics
    const baseline = await metrics.loadBaseline('v1.0.0');
    
    // Run current performance tests
    const current = await runner.runBenchmarks([
      'task_creation',
      'status_update',
      'batch_processing',
      'story_sync',
      'session_notes'
    ]);
    
    // Compare against baseline
    for (const [operation, currentMetrics] of Object.entries(current)) {
      const baselineMetrics = baseline[operation];
      
      // Allow 10% regression tolerance
      const regressionThreshold = 1.1;
      
      expect(currentMetrics.p50).toBeLessThan(
        baselineMetrics.p50 * regressionThreshold
      );
      expect(currentMetrics.p95).toBeLessThan(
        baselineMetrics.p95 * regressionThreshold
      );
      expect(currentMetrics.p99).toBeLessThan(
        baselineMetrics.p99 * regressionThreshold
      );
    }
    
    // Save current as new baseline if all tests pass
    await metrics.saveBaseline('current', current);
  });
});

// Chaos testing for resilience
export class ChaosTestSuite {
  private chaosMonkey: ChaosMonkey;
  private resilience: ResilienceVerifier;
  
  async runChaosTests(): Promise<ChaosTestResults> {
    const scenarios = [
      this.networkChaos(),
      this.resourceChaos(),
      this.dataChaos(),
      this.timeChaos()
    ];
    
    const results = await Promise.all(
      scenarios.map(scenario => this.executeScenario(scenario))
    );
    
    return this.analyzeResults(results);
  }
  
  private networkChaos(): ChaosScenario {
    return {
      name: 'Network Chaos',
      description: 'Simulate network failures and latency',
      chaos: [
        {
          type: 'network_delay',
          target: 'api_calls',
          config: { minDelay: 100, maxDelay: 5000 }
        },
        {
          type: 'network_failure',
          target: 'random_endpoints',
          config: { failureRate: 0.1 }
        },
        {
          type: 'packet_loss',
          target: 'websocket_connections',
          config: { lossRate: 0.05 }
        }
      ],
      validation: async () => {
        // System should handle network issues gracefully
        const metrics = await this.resilience.checkSystemHealth();
        expect(metrics.availability).toBeGreaterThan(0.99);
        expect(metrics.dataConsistency).toBe(1.0);
      }
    };
  }
  
  private resourceChaos(): ChaosScenario {
    return {
      name: 'Resource Chaos',
      description: 'Simulate resource exhaustion',
      chaos: [
        {
          type: 'cpu_stress',
          target: 'worker_processes',
          config: { utilization: 0.95 }
        },
        {
          type: 'memory_pressure',
          target: 'application',
          config: { fillRate: 0.9 }
        },
        {
          type: 'disk_full',
          target: 'temp_directory',
          config: { fillPercentage: 0.98 }
        }
      ],
      validation: async () => {
        // System should degrade gracefully
        const performance = await this.resilience.measurePerformance();
        expect(performance.degradation).toBeLessThan(0.5); // < 50% degradation
        expect(performance.errorRate).toBeLessThan(0.05);
      }
    };
  }
}
```

### Mock Service Factory

```typescript
// Comprehensive mock factory for all services
export class ServiceMockFactory {
  createTodoWriteMock(): MockTodoWrite {
    return new MockTodoWrite();
  }
  
  createPersistenceMock(): MockPersistence {
    return new MockPersistence();
  }
  
  createEventBusMock(): MockEventBus {
    return new MockEventBus();
  }
  
  createAllMocks(): ServiceMocks {
    return {
      todoWrite: this.createTodoWriteMock(),
      persistence: this.createPersistenceMock(),
      eventBus: this.createEventBusMock(),
      storyService: this.createStoryServiceMock(),
      sessionService: this.createSessionServiceMock(),
      hookRegistry: this.createHookRegistryMock()
    };
  }
}

export class MockTodoWrite implements TodoWriteService {
  private expectations: Map<string, Expectation> = new Map();
  private calls: Call[] = [];
  
  expectCreate(matcher: any): Expectation {
    const expectation = new Expectation('create', matcher);
    this.expectations.set('create', expectation);
    return expectation;
  }
  
  async create(data: any): Promise<any> {
    this.calls.push({ method: 'create', args: [data] });
    
    const expectation = this.expectations.get('create');
    if (!expectation) {
      throw new Error('Unexpected call to create');
    }
    
    if (!expectation.matches(data)) {
      throw new Error(`create called with unexpected args: ${JSON.stringify(data)}`);
    }
    
    return expectation.getResponse();
  }
  
  verifyNoUnexpectedCalls(): void {
    const unexpectedCalls = this.calls.filter(call => 
      !this.expectations.has(call.method)
    );
    
    if (unexpectedCalls.length > 0) {
      throw new Error(`Unexpected calls: ${JSON.stringify(unexpectedCalls)}`);
    }
  }
  
  reset(): void {
    this.expectations.clear();
    this.calls = [];
  }
}

class Expectation {
  private response: any;
  private error: Error | null = null;
  private matcher: (value: any) => boolean;
  
  constructor(
    public method: string,
    matcher: any
  ) {
    this.matcher = typeof matcher === 'function' 
      ? matcher 
      : (value) => JSON.stringify(value) === JSON.stringify(matcher);
  }
  
  resolves(value: any): this {
    this.response = value;
    return this;
  }
  
  rejects(error: Error): this {
    this.error = error;
    return this;
  }
  
  matches(value: any): boolean {
    return this.matcher(value);
  }
  
  async getResponse(): Promise<any> {
    if (this.error) {
      throw this.error;
    }
    return this.response;
  }
}
```

### Test Coverage and Reporting

```typescript
// Coverage analysis and reporting
export class CoverageAnalyzer {
  private coverage: CoverageData;
  private thresholds: CoverageThresholds;
  
  constructor(thresholds: CoverageThresholds = {
    statements: 90,
    branches: 85,
    functions: 90,
    lines: 90
  }) {
    this.thresholds = thresholds;
  }
  
  async analyzeCoverage(): Promise<CoverageReport> {
    // Collect coverage data
    this.coverage = await this.collectCoverage();
    
    // Generate report
    const report: CoverageReport = {
      summary: this.generateSummary(),
      detailed: this.generateDetailedReport(),
      uncovered: this.findUncoveredCode(),
      suggestions: this.generateSuggestions(),
      trends: await this.analyzeTrends()
    };
    
    // Check thresholds
    this.checkThresholds(report.summary);
    
    return report;
  }
  
  private generateSummary(): CoverageSummary {
    return {
      statements: {
        total: this.coverage.statements.total,
        covered: this.coverage.statements.covered,
        percentage: (this.coverage.statements.covered / this.coverage.statements.total) * 100
      },
      branches: {
        total: this.coverage.branches.total,
        covered: this.coverage.branches.covered,
        percentage: (this.coverage.branches.covered / this.coverage.branches.total) * 100
      },
      functions: {
        total: this.coverage.functions.total,
        covered: this.coverage.functions.covered,
        percentage: (this.coverage.functions.covered / this.coverage.functions.total) * 100
      },
      lines: {
        total: this.coverage.lines.total,
        covered: this.coverage.lines.covered,
        percentage: (this.coverage.lines.covered / this.coverage.lines.total) * 100
      }
    };
  }
  
  private findUncoveredCode(): UncoveredCode[] {
    const uncovered: UncoveredCode[] = [];
    
    // Find uncovered lines
    for (const file of this.coverage.files) {
      const uncoveredLines = file.lines.filter(line => !line.covered);
      
      if (uncoveredLines.length > 0) {
        uncovered.push({
          file: file.path,
          lines: uncoveredLines.map(l => l.number),
          type: 'lines',
          priority: this.calculatePriority(file, uncoveredLines)
        });
      }
      
      // Find uncovered branches
      const uncoveredBranches = file.branches.filter(branch => !branch.covered);
      if (uncoveredBranches.length > 0) {
        uncovered.push({
          file: file.path,
          branches: uncoveredBranches,
          type: 'branches',
          priority: this.calculateBranchPriority(uncoveredBranches)
        });
      }
    }
    
    // Sort by priority
    return uncovered.sort((a, b) => b.priority - a.priority);
  }
  
  private generateSuggestions(): TestSuggestion[] {
    const suggestions: TestSuggestion[] = [];
    
    // Analyze patterns in uncovered code
    const patterns = this.analyzeUncoveredPatterns();
    
    for (const pattern of patterns) {
      suggestions.push({
        type: pattern.type,
        description: pattern.description,
        example: this.generateTestExample(pattern),
        estimatedImpact: pattern.coverageImpact
      });
    }
    
    return suggestions;
  }
}

// Test report generator
export class TestReportGenerator {
  async generateReport(results: TestResults): Promise<void> {
    const report = {
      summary: this.generateSummary(results),
      details: this.generateDetails(results),
      visualizations: await this.generateVisualizations(results),
      recommendations: this.generateRecommendations(results)
    };
    
    // Generate multiple formats
    await this.generateHTMLReport(report);
    await this.generateJSONReport(report);
    await this.generateJUnitXML(report);
    await this.generateMarkdownReport(report);
    
    // Send notifications if needed
    if (results.hasFailures) {
      await this.sendFailureNotifications(results);
    }
  }
  
  private async generateHTMLReport(report: Report): Promise<void> {
    const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Test Report - ${new Date().toISOString()}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .summary { background: #f0f0f0; padding: 20px; border-radius: 5px; }
    .passed { color: green; }
    .failed { color: red; }
    .skipped { color: orange; }
    .chart { margin: 20px 0; }
    .recommendations { background: #ffffcc; padding: 15px; }
  </style>
</head>
<body>
  <h1>Test Execution Report</h1>
  
  <div class="summary">
    <h2>Summary</h2>
    <p>Total Tests: ${report.summary.total}</p>
    <p class="passed">Passed: ${report.summary.passed}</p>
    <p class="failed">Failed: ${report.summary.failed}</p>
    <p class="skipped">Skipped: ${report.summary.skipped}</p>
    <p>Duration: ${report.summary.duration}ms</p>
    <p>Success Rate: ${report.summary.successRate}%</p>
  </div>
  
  <div class="details">
    <h2>Test Details</h2>
    ${this.renderTestDetails(report.details)}
  </div>
  
  <div class="visualizations">
    <h2>Visualizations</h2>
    ${this.renderCharts(report.visualizations)}
  </div>
  
  <div class="recommendations">
    <h2>Recommendations</h2>
    ${this.renderRecommendations(report.recommendations)}
  </div>
</body>
</html>
    `;
    
    await fs.writeFile('test-report.html', html);
  }
}
```

### Flaky Test Detection

```typescript
// Intelligent flaky test detection and quarantine
export class FlakinessDetector {
  private history: TestExecutionHistory;
  private analyzer: StatisticalAnalyzer;
  
  async detectFlakyTests(): Promise<FlakyTestReport> {
    const candidates = await this.identifyCandidates();
    const confirmed = await this.confirmFlakiness(candidates);
    const analysis = await this.analyzeRootCauses(confirmed);
    
    return {
      flakyTests: confirmed,
      rootCauses: analysis,
      recommendations: this.generateRecommendations(analysis),
      quarantined: await this.quarantineTests(confirmed)
    };
  }
  
  private async identifyCandidates(): Promise<TestCandidate[]> {
    const recentRuns = await this.history.getRecentRuns(100);
    const candidates: TestCandidate[] = [];
    
    // Group by test
    const testRuns = this.groupByTest(recentRuns);
    
    for (const [testId, runs] of testRuns) {
      const successRate = this.calculateSuccessRate(runs);
      const variance = this.calculateVariance(runs);
      
      // High variance or inconsistent success rate indicates flakiness
      if (variance > 0.2 || (successRate > 0.1 && successRate < 0.9)) {
        candidates.push({
          testId,
          successRate,
          variance,
          pattern: this.detectPattern(runs),
          confidence: this.calculateConfidence(runs)
        });
      }
    }
    
    return candidates;
  }
  
  private async confirmFlakiness(candidates: TestCandidate[]): Promise<FlakyTest[]> {
    const confirmed: FlakyTest[] = [];
    
    for (const candidate of candidates) {
      // Run test multiple times in isolation
      const isolatedRuns = await this.runInIsolation(candidate.testId, 10);
      
      if (this.hasInconsistentResults(isolatedRuns)) {
        // Analyze failure patterns
        const patterns = this.analyzeFailurePatterns(isolatedRuns);
        
        confirmed.push({
          ...candidate,
          confirmed: true,
          patterns,
          severity: this.calculateSeverity(candidate, patterns)
        });
      }
    }
    
    return confirmed;
  }
  
  private analyzeFailurePatterns(runs: TestRun[]): FailurePattern[] {
    const patterns: FailurePattern[] = [];
    
    // Time-based patterns
    const timePattern = this.detectTimePattern(runs);
    if (timePattern) patterns.push(timePattern);
    
    // Resource-based patterns
    const resourcePattern = this.detectResourcePattern(runs);
    if (resourcePattern) patterns.push(resourcePattern);
    
    // Order-based patterns
    const orderPattern = this.detectOrderPattern(runs);
    if (orderPattern) patterns.push(orderPattern);
    
    // Environment-based patterns
    const envPattern = this.detectEnvironmentPattern(runs);
    if (envPattern) patterns.push(envPattern);
    
    return patterns;
  }
  
  private generateRecommendations(analysis: RootCauseAnalysis): Recommendation[] {
    const recommendations: Recommendation[] = [];
    
    for (const cause of analysis.causes) {
      switch (cause.type) {
        case 'timing':
          recommendations.push({
            test: cause.testId,
            action: 'Add explicit waits or use deterministic time',
            example: `
// Instead of:
await sleep(1000);

// Use:
await waitFor(() => element.isVisible());
            `,
            priority: 'high'
          });
          break;
          
        case 'shared_state':
          recommendations.push({
            test: cause.testId,
            action: 'Isolate test state',
            example: `
// Add to test:
beforeEach(() => {
  TestDatabase.reset();
  TestCache.clear();
});
            `,
            priority: 'high'
          });
          break;
          
        case 'external_dependency':
          recommendations.push({
            test: cause.testId,
            action: 'Mock external dependencies',
            example: `
// Mock the external service:
mockServer.stub({
  url: '/api/external',
  response: { data: 'mocked' }
});
            `,
            priority: 'medium'
          });
          break;
      }
    }
    
    return recommendations;
  }
}
```

---

## Tasks / Subtasks

### Task 1: Set Up Test Infrastructure (AC: 1)
- [ ] 1.1 Configure test runners (Jest, Vitest, Playwright)
- [ ] 1.2 Set up test environment isolation
- [ ] 1.3 Create test database management
- [ ] 1.4 Configure coverage tools
- [ ] 1.5 Set up parallel execution

### Task 2: Create Mock Service Layer (AC: 2)
- [ ] 2.1 Build TodoWrite mock with expectations
- [ ] 2.2 Create persistence mock with state
- [ ] 2.3 Implement event bus test double
- [ ] 2.4 Add service mock factory
- [ ] 2.5 Create mock validation utilities

### Task 3: Implement Unit Test Suite (AC: 2, 4)
- [ ] 3.1 Create task service unit tests
- [ ] 3.2 Add hook execution tests
- [ ] 3.3 Build persistence layer tests
- [ ] 3.4 Test error handling paths
- [ ] 3.5 Add property-based tests

### Task 4: Build Integration Tests (AC: 2, 4)
- [ ] 4.1 Create story workflow tests
- [ ] 4.2 Add cross-agent handoff tests
- [ ] 4.3 Test concurrent operations
- [ ] 4.4 Validate data consistency
- [ ] 4.5 Test session recovery

### Task 5: Develop E2E Test Suite (AC: 1, 2)
- [ ] 5.1 Set up Playwright framework
- [ ] 5.2 Create UI workflow tests
- [ ] 5.3 Add visual regression tests
- [ ] 5.4 Test error scenarios
- [ ] 5.5 Implement accessibility tests

### Task 6: Create Performance Tests (AC: 3)
- [ ] 6.1 Build load test scenarios
- [ ] 6.2 Add stress test suite
- [ ] 6.3 Implement memory leak detection
- [ ] 6.4 Create performance benchmarks
- [ ] 6.5 Add regression detection

### Task 7: Implement Chaos Testing (AC: 3)
- [ ] 7.1 Create chaos scenarios
- [ ] 7.2 Build failure injection
- [ ] 7.3 Add resilience verification
- [ ] 7.4 Test recovery procedures
- [ ] 7.5 Document failure modes

### Task 8: Build Test Data Management (AC: All)
- [ ] 8.1 Create test data builders
- [ ] 8.2 Add fixture management
- [ ] 8.3 Implement data generators
- [ ] 8.4 Build snapshot testing
- [ ] 8.5 Add test data cleanup

### Task 9: Set Up CI/CD Integration (AC: 1, 6)
- [ ] 9.1 Configure test pipelines
- [ ] 9.2 Add parallel test execution
- [ ] 9.3 Implement test reporting
- [ ] 9.4 Set up failure notifications
- [ ] 9.5 Add flaky test detection

### Task 10: Create Documentation (AC: 4)
- [ ] 10.1 Write testing guide
- [ ] 10.2 Document best practices
- [ ] 10.3 Create troubleshooting guide
- [ ] 10.4 Add example tests
- [ ] 10.5 Record video tutorials

---

## Test Scenarios

### Happy Path

1. **Complete Test Suite Execution**
   - All unit tests pass
   - Integration tests validate workflows
   - E2E tests confirm UI functionality
   - Performance meets benchmarks
   - Coverage exceeds thresholds
   - Reports generated successfully

### Edge Cases

1. **Flaky Test Detection**
   - Test fails intermittently
   - System detects pattern
   - Test automatically quarantined
   - Root cause analysis provided
   - Fix recommendations generated

2. **Performance Regression**
   - New code slows operations
   - Benchmark tests detect regression
   - Detailed comparison provided
   - Bottleneck identified
   - Optimization suggestions given

3. **Concurrent Test Execution**
   - 100 tests run in parallel
   - No interference between tests
   - Results remain deterministic
   - Total time under 2 minutes
   - All resources cleaned up

4. **Test Data Conflicts**
   - Multiple tests use same data
   - Isolation prevents conflicts
   - Each test has clean state
   - No false failures
   - Cleanup verified

### Error Scenarios

1. **Infrastructure Failure During Tests**
   - Database becomes unavailable
   - Tests detect infrastructure issue
   - Clear error reporting
   - Graceful degradation
   - Automatic retry succeeds

2. **Memory Exhaustion in Tests**
   - Large dataset causes OOM
   - Test framework detects issue
   - Process gracefully terminated
   - Memory leak identified
   - Smaller batch size suggested

3. **Circular Dependency in Mocks**
   - Mock A depends on Mock B depends on Mock A
   - Framework detects cycle
   - Clear error message
   - Dependency graph provided
   - Refactoring guidance given

---

## Architecture Diagrams

### Test Framework Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                   Test Execution Layer                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │Unit Tests│ │Integration│ │E2E Tests │ │Performance│     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                    Test Utilities Layer                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │Mocks     │ │Builders  │ │Assertions│ │Helpers   │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                 Test Infrastructure Layer                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │Runner    │ │Reporter  │ │Coverage  │ │CI/CD     │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Test Execution Flow
```
Code Change → CI Trigger → Test Execution → Results Analysis
     │            │              │                 │
     │            ▼              ▼                 ▼
     │      Lint & Build    Parallel Tests    Coverage Check
     │            │              │                 │
     │            │              ▼                 ▼
     │            │         Unit → Integration  Report Generation
     │            │              ↓                 │
     │            │            E2E → Perf         ▼
     │            │              │            Notifications
     │            │              ▼                 │
     └────────────┴──────── All Pass? ─────────────┘
                                │
                                ▼
                         Deploy or Block
```

---

## Notes & Discussion

### Development Notes

- Use test containers for database isolation
- Implement visual regression with Percy or Chromatic
- Consider contract testing with Pact
- Plan for test environment costs

### QA Notes

- Focus on critical user journeys
- Test accessibility with axe-core
- Validate against production data shapes
- Include security testing (OWASP)

### Stakeholder Feedback

- PM: "Need confidence in every deployment"
- Architect: "Tests must not slow development"
- DevOps: "Must run efficiently in CI/CD"

---

## Story Progress Tracking

### Agent/Developer: `SM Agent - Story Creator`

### Implementation Log

| Date | Activity | Notes |
|------|----------|-------|
| 2024-01-10 | Story enhanced | Added comprehensive testing framework design |
| 2024-01-10 | Examples created | 30+ test implementation examples |
| 2024-01-10 | Strategies defined | Unit, integration, E2E, performance, chaos |

### Completion Notes

This story provides a complete blueprint for implementing a comprehensive testing framework. The design covers all aspects of testing from unit to chaos testing, with emphasis on automation, reliability, and actionable insights.

---

## Change Log

| Change | Date - Time | Version | Description | Author |
|--------|-------------|---------|-------------|--------|
| Enhanced | 2024-01-10 - 12:00 | 2.0.0 | Complete story enhancement with testing framework | SM Agent |