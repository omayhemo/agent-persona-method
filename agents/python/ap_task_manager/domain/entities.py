"""
Domain entities for task management.

This module defines the core business entities used throughout the task management system.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from uuid import UUID, uuid4


class TaskStatus(Enum):
    """Task lifecycle states."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    BLOCKED = "blocked"
    FAILED = "failed"
    ARCHIVED = "archived"
    
    def can_transition_to(self, new_status: 'TaskStatus') -> bool:
        """Check if transition to new status is valid."""
        valid_transitions = {
            TaskStatus.PENDING: [TaskStatus.IN_PROGRESS, TaskStatus.BLOCKED, TaskStatus.ARCHIVED],
            TaskStatus.IN_PROGRESS: [TaskStatus.COMPLETED, TaskStatus.BLOCKED, TaskStatus.FAILED],
            TaskStatus.BLOCKED: [TaskStatus.IN_PROGRESS, TaskStatus.FAILED, TaskStatus.ARCHIVED],
            TaskStatus.COMPLETED: [TaskStatus.ARCHIVED],
            TaskStatus.FAILED: [TaskStatus.IN_PROGRESS, TaskStatus.ARCHIVED],
            TaskStatus.ARCHIVED: []  # Terminal state
        }
        return new_status in valid_transitions.get(self, [])


class Priority(Enum):
    """Task priority levels."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    
    @property
    def weight(self) -> int:
        """Numeric weight for sorting."""
        weights = {
            Priority.CRITICAL: 4,
            Priority.HIGH: 3,
            Priority.MEDIUM: 2,
            Priority.LOW: 1
        }
        return weights[self]


class AgentType(Enum):
    """AP Mapping agent types."""
    ORCHESTRATOR = "orchestrator"
    DEVELOPER = "developer"
    ARCHITECT = "architect"
    ANALYST = "analyst"
    QA = "qa"
    PM = "pm"
    PO = "po"
    SM = "sm"
    DESIGN_ARCHITECT = "design_architect"


@dataclass
class TaskMetrics:
    """Performance and tracking metrics for a task."""
    time_to_start: Optional[float] = None  # Seconds from creation to start
    time_in_progress: Optional[float] = None  # Seconds in progress
    total_duration: Optional[float] = None  # Total seconds to completion
    state_changes: int = 0
    blocks_encountered: int = 0
    retry_count: int = 0
    
    # APM-specific metrics
    cpu_time: Optional[float] = None
    memory_usage: Optional[float] = None
    api_calls: int = 0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for APM export."""
        return {
            k: v for k, v in self.__dict__.items() 
            if v is not None and v != 0
        }


@dataclass
class TaskEvent:
    """Event representing a state change or action on a task."""
    id: UUID = field(default_factory=uuid4)
    task_id: UUID = field(default_factory=uuid4)
    event_type: str = ""
    timestamp: datetime = field(default_factory=datetime.utcnow)
    actor: str = ""
    details: Dict[str, Any] = field(default_factory=dict)
    correlation_id: Optional[UUID] = None
    
    def to_apm_format(self) -> Dict[str, Any]:
        """Format for APM systems."""
        return {
            "event_id": str(self.id),
            "task_id": str(self.task_id),
            "type": self.event_type,
            "timestamp": self.timestamp.isoformat(),
            "actor": self.actor,
            "details": self.details,
            "correlation_id": str(self.correlation_id) if self.correlation_id else None
        }


@dataclass
class Task:
    """Core task entity."""
    id: UUID = field(default_factory=uuid4)
    title: str = ""
    description: str = ""
    status: TaskStatus = TaskStatus.PENDING
    priority: Priority = Priority.MEDIUM
    story_id: Optional[UUID] = None
    epic_id: Optional[UUID] = None
    assignee: Optional[AgentType] = None
    labels: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    # Timestamps
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    # APM tracking
    metrics: TaskMetrics = field(default_factory=TaskMetrics)
    events: List[TaskEvent] = field(default_factory=list)
    
    def add_event(self, event_type: str, actor: str, details: Optional[Dict] = None) -> TaskEvent:
        """Add an event to the task's history."""
        event = TaskEvent(
            task_id=self.id,
            event_type=event_type,
            actor=actor,
            details=details or {}
        )
        self.events.append(event)
        return event
    
    def transition_to(self, new_status: TaskStatus, actor: str) -> bool:
        """Transition task to a new status with validation."""
        if not self.status.can_transition_to(new_status):
            return False
        
        old_status = self.status
        self.status = new_status
        self.updated_at = datetime.utcnow()
        
        # Update timestamps based on transition
        if new_status == TaskStatus.IN_PROGRESS and not self.started_at:
            self.started_at = datetime.utcnow()
            if self.created_at:
                self.metrics.time_to_start = (self.started_at - self.created_at).total_seconds()
        
        elif new_status in [TaskStatus.COMPLETED, TaskStatus.FAILED]:
            self.completed_at = datetime.utcnow()
            if self.started_at:
                self.metrics.time_in_progress = (self.completed_at - self.started_at).total_seconds()
            if self.created_at:
                self.metrics.total_duration = (self.completed_at - self.created_at).total_seconds()
        
        # Track state changes
        self.metrics.state_changes += 1
        if new_status == TaskStatus.BLOCKED:
            self.metrics.blocks_encountered += 1
        
        # Add event
        self.add_event(
            event_type=f"status_changed",
            actor=actor,
            details={
                "from": old_status.value,
                "to": new_status.value
            }
        )
        
        return True
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": str(self.id),
            "title": self.title,
            "description": self.description,
            "status": self.status.value,
            "priority": self.priority.value,
            "story_id": str(self.story_id) if self.story_id else None,
            "epic_id": str(self.epic_id) if self.epic_id else None,
            "assignee": self.assignee.value if self.assignee else None,
            "labels": self.labels,
            "metadata": self.metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "metrics": self.metrics.to_dict(),
            "events": [e.to_apm_format() for e in self.events[-10:]]  # Last 10 events
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Task':
        """Create task from dictionary."""
        task = cls()
        
        # Basic fields
        if 'id' in data:
            task.id = UUID(data['id'])
        task.title = data.get('title', '')
        task.description = data.get('description', '')
        
        # Enums
        if 'status' in data:
            task.status = TaskStatus(data['status'])
        if 'priority' in data:
            task.priority = Priority(data['priority'])
        if 'assignee' in data and data['assignee']:
            task.assignee = AgentType(data['assignee'])
        
        # Optional fields
        if 'story_id' in data and data['story_id']:
            task.story_id = UUID(data['story_id'])
        if 'epic_id' in data and data['epic_id']:
            task.epic_id = UUID(data['epic_id'])
        
        task.labels = data.get('labels', [])
        task.metadata = data.get('metadata', {})
        
        # Timestamps
        for field_name in ['created_at', 'updated_at', 'started_at', 'completed_at']:
            if field_name in data and data[field_name]:
                setattr(task, field_name, datetime.fromisoformat(data[field_name]))
        
        return task