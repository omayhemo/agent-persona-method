# Task Management API Design

## Overview

The Python Task Management API provides a robust, extensible foundation for managing tasks within the AP Method framework, with built-in APM integration capabilities.

## Core Architecture

### Design Principles
1. **Domain-Driven Design** - Clear separation of concerns
2. **Event-Driven** - All state changes emit events for APM
3. **Plugin Architecture** - Extensible for custom integrations
4. **Type Safety** - Full type hints and runtime validation
5. **Async-First** - Built for performance and concurrency

### Component Architecture

```
┌──────────────────────────────────────────────────────┐
│                   API Gateway                         │
│  (REST API / CLI Interface / SDK)                    │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│              Task Service Layer                       │
│                                                      │
│  • Task Operations (CRUD)                            │
│  • Query Engine                                      │
│  • Batch Processing                                  │
│  • Event Publishing                                  │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│              Domain Layer                            │
│                                                      │
│  • Task Entity                                       │
│  • Story Entity                                      │
│  • Epic Entity                                       │
│  • Value Objects                                     │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│           Infrastructure Layer                        │
│                                                      │
│  • Repository Pattern                                │
│  • Event Bus                                         │
│  • APM Integration                                   │
│  • Cache Layer                                       │
└──────────────────────────────────────────────────────┘
```

## Domain Models

### Task Entity
```python
@dataclass
class Task:
    id: TaskId
    title: str
    description: str
    status: TaskStatus
    priority: Priority
    story_id: Optional[StoryId]
    epic_id: Optional[EpicId]
    assignee: Optional[AgentType]
    labels: List[str]
    metadata: Dict[str, Any]
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    
    # APM-specific fields
    metrics: TaskMetrics
    events: List[TaskEvent]
```

### Task Status Lifecycle
```
PENDING → IN_PROGRESS → COMPLETED
    ↓          ↓           ↓
  BLOCKED   FAILED     ARCHIVED
```

### Event Model
```python
@dataclass
class TaskEvent:
    id: EventId
    task_id: TaskId
    event_type: EventType
    timestamp: datetime
    actor: str
    details: Dict[str, Any]
    correlation_id: Optional[str]
```

## API Endpoints

### REST API Design
```
POST   /api/v1/tasks              # Create task
GET    /api/v1/tasks              # List tasks (with filtering)
GET    /api/v1/tasks/{id}         # Get task details
PUT    /api/v1/tasks/{id}         # Update task
DELETE /api/v1/tasks/{id}         # Delete task
POST   /api/v1/tasks/batch        # Batch operations
GET    /api/v1/tasks/search       # Advanced search
POST   /api/v1/tasks/{id}/events  # Add custom event
GET    /api/v1/tasks/metrics      # Get metrics
```

### Query Language
```python
# Example query syntax
tasks = await task_service.query(
    Query()
    .filter(status=TaskStatus.IN_PROGRESS)
    .filter(assignee=AgentType.DEVELOPER)
    .filter(created_after=datetime.now() - timedelta(days=7))
    .sort_by("priority", descending=True)
    .limit(10)
)
```

## APM Integration

### Metrics Collection
```python
class TaskMetrics:
    # Timing metrics
    time_to_start: Optional[timedelta]
    time_in_progress: Optional[timedelta]
    total_duration: Optional[timedelta]
    
    # State change metrics
    state_changes: int
    blocks_encountered: int
    retry_count: int
    
    # Performance metrics
    cpu_time: Optional[float]
    memory_usage: Optional[float]
    api_calls: int
```

### OpenTelemetry Integration
```python
# Automatic tracing for all operations
@trace_operation("task.create")
async def create_task(self, task_data: TaskCreateRequest) -> Task:
    span = trace.get_current_span()
    span.set_attribute("task.priority", task_data.priority)
    span.set_attribute("task.assignee", task_data.assignee)
    
    # Business logic with automatic metric collection
    task = await self._create_task_internal(task_data)
    
    # Emit metrics
    metrics.task_created.inc(
        labels={"priority": task.priority, "assignee": task.assignee}
    )
    
    return task
```

### Event Streaming
```python
# Real-time event streaming for monitoring
class TaskEventStream:
    async def subscribe(self, 
                       event_types: List[EventType],
                       callback: Callable[[TaskEvent], Awaitable[None]]):
        """Subscribe to real-time task events"""
        
    async def publish(self, event: TaskEvent):
        """Publish event to all subscribers and APM"""
```

## Plugin Architecture

### Plugin Interface
```python
class TaskPlugin(ABC):
    @abstractmethod
    async def on_task_created(self, task: Task) -> None:
        """Called when a task is created"""
    
    @abstractmethod
    async def on_task_updated(self, task: Task, changes: Dict) -> None:
        """Called when a task is updated"""
    
    @abstractmethod
    async def on_task_completed(self, task: Task) -> None:
        """Called when a task is completed"""
```

### Example APM Plugin
```python
class PrometheusAPMPlugin(TaskPlugin):
    def __init__(self, prometheus_gateway: str):
        self.gateway = prometheus_gateway
        self._init_metrics()
    
    async def on_task_created(self, task: Task):
        self.tasks_created.labels(
            priority=task.priority,
            assignee=task.assignee
        ).inc()
    
    async def on_task_completed(self, task: Task):
        duration = (task.completed_at - task.created_at).total_seconds()
        self.task_duration.labels(
            priority=task.priority,
            assignee=task.assignee
        ).observe(duration)
```

## CLI Compatibility Layer

### Backward Compatible Commands
```bash
# Original Bash command
./extract-tasks.sh story.md

# New Python equivalent (same interface)
ap-tasks extract story.md

# Or using Python directly
python -m ap_task_manager.cli extract story.md
```

### Bridge Implementation
```python
# Maintains exact same output format as Bash scripts
class LegacyCLI:
    def extract_tasks(self, story_file: Path) -> None:
        """Extract tasks maintaining Bash script output format"""
        tasks = self.task_service.extract_from_story(story_file)
        
        # Format output exactly like Bash script
        for task in tasks:
            print(f"[{task.id}] {task.title}")
            if task.description:
                print(f"  {task.description}")
```

## Performance Optimizations

### Caching Strategy
```python
class TaskCache:
    # LRU cache for frequently accessed tasks
    # Redis for distributed caching
    # Invalidation on updates
```

### Batch Operations
```python
# Optimize for bulk operations
async def update_tasks_batch(self, updates: List[TaskUpdate]) -> List[Task]:
    async with self.db.transaction():
        tasks = await asyncio.gather(*[
            self._update_single(update) for update in updates
        ])
    
    # Single APM event for batch
    await self.apm.record_batch_operation(
        operation="task.update.batch",
        count=len(updates),
        duration=timer.elapsed()
    )
    
    return tasks
```

## Security Considerations

### Authentication & Authorization
```python
@require_permission("task.create")
async def create_task(self, request: TaskCreateRequest, user: User) -> Task:
    # Audit trail
    audit_log.record(
        action="task.create",
        user=user.id,
        resource="task",
        details=request.dict()
    )
```

### Input Validation
```python
class TaskCreateRequest(BaseModel):
    title: constr(min_length=1, max_length=200)
    description: Optional[constr(max_length=2000)]
    priority: Priority
    assignee: Optional[AgentType]
    
    @validator('title')
    def sanitize_title(cls, v):
        # Prevent injection attacks
        return sanitize_markdown(v)
```

## Testing Strategy

### Unit Tests
```python
@pytest.mark.asyncio
async def test_task_creation_emits_metrics():
    # Arrange
    mock_apm = Mock()
    service = TaskService(apm=mock_apm)
    
    # Act
    task = await service.create_task(
        TaskCreateRequest(title="Test", priority=Priority.HIGH)
    )
    
    # Assert
    mock_apm.record_metric.assert_called_with(
        "task.created",
        tags={"priority": "high"}
    )
```

### Integration Tests
```python
@pytest.mark.integration
async def test_full_task_lifecycle():
    # Test complete flow with real APM integration
    async with TestEnvironment() as env:
        # Create, update, complete task
        # Verify metrics in APM
        # Check event stream
```

## Migration Path

### Phase 1: Parallel Implementation
```python
# Wrapper to call both old and new systems
class MigrationWrapper:
    async def extract_tasks(self, story_file: Path):
        # Call new Python implementation
        python_tasks = await self.new_system.extract(story_file)
        
        # Call old Bash implementation
        bash_tasks = await self.run_bash_script(
            "extract-tasks.sh", story_file
        )
        
        # Compare results
        if not self._results_match(python_tasks, bash_tasks):
            self.log_discrepancy(python_tasks, bash_tasks)
        
        # Return based on feature flag
        if self.use_new_system:
            return python_tasks
        return bash_tasks
```

### Phase 2: Gradual Cutover
- Feature flags for each operation
- Monitoring for discrepancies
- Performance comparison
- User feedback collection

### Phase 3: Deprecation
- Remove Bash script calls
- Archive old implementations
- Update all documentation
- Final performance validation