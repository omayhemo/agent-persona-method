# Story 1.12: Implement Cross-Agent Visibility

## Story ID: STORY-012
## Epic: EPIC-001 - AP Method Subtask Integration
## Priority: Medium
## Story Points: 13

---

## User Story

**As a** Project Manager overseeing AP Method workflows  
**I want** real-time visibility into all agent activities, task statuses, and handoff points across the entire AP ecosystem  
**So that** I can monitor progress, identify bottlenecks, facilitate smooth handoffs, and ensure no tasks fall through the cracks

---

## Acceptance Criteria

1. **Given** multiple agents working on related tasks **When** viewing the unified dashboard **Then** all agent activities are visible in real-time with < 1 second latency
2. **Given** an agent handoff is initiated **When** the receiving agent starts **Then** complete task context and history is immediately accessible
3. **Given** tasks span multiple agents **When** tracking progress **Then** a unified timeline shows all agent contributions with attribution
4. **Given** a task is blocked **When** viewing cross-agent dependencies **Then** the blocking agent and task are clearly identified with resolution path
5. **Given** 50+ concurrent agent sessions **When** accessing the visibility system **Then** performance remains responsive with < 100ms query times
6. **Given** an agent completes work **When** another agent needs context **Then** searchable artifacts and decisions are available within 5 seconds

---

## Definition of Done

- [ ] All acceptance criteria met with automated testing
- [ ] Cross-agent dashboard operational with real-time updates
- [ ] Handoff context preservation verified across all personas
- [ ] Search functionality indexes all agent activities
- [ ] Performance benchmarks met under load
- [ ] Security and privacy controls implemented
- [ ] Integration with all AP agent personas complete
- [ ] Analytics and reporting features functional
- [ ] Documentation includes usage examples
- [ ] Production deployment successful

---

## Technical Requirements

### Dependencies

- [ ] Prerequisite Story: 1.8 - Task Tracking Hooks (Completed)
- [ ] Prerequisite Story: 1.5 - Persistence Architecture (Completed)
- [ ] Technical Dependency: Real-time event streaming
- [ ] Technical Dependency: Distributed search infrastructure
- [ ] External Dependency: Visualization libraries (D3.js, React Flow)

### Technical Notes

Cross-agent visibility requirements:
- Event sourcing for complete audit trail
- Real-time synchronization across sessions
- Federated search across agent data
- Timeline reconstruction from events
- Role-based access control
- Data retention and archival policies
- Performance optimization for large datasets

### API/Service Requirements

The visibility system will provide:
- `AgentActivityStream` for real-time events
- `CrossAgentSearch` for unified queries
- `HandoffContextManager` for transitions
- `DependencyTracker` for cross-agent deps
- `TimelineReconstructor` for history
- `AnalyticsEngine` for insights

---

## Business Context

### Business Value

- **Transparency**: 100% visibility into AP Method execution
- **Efficiency**: 60% reduction in handoff friction
- **Quality**: 70% fewer dropped tasks
- **Insights**: Data-driven process improvements
- **Accountability**: Complete audit trail for compliance

### User Impact

- Project managers see unified progress
- Agents have full context for handoffs
- Stakeholders get real-time updates
- Teams identify bottlenecks quickly
- Historical analysis enables optimization

### Risk Assessment

**High Risk**: Information overload from too much data
- *Mitigation*: Smart filtering and aggregation

**Medium Risk**: Performance degradation with scale
- *Mitigation*: Distributed architecture and caching

**Low Risk**: Privacy concerns with cross-agent visibility
- *Mitigation*: Role-based access controls

---

## Dev Technical Guidance

### Cross-Agent Visibility Architecture

```typescript
// Core cross-agent visibility system
export class CrossAgentVisibilitySystem {
  private components = {
    // Event Collection and Processing
    eventCollection: {
      collector: new DistributedEventCollector(),
      processor: new EventStreamProcessor(),
      enricher: new ContextEnricher(),
      router: new EventRouter()
    },
    
    // Storage and Indexing
    storage: {
      eventStore: new EventStore(),
      searchIndex: new ElasticsearchCluster(),
      timeSeriesDB: new TimeSeriesDatabase(),
      graphDB: new GraphDatabase()
    },
    
    // Real-time Distribution
    distribution: {
      websocketServer: new WebSocketServer(),
      pubsubEngine: new PubSubEngine(),
      cacheLayer: new DistributedCache(),
      cdnIntegration: new CDNProvider()
    },
    
    // Analytics and Visualization
    analytics: {
      queryEngine: new AnalyticsQueryEngine(),
      aggregator: new MetricsAggregator(),
      visualizer: new DataVisualizer(),
      insightsEngine: new MLInsightsEngine()
    }
  };
}
```

### Event Collection and Streaming

```typescript
// Distributed event collection from all agents
export class AgentEventCollector {
  private eventStream: EventStream;
  private bufferManager: BufferManager;
  private deduplicator: EventDeduplicator;
  
  async collectAgentEvents(): Promise<void> {
    // Set up event listeners for all agent types
    const agentTypes = [
      'orchestrator', 'analyst', 'pm', 'architect', 
      'design-architect', 'po', 'sm', 'developer', 'qa'
    ];
    
    for (const agentType of agentTypes) {
      await this.setupAgentListener(agentType);
    }
    
    // Process incoming events
    this.eventStream.on('event', async (event) => {
      // Enrich event with context
      const enrichedEvent = await this.enrichEvent(event);
      
      // Deduplicate
      if (await this.deduplicator.isDuplicate(enrichedEvent)) {
        return;
      }
      
      // Route to appropriate handlers
      await this.routeEvent(enrichedEvent);
      
      // Update real-time dashboards
      await this.updateDashboards(enrichedEvent);
      
      // Trigger dependent workflows
      await this.triggerWorkflows(enrichedEvent);
    });
  }
  
  private async setupAgentListener(agentType: string): Promise<void> {
    const listener = new AgentListener({
      agentType: agentType,
      
      eventTypes: [
        'task:created', 'task:updated', 'task:completed',
        'handoff:initiated', 'handoff:accepted', 'handoff:completed',
        'decision:made', 'artifact:created', 'review:requested',
        'block:encountered', 'error:occurred'
      ],
      
      transformer: async (rawEvent) => {
        return {
          id: generateEventId(),
          timestamp: new Date(),
          agentType: agentType,
          agentId: rawEvent.agentId,
          sessionId: rawEvent.sessionId,
          eventType: rawEvent.type,
          
          // Core event data
          data: rawEvent.data,
          
          // Context information
          context: {
            project: rawEvent.context?.project,
            epic: rawEvent.context?.epic,
            story: rawEvent.context?.story,
            parentTask: rawEvent.context?.parentTask,
            dependencies: rawEvent.context?.dependencies
          },
          
          // Metadata
          metadata: {
            version: rawEvent.version,
            source: rawEvent.source,
            correlation: rawEvent.correlationId,
            causation: rawEvent.causationId
          }
        };
      },
      
      // Reliability settings
      reliability: {
        retryAttempts: 3,
        retryDelay: 1000,
        deadLetterQueue: true,
        circuitBreaker: {
          threshold: 5,
          timeout: 30000
        }
      }
    });
    
    await listener.start();
  }
  
  private async enrichEvent(event: AgentEvent): Promise<EnrichedEvent> {
    const enrichers = [
      // Add task hierarchy
      async (e) => {
        if (e.data.taskId) {
          e.enriched.taskHierarchy = await this.getTaskHierarchy(e.data.taskId);
        }
        return e;
      },
      
      // Add agent context
      async (e) => {
        e.enriched.agentContext = await this.getAgentContext(e.agentId);
        return e;
      },
      
      // Add related events
      async (e) => {
        e.enriched.relatedEvents = await this.findRelatedEvents(e);
        return e;
      },
      
      // Add impact analysis
      async (e) => {
        e.enriched.impact = await this.analyzeEventImpact(e);
        return e;
      }
    ];
    
    let enrichedEvent = { ...event, enriched: {} };
    
    for (const enricher of enrichers) {
      enrichedEvent = await enricher(enrichedEvent);
    }
    
    return enrichedEvent;
  }
}
```

### Unified Search and Query System

```typescript
// Federated search across all agent data
export class CrossAgentSearchEngine {
  private searchIndex: DistributedSearchIndex;
  private queryOptimizer: QueryOptimizer;
  private resultAggregator: ResultAggregator;
  
  async search(query: SearchQuery): Promise<SearchResults> {
    // Parse and optimize query
    const optimizedQuery = await this.queryOptimizer.optimize(query);
    
    // Execute distributed search
    const searchPromises = [
      this.searchTasks(optimizedQuery),
      this.searchEvents(optimizedQuery),
      this.searchArtifacts(optimizedQuery),
      this.searchDecisions(optimizedQuery),
      this.searchConversations(optimizedQuery)
    ];
    
    const results = await Promise.all(searchPromises);
    
    // Aggregate and rank results
    const aggregated = await this.resultAggregator.aggregate(results, {
      ranking: {
        algorithm: 'ml-relevance',
        factors: {
          textRelevance: 0.3,
          recency: 0.2,
          agentAuthority: 0.2,
          userContext: 0.3
        }
      },
      
      grouping: {
        enabled: true,
        criteria: ['agent', 'task', 'time']
      },
      
      enrichment: {
        snippets: true,
        highlights: true,
        context: true,
        timeline: true
      }
    });
    
    return aggregated;
  }
  
  private async searchTasks(query: OptimizedQuery): Promise<TaskSearchResults> {
    const taskQuery = {
      index: 'agent-tasks',
      
      query: {
        bool: {
          must: [
            { match: { content: query.text } },
            ...query.filters.map(f => this.buildFilter(f))
          ],
          
          should: [
            { match: { 'metadata.agent': query.context?.preferredAgent } },
            { range: { created: { gte: 'now-7d' } } }
          ],
          
          filter: query.permissions
        }
      },
      
      aggs: {
        by_agent: { terms: { field: 'agent' } },
        by_status: { terms: { field: 'status' } },
        by_priority: { terms: { field: 'priority' } }
      },
      
      highlight: {
        fields: {
          content: {},
          description: {},
          'subtasks.content': {}
        }
      }
    };
    
    return await this.searchIndex.search(taskQuery);
  }
  
  async buildSearchInterface(): Promise<SearchInterface> {
    return new SearchInterface({
      // Natural language processing
      nlp: {
        enabled: true,
        model: 'cross-agent-bert',
        
        intentRecognition: async (query) => {
          // Recognize search intent
          const intents = await this.recognizeIntent(query);
          
          if (intents.includes('find-handoff')) {
            return this.buildHandoffQuery(query);
          } else if (intents.includes('track-progress')) {
            return this.buildProgressQuery(query);
          } else if (intents.includes('find-blocker')) {
            return this.buildBlockerQuery(query);
          }
          
          return this.buildGeneralQuery(query);
        }
      },
      
      // Auto-suggestions
      suggestions: {
        enabled: true,
        
        sources: [
          { type: 'recent-searches', weight: 0.3 },
          { type: 'popular-searches', weight: 0.2 },
          { type: 'contextual', weight: 0.5 }
        ],
        
        realtime: true,
        debounce: 300
      },
      
      // Faceted search
      facets: [
        {
          name: 'agent',
          field: 'metadata.agent',
          type: 'terms',
          size: 10
        },
        {
          name: 'timeRange',
          field: 'timestamp',
          type: 'date_range',
          ranges: [
            { key: 'today', from: 'now/d' },
            { key: 'week', from: 'now-7d' },
            { key: 'month', from: 'now-30d' }
          ]
        },
        {
          name: 'status',
          field: 'status',
          type: 'terms'
        },
        {
          name: 'type',
          field: 'eventType',
          type: 'terms'
        }
      ]
    });
  }
}
```

### Handoff Context Management

```typescript
// Seamless context preservation during agent handoffs
export class HandoffContextManager {
  private contextStore: ContextStore;
  private snapshotEngine: SnapshotEngine;
  private transferProtocol: TransferProtocol;
  
  async initiateHandoff(handoff: HandoffRequest): Promise<HandoffContext> {
    // Capture complete context
    const context = await this.captureContext(handoff);
    
    // Create immutable snapshot
    const snapshot = await this.snapshotEngine.create({
      context: context,
      timestamp: new Date(),
      
      includes: {
        tasks: await this.captureTasks(handoff),
        decisions: await this.captureDecisions(handoff),
        artifacts: await this.captureArtifacts(handoff),
        conversations: await this.captureConversations(handoff),
        state: await this.captureState(handoff)
      },
      
      metadata: {
        fromAgent: handoff.fromAgent,
        toAgent: handoff.toAgent,
        reason: handoff.reason,
        priority: handoff.priority
      }
    });
    
    // Prepare for transfer
    const transfer = await this.transferProtocol.prepare({
      snapshot: snapshot,
      
      optimization: {
        compress: true,
        deduplicate: true,
        prioritize: true
      },
      
      validation: {
        checksum: true,
        signature: true,
        completeness: true
      }
    });
    
    // Notify receiving agent
    await this.notifyReceivingAgent(transfer);
    
    // Track handoff
    await TodoWrite.createTask({
      content: `Handoff: ${handoff.fromAgent} → ${handoff.toAgent}`,
      status: 'in_progress',
      priority: handoff.priority,
      metadata: {
        type: 'handoff',
        handoffId: transfer.id,
        fromAgent: handoff.fromAgent,
        toAgent: handoff.toAgent,
        contextSize: snapshot.size
      }
    });
    
    return transfer;
  }
  
  private async captureContext(handoff: HandoffRequest): Promise<Context> {
    const contextBuilder = new ContextBuilder();
    
    // Capture active tasks
    const activeTasks = await TodoWrite.getTasksByAgent(handoff.fromAgent, {
      status: ['pending', 'in_progress']
    });
    
    // Build task context
    for (const task of activeTasks) {
      await contextBuilder.addTask({
        task: task,
        
        // Include full history
        history: await this.getTaskHistory(task.id),
        
        // Include related artifacts
        artifacts: await this.getTaskArtifacts(task.id),
        
        // Include decisions
        decisions: await this.getTaskDecisions(task.id),
        
        // Include blockers
        blockers: await this.getTaskBlockers(task.id),
        
        // Include dependencies
        dependencies: await this.getTaskDependencies(task.id)
      });
    }
    
    // Capture conversation context
    const conversations = await this.captureConversations(handoff);
    contextBuilder.addConversations(conversations);
    
    // Capture working state
    const workingState = {
      currentFocus: handoff.currentFocus,
      inProgressItems: handoff.inProgressItems,
      pendingDecisions: handoff.pendingDecisions,
      openQuestions: handoff.openQuestions,
      nextSteps: handoff.nextSteps
    };
    contextBuilder.addState(workingState);
    
    return contextBuilder.build();
  }
  
  async acceptHandoff(handoffId: string, agent: Agent): Promise<void> {
    // Retrieve handoff context
    const transfer = await this.transferProtocol.retrieve(handoffId);
    
    // Validate transfer
    const validation = await this.validateTransfer(transfer);
    if (!validation.valid) {
      throw new Error(`Invalid handoff: ${validation.errors.join(', ')}`);
    }
    
    // Restore context
    const restored = await this.restoreContext(transfer.snapshot, agent);
    
    // Update task ownership
    for (const task of restored.tasks) {
      await TodoWrite.updateTask(task.id, {
        assignee: agent.id,
        metadata: {
          ...task.metadata,
          handoffId: handoffId,
          previousOwner: transfer.metadata.fromAgent
        }
      });
    }
    
    // Confirm handoff
    await this.confirmHandoff(handoffId, agent);
    
    // Provide context summary
    await this.provideContextSummary(restored, agent);
  }
  
  private async provideContextSummary(
    restored: RestoredContext, 
    agent: Agent
  ): Promise<void> {
    const summary = {
      overview: `Received ${restored.tasks.length} tasks from ${restored.previousAgent}`,
      
      tasks: {
        total: restored.tasks.length,
        inProgress: restored.tasks.filter(t => t.status === 'in_progress').length,
        pending: restored.tasks.filter(t => t.status === 'pending').length,
        blocked: restored.tasks.filter(t => t.blockers?.length > 0).length
      },
      
      priorities: this.summarizePriorities(restored.tasks),
      
      decisions: {
        pending: restored.decisions.filter(d => d.status === 'pending'),
        recent: restored.decisions.filter(d => 
          d.timestamp > new Date(Date.now() - 24 * 60 * 60 * 1000)
        )
      },
      
      artifacts: {
        count: restored.artifacts.length,
        types: this.categorizeArtifacts(restored.artifacts)
      },
      
      nextActions: this.identifyNextActions(restored)
    };
    
    // Create summary task
    await TodoWrite.createTask({
      content: 'Review handoff context and continue work',
      status: 'in_progress',
      priority: 'high',
      metadata: {
        type: 'handoff-review',
        handoffId: restored.handoffId,
        summary: summary
      },
      description: this.formatHandoffSummary(summary)
    });
  }
}
```

### Real-time Dashboard System

```typescript
// Unified cross-agent dashboard
export class CrossAgentDashboard {
  private websocketServer: WebSocketServer;
  private dashboardEngine: DashboardEngine;
  private layoutManager: LayoutManager;
  
  async initializeDashboard(): Promise<Dashboard> {
    const dashboard = new Dashboard({
      layout: 'adaptive-grid',
      theme: 'professional-dark',
      
      sections: [
        // Agent Activity Stream
        {
          id: 'agent-activity',
          type: 'activity-stream',
          title: 'Live Agent Activity',
          
          config: {
            agents: 'all',
            eventTypes: ['task', 'handoff', 'decision', 'artifact'],
            updateFrequency: 1000,
            maxItems: 50,
            
            visualization: {
              type: 'timeline',
              groupBy: 'agent',
              showConnections: true
            }
          }
        },
        
        // Task Progress Overview
        {
          id: 'task-progress',
          type: 'progress-tracker',
          title: 'Cross-Agent Task Progress',
          
          config: {
            view: 'kanban',
            columns: ['pending', 'in_progress', 'review', 'completed'],
            groupBy: 'agent',
            
            metrics: {
              velocity: true,
              cycleTime: true,
              blockageRate: true
            }
          }
        },
        
        // Handoff Visualization
        {
          id: 'handoff-flow',
          type: 'flow-diagram',
          title: 'Agent Handoff Flow',
          
          config: {
            visualization: 'sankey',
            timeRange: 'last-24h',
            
            nodes: {
              size: 'taskCount',
              color: 'agentType'
            },
            
            edges: {
              width: 'handoffCount',
              color: 'avgDuration'
            }
          }
        },
        
        // Dependency Graph
        {
          id: 'dependencies',
          type: 'graph',
          title: 'Cross-Agent Dependencies',
          
          config: {
            layout: 'force-directed',
            
            highlighting: {
              blockers: 'red',
              critical: 'orange',
              normal: 'green'
            },
            
            interactions: {
              zoom: true,
              pan: true,
              details: true
            }
          }
        },
        
        // Performance Metrics
        {
          id: 'performance',
          type: 'metrics-grid',
          title: 'System Performance',
          
          widgets: [
            {
              metric: 'activeAgents',
              type: 'number',
              format: 'count'
            },
            {
              metric: 'tasksPerHour',
              type: 'sparkline',
              period: '24h'
            },
            {
              metric: 'avgHandoffTime',
              type: 'gauge',
              thresholds: { good: 60, warning: 300, critical: 600 }
            },
            {
              metric: 'blockageRate',
              type: 'percentage',
              trend: true
            }
          ]
        }
      ],
      
      // Real-time updates
      realtime: {
        enabled: true,
        transport: 'websocket',
        
        subscriptions: [
          'agent:*',
          'task:*',
          'handoff:*',
          'system:metrics'
        ],
        
        handlers: {
          'agent:activity': this.handleAgentActivity.bind(this),
          'task:update': this.handleTaskUpdate.bind(this),
          'handoff:initiated': this.handleHandoff.bind(this),
          'system:alert': this.handleSystemAlert.bind(this)
        }
      }
    });
    
    // Set up WebSocket connections
    await this.setupWebSocketServer(dashboard);
    
    // Initialize data streams
    await this.initializeDataStreams(dashboard);
    
    return dashboard;
  }
  
  private async handleAgentActivity(event: AgentActivityEvent): Promise<void> {
    // Update activity stream
    await this.dashboardEngine.updateSection('agent-activity', {
      action: 'append',
      data: {
        id: event.id,
        timestamp: event.timestamp,
        agent: event.agent,
        activity: event.activity,
        details: event.details,
        impact: event.impact
      }
    });
    
    // Update agent status
    await this.updateAgentStatus(event.agent, event.activity);
    
    // Check for anomalies
    if (await this.isAnomalous(event)) {
      await this.highlightAnomaly(event);
    }
  }
  
  async createAnalyticsDashboard(): Promise<AnalyticsDashboard> {
    return new AnalyticsDashboard({
      // Historical Analysis
      historical: {
        queries: [
          {
            name: 'Agent Efficiency Trends',
            query: `
              SELECT agent, 
                     AVG(completion_time) as avg_time,
                     COUNT(*) as task_count,
                     DATE_TRUNC('day', timestamp) as day
              FROM agent_tasks
              WHERE status = 'completed'
              GROUP BY agent, day
              ORDER BY day DESC
            `
          },
          {
            name: 'Handoff Patterns',
            query: `
              WITH handoff_pairs AS (
                SELECT from_agent, to_agent, COUNT(*) as count
                FROM handoffs
                GROUP BY from_agent, to_agent
              )
              SELECT * FROM handoff_pairs
              ORDER BY count DESC
            `
          }
        ]
      },
      
      // Predictive Analytics
      predictive: {
        models: [
          {
            name: 'Task Completion Predictor',
            type: 'regression',
            features: ['agent', 'task_type', 'complexity', 'dependencies'],
            target: 'completion_time'
          },
          {
            name: 'Bottleneck Detector',
            type: 'anomaly-detection',
            features: ['queue_length', 'processing_rate', 'error_rate']
          }
        ]
      },
      
      // Real-time Analytics
      realtime: {
        streams: [
          {
            name: 'Live Performance',
            metrics: ['tasks/sec', 'avg_latency', 'error_rate'],
            window: '5m',
            aggregation: 'sliding'
          }
        ]
      }
    });
  }
}
```

### Cross-Agent Timeline Reconstruction

```typescript
// Reconstruct complete timeline across all agents
export class TimelineReconstructor {
  private eventStore: EventStore;
  private correlator: EventCorrelator;
  private visualizer: TimelineVisualizer;
  
  async reconstructTimeline(params: TimelineParams): Promise<Timeline> {
    // Fetch all relevant events
    const events = await this.fetchEvents(params);
    
    // Correlate events across agents
    const correlated = await this.correlator.correlate(events, {
      strategies: [
        'task-id-matching',
        'temporal-proximity',
        'causal-chain',
        'semantic-similarity'
      ],
      
      confidence: {
        threshold: 0.8,
        factors: {
          temporal: 0.3,
          semantic: 0.4,
          structural: 0.3
        }
      }
    });
    
    // Build timeline structure
    const timeline = await this.buildTimeline(correlated);
    
    // Add rich annotations
    await this.enrichTimeline(timeline);
    
    // Create interactive visualization
    const visualization = await this.visualizer.create(timeline, {
      layout: 'swimlane',
      
      lanes: {
        groupBy: 'agent',
        order: 'chronological',
        height: 'auto'
      },
      
      events: {
        shape: this.getEventShape.bind(this),
        color: this.getEventColor.bind(this),
        size: this.getEventSize.bind(this)
      },
      
      connections: {
        show: true,
        types: ['handoff', 'dependency', 'reference'],
        style: this.getConnectionStyle.bind(this)
      },
      
      interactions: {
        zoom: { min: '1h', max: '1y' },
        pan: true,
        filter: true,
        search: true,
        export: true
      },
      
      tooltips: {
        enabled: true,
        content: this.generateTooltip.bind(this)
      }
    });
    
    return {
      data: timeline,
      visualization: visualization,
      insights: await this.generateInsights(timeline)
    };
  }
  
  private async buildTimeline(events: CorrelatedEvents): Promise<TimelineData> {
    const timeline = new TimelineData();
    
    // Process each event
    for (const event of events) {
      const timelineEvent = {
        id: event.id,
        timestamp: event.timestamp,
        agent: event.agent,
        type: event.type,
        
        // Core data
        title: this.generateTitle(event),
        description: this.generateDescription(event),
        
        // Relationships
        references: event.references || [],
        dependencies: event.dependencies || [],
        blockers: event.blockers || [],
        
        // Context
        context: {
          task: event.taskId ? await this.getTask(event.taskId) : null,
          story: event.storyId ? await this.getStory(event.storyId) : null,
          epic: event.epicId ? await this.getEpic(event.epicId) : null
        },
        
        // Metrics
        metrics: {
          duration: event.duration,
          impact: event.impact,
          complexity: event.complexity
        }
      };
      
      timeline.addEvent(timelineEvent);
    }
    
    // Identify phases
    const phases = await this.identifyPhases(timeline);
    timeline.setPhases(phases);
    
    // Calculate critical path
    const criticalPath = await this.calculateCriticalPath(timeline);
    timeline.setCriticalPath(criticalPath);
    
    return timeline;
  }
  
  private async generateInsights(timeline: TimelineData): Promise<TimelineInsights> {
    const analyzer = new TimelineAnalyzer();
    
    return {
      summary: {
        totalDuration: timeline.getDuration(),
        agentCount: timeline.getUniqueAgents().length,
        eventCount: timeline.getEventCount(),
        handoffCount: timeline.getHandoffCount()
      },
      
      patterns: {
        bottlenecks: await analyzer.findBottlenecks(timeline),
        inefficiencies: await analyzer.findInefficiencies(timeline),
        repetitions: await analyzer.findRepetitions(timeline)
      },
      
      performance: {
        byAgent: await analyzer.analyzeAgentPerformance(timeline),
        byPhase: await analyzer.analyzePhasePerformance(timeline),
        byTaskType: await analyzer.analyzeTaskPerformance(timeline)
      },
      
      recommendations: await analyzer.generateRecommendations(timeline),
      
      anomalies: await analyzer.detectAnomalies(timeline)
    };
  }
}
```

### Dependency Tracking Across Agents

```typescript
// Track and visualize cross-agent dependencies
export class CrossAgentDependencyTracker {
  private dependencyGraph: DependencyGraph;
  private impactAnalyzer: ImpactAnalyzer;
  private resolutionEngine: ResolutionEngine;
  
  async trackDependency(dependency: Dependency): Promise<void> {
    // Add to dependency graph
    await this.dependencyGraph.addDependency({
      id: dependency.id,
      
      source: {
        agent: dependency.sourceAgent,
        task: dependency.sourceTask,
        output: dependency.output
      },
      
      target: {
        agent: dependency.targetAgent,
        task: dependency.targetTask,
        input: dependency.input
      },
      
      metadata: {
        type: dependency.type,
        criticality: dependency.criticality,
        deadline: dependency.deadline,
        status: 'active'
      }
    });
    
    // Analyze impact
    const impact = await this.impactAnalyzer.analyze(dependency);
    
    // Create tracking task if critical
    if (impact.criticality === 'high') {
      await this.createTrackingTask(dependency, impact);
    }
    
    // Set up monitoring
    await this.monitorDependency(dependency);
  }
  
  async visualizeDependencies(scope: DependencyScope): Promise<DependencyVisualization> {
    // Get relevant dependencies
    const dependencies = await this.dependencyGraph.query(scope);
    
    // Create interactive visualization
    return new DependencyVisualization({
      data: dependencies,
      
      layout: {
        type: 'hierarchical',
        direction: 'left-to-right',
        spacing: 'auto'
      },
      
      nodes: {
        shape: (node) => node.type === 'agent' ? 'hexagon' : 'rectangle',
        color: (node) => this.getNodeColor(node),
        size: (node) => this.calculateNodeSize(node),
        
        label: {
          text: (node) => node.name,
          position: 'center'
        }
      },
      
      edges: {
        style: (edge) => ({
          stroke: this.getEdgeColor(edge),
          strokeWidth: this.getEdgeWidth(edge),
          strokeDasharray: edge.status === 'blocked' ? '5,5' : 'none',
          marker: 'arrow'
        }),
        
        label: {
          text: (edge) => edge.dependency,
          position: 'middle'
        }
      },
      
      interactions: {
        onClick: async (element) => {
          if (element.type === 'node') {
            await this.showNodeDetails(element);
          } else if (element.type === 'edge') {
            await this.showDependencyDetails(element);
          }
        },
        
        onHover: (element) => {
          this.highlightPath(element);
        }
      },
      
      analysis: {
        criticalPath: true,
        cycles: true,
        bottlenecks: true
      }
    });
  }
  
  async detectBlockers(): Promise<Blocker[]> {
    const blockers: Blocker[] = [];
    
    // Analyze all active dependencies
    const activeDeps = await this.dependencyGraph.getActive();
    
    for (const dep of activeDeps) {
      // Check if source task is blocking
      if (dep.source.status !== 'completed' && 
          dep.target.status === 'blocked') {
        blockers.push({
          id: `blocker-${dep.id}`,
          
          blocking: {
            agent: dep.source.agent,
            task: dep.source.task
          },
          
          blocked: {
            agent: dep.target.agent,
            task: dep.target.task,
            count: await this.countBlockedTasks(dep.target)
          },
          
          impact: await this.calculateBlockerImpact(dep),
          
          resolution: await this.suggestResolution(dep),
          
          escalation: this.determineEscalation(dep)
        });
      }
    }
    
    // Create blocker resolution tasks
    for (const blocker of blockers) {
      await this.createBlockerTask(blocker);
    }
    
    return blockers;
  }
  
  private async createBlockerTask(blocker: Blocker): Promise<void> {
    await TodoWrite.createTask({
      content: `Resolve Blocker: ${blocker.blocking.task} blocking ${blocker.blocked.count} tasks`,
      status: 'pending',
      priority: 'high',
      
      metadata: {
        type: 'blocker-resolution',
        blockerId: blocker.id,
        blockingAgent: blocker.blocking.agent,
        impact: blocker.impact
      },
      
      subtasks: [
        {
          content: `Contact ${blocker.blocking.agent} agent`,
          assignee: 'orchestrator'
        },
        {
          content: 'Assess blocker severity and alternatives',
          assignee: blocker.blocking.agent
        },
        {
          content: 'Implement resolution',
          assignee: blocker.blocking.agent,
          estimatedHours: blocker.resolution.estimatedEffort
        },
        {
          content: 'Verify unblocking',
          assignee: blocker.blocked.agent
        }
      ]
    });
  }
}
```

### Analytics and Insights Engine

```typescript
// Generate insights from cross-agent data
export class CrossAgentAnalytics {
  private dataWarehouse: DataWarehouse;
  private mlEngine: MLEngine;
  private insightGenerator: InsightGenerator;
  
  async generateInsights(timeRange: TimeRange): Promise<InsightReport> {
    // Collect comprehensive metrics
    const metrics = await this.collectMetrics(timeRange);
    
    // Run ML analysis
    const patterns = await this.mlEngine.analyzePatterns(metrics, {
      algorithms: [
        'clustering',
        'anomaly-detection',
        'trend-analysis',
        'correlation'
      ]
    });
    
    // Generate insights
    const insights = await this.insightGenerator.generate({
      metrics: metrics,
      patterns: patterns,
      
      categories: [
        'efficiency',
        'collaboration',
        'bottlenecks',
        'quality',
        'velocity'
      ],
      
      depth: 'comprehensive'
    });
    
    // Create insight tasks
    await this.createInsightTasks(insights);
    
    return {
      timeRange: timeRange,
      metrics: metrics,
      patterns: patterns,
      insights: insights,
      recommendations: await this.generateRecommendations(insights)
    };
  }
  
  private async collectMetrics(timeRange: TimeRange): Promise<Metrics> {
    const queries = [
      // Agent efficiency metrics
      {
        name: 'agent-efficiency',
        query: `
          WITH agent_metrics AS (
            SELECT 
              agent_type,
              COUNT(DISTINCT task_id) as tasks_completed,
              AVG(completion_time) as avg_completion_time,
              PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY completion_time) as p95_time,
              SUM(CASE WHEN status = 'blocked' THEN 1 ELSE 0 END) as blocked_count
            FROM agent_tasks
            WHERE timestamp BETWEEN $1 AND $2
            GROUP BY agent_type
          )
          SELECT * FROM agent_metrics
        `,
        params: [timeRange.start, timeRange.end]
      },
      
      // Handoff efficiency
      {
        name: 'handoff-efficiency',
        query: `
          SELECT 
            from_agent,
            to_agent,
            COUNT(*) as handoff_count,
            AVG(duration) as avg_duration,
            SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_count
          FROM handoffs
          WHERE timestamp BETWEEN $1 AND $2
          GROUP BY from_agent, to_agent
        `,
        params: [timeRange.start, timeRange.end]
      },
      
      // Task flow metrics
      {
        name: 'task-flow',
        query: `
          WITH task_states AS (
            SELECT 
              task_id,
              status,
              LAG(status) OVER (PARTITION BY task_id ORDER BY timestamp) as prev_status,
              timestamp,
              LAG(timestamp) OVER (PARTITION BY task_id ORDER BY timestamp) as prev_timestamp
            FROM task_events
            WHERE timestamp BETWEEN $1 AND $2
          )
          SELECT 
            prev_status || ' -> ' || status as transition,
            COUNT(*) as count,
            AVG(EXTRACT(EPOCH FROM (timestamp - prev_timestamp))) as avg_duration
          FROM task_states
          WHERE prev_status IS NOT NULL
          GROUP BY transition
        `,
        params: [timeRange.start, timeRange.end]
      }
    ];
    
    const results = await Promise.all(
      queries.map(q => this.dataWarehouse.query(q))
    );
    
    return this.aggregateMetrics(results);
  }
  
  private async generateRecommendations(
    insights: Insights
  ): Promise<Recommendation[]> {
    const recommendations: Recommendation[] = [];
    
    // Analyze bottlenecks
    if (insights.bottlenecks.length > 0) {
      for (const bottleneck of insights.bottlenecks) {
        recommendations.push({
          type: 'process-improvement',
          priority: 'high',
          
          title: `Optimize ${bottleneck.location} bottleneck`,
          
          description: `${bottleneck.agent} is causing delays of ${bottleneck.avgDelay}`,
          
          actions: [
            'Increase parallel processing capacity',
            'Optimize task batching',
            'Consider workload redistribution'
          ],
          
          expectedImpact: {
            metric: 'throughput',
            improvement: '30-40%'
          }
        });
      }
    }
    
    // Analyze collaboration patterns
    const collaborationIssues = insights.patterns.filter(
      p => p.type === 'poor-collaboration'
    );
    
    for (const issue of collaborationIssues) {
      recommendations.push({
        type: 'collaboration',
        priority: 'medium',
        
        title: `Improve ${issue.agents.join(' ↔ ')} collaboration`,
        
        description: `High handoff failure rate (${issue.failureRate}%)`,
        
        actions: [
          'Standardize handoff protocols',
          'Improve context documentation',
          'Add validation checks'
        ],
        
        expectedImpact: {
          metric: 'handoff-success-rate',
          improvement: '50%'
        }
      });
    }
    
    return recommendations;
  }
}
```

### Security and Access Control

```typescript
// Role-based access control for cross-agent visibility
export class VisibilityAccessControl {
  private authProvider: AuthProvider;
  private policyEngine: PolicyEngine;
  private auditLogger: AuditLogger;
  
  async enforceAccess(request: AccessRequest): Promise<AccessDecision> {
    // Authenticate user
    const user = await this.authProvider.authenticate(request.credentials);
    
    // Load user permissions
    const permissions = await this.loadPermissions(user);
    
    // Evaluate access policies
    const decision = await this.policyEngine.evaluate({
      user: user,
      permissions: permissions,
      resource: request.resource,
      action: request.action,
      
      context: {
        time: new Date(),
        ip: request.ip,
        userAgent: request.userAgent
      }
    });
    
    // Audit access attempt
    await this.auditLogger.log({
      user: user.id,
      resource: request.resource,
      action: request.action,
      decision: decision.allowed,
      reason: decision.reason,
      timestamp: new Date()
    });
    
    return decision;
  }
  
  async defineAccessPolicies(): Promise<void> {
    // Define role-based policies
    const policies = [
      {
        role: 'project-manager',
        permissions: [
          'view:all-agents',
          'view:all-tasks',
          'view:all-handoffs',
          'view:analytics',
          'export:reports'
        ]
      },
      {
        role: 'team-member',
        permissions: [
          'view:own-agent',
          'view:related-tasks',
          'view:relevant-handoffs'
        ]
      },
      {
        role: 'stakeholder',
        permissions: [
          'view:progress-summary',
          'view:high-level-metrics',
          'export:status-reports'
        ]
      },
      {
        role: 'admin',
        permissions: ['*'] // All permissions
      }
    ];
    
    await this.policyEngine.definePolicies(policies);
  }
}
```

---

## Test Scenarios

### Happy Path

1. Multiple agents collaborate on complex project
2. Real-time updates flow seamlessly to dashboard
3. Handoffs preserve complete context
4. Search returns relevant results instantly
5. Analytics provide actionable insights

### Edge Cases

1. Agent session crashes during handoff
2. Circular dependencies between agents
3. Search across millions of events
4. Dashboard with 100+ concurrent viewers
5. Handoff chain spanning 10+ agents

### Error Scenarios

1. Network partition during event streaming
2. Storage system becomes unavailable
3. Search index corruption
4. WebSocket connection drops
5. Authentication service timeout

---

## Dev Technical Implementation Examples

### Example 1: Setting Up Cross-Agent Visibility

```typescript
// Initialize cross-agent visibility system
const visibilitySystem = new CrossAgentVisibilitySystem();

await visibilitySystem.initialize({
  eventSources: {
    agents: ['orchestrator', 'analyst', 'pm', 'architect', 'po', 'sm', 'dev', 'qa'],
    hookIntegration: true,
    todoWriteSync: true
  },
  
  storage: {
    eventStore: 'postgresql://events',
    searchIndex: 'elasticsearch://search',
    timeseries: 'influxdb://metrics'
  },
  
  realtime: {
    websocket: { port: 8080 },
    scaling: 'horizontal',
    ssl: true
  }
});

// Start collecting events
await visibilitySystem.startCollection();
```

### Example 2: Performing Cross-Agent Search

```typescript
// Search across all agent data
const searchEngine = new CrossAgentSearchEngine();

const results = await searchEngine.search({
  text: 'authentication implementation',
  
  filters: [
    { field: 'agent', values: ['architect', 'developer'] },
    { field: 'timestamp', range: { from: 'now-7d' } },
    { field: 'status', values: ['in_progress', 'completed'] }
  ],
  
  context: {
    user: 'project-manager',
    project: 'auth-system-v2'
  },
  
  options: {
    highlight: true,
    facets: true,
    timeline: true
  }
});

console.log(`Found ${results.total} matches across ${results.agents.length} agents`);
```

### Example 3: Handling Agent Handoff

```typescript
// Initiate handoff with full context
const handoffManager = new HandoffContextManager();

const handoff = await handoffManager.initiateHandoff({
  fromAgent: 'architect',
  toAgent: 'developer',
  reason: 'Implementation ready after design completion',
  priority: 'high',
  
  context: {
    tasks: ['TASK-123', 'TASK-124'],
    artifacts: ['system-design-v2.pdf', 'api-spec.yaml'],
    decisions: ['ADR-001', 'ADR-002'],
    notes: 'Focus on authentication module first'
  }
});

// Receiving agent accepts handoff
await handoffManager.acceptHandoff(handoff.id, developerAgent);
```

### Example 4: Visualizing Dependencies

```typescript
// Create dependency visualization
const depTracker = new CrossAgentDependencyTracker();

const visualization = await depTracker.visualizeDependencies({
  scope: 'epic',
  epicId: 'EPIC-001',
  
  options: {
    showBlockers: true,
    highlightCriticalPath: true,
    groupByAgent: true
  }
});

// Check for blockers
const blockers = await depTracker.detectBlockers();

if (blockers.length > 0) {
  console.log(`Found ${blockers.length} blockers affecting ${
    blockers.reduce((sum, b) => sum + b.blocked.count, 0)
  } tasks`);
}
```

### Example 5: Generating Analytics Report

```typescript
// Generate cross-agent analytics
const analytics = new CrossAgentAnalytics();

const report = await analytics.generateInsights({
  start: new Date('2024-01-01'),
  end: new Date('2024-01-31')
});

// Display key insights
console.log('Top Insights:');
report.insights.forEach(insight => {
  console.log(`- ${insight.title}: ${insight.finding}`);
  console.log(`  Impact: ${insight.impact}`);
  console.log(`  Recommendation: ${insight.recommendation}`);
});

// Export for stakeholders
await report.export({
  format: 'pdf',
  template: 'executive-summary',
  recipients: ['pm@company.com', 'cto@company.com']
});
```

---

## Monitoring and Observability

```typescript
// Visibility system health monitoring
export class VisibilityHealthMonitor {
  async getHealth(): Promise<SystemHealth> {
    return {
      eventIngestion: {
        rate: await this.getIngestionRate(),
        lag: await this.getProcessingLag(),
        errors: await this.getIngestionErrors()
      },
      
      search: {
        latency: await this.getSearchLatency(),
        availability: await this.getSearchAvailability(),
        indexLag: await this.getIndexLag()
      },
      
      realtime: {
        connectedClients: await this.getConnectedClients(),
        messageRate: await this.getMessageRate(),
        deliveryLatency: await this.getDeliveryLatency()
      },
      
      storage: {
        usage: await this.getStorageUsage(),
        performance: await this.getStoragePerformance(),
        availability: await this.getStorageAvailability()
      }
    };
  }
}
```

---

## Implementation Checklist

- [ ] Set up event collection infrastructure
- [ ] Implement cross-agent search
- [ ] Build handoff context system
- [ ] Create real-time dashboard
- [ ] Implement dependency tracking
- [ ] Build timeline reconstruction
- [ ] Set up analytics engine
- [ ] Configure access control
- [ ] Performance optimization
- [ ] Deploy and monitor

---

## Change Log

| Change | Date - Time | Version | Description | Author |
| Initial Creation | 2024-12-27 - 15:30 | 1.0.0 | Created comprehensive cross-agent visibility story | SM Agent |