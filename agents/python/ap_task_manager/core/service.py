"""
Core task management service with APM integration.

This module provides the main business logic for task operations.
"""

import asyncio
import json
import re
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any, Callable, Set
from uuid import UUID

from ..domain.entities import Task, TaskStatus, Priority, AgentType, TaskEvent
from ..infrastructure.apm import APMProvider, MetricType
from ..infrastructure.events import EventBus, EventType
from ..infrastructure.repository import TaskRepository


class TaskService:
    """Main service for task management operations."""
    
    def __init__(
        self,
        repository: Optional[TaskRepository] = None,
        apm_provider: Optional[APMProvider] = None,
        event_bus: Optional[EventBus] = None
    ):
        self.repository = repository or TaskRepository()
        self.apm = apm_provider
        self.event_bus = event_bus or EventBus()
        self._plugins: List[Any] = []
        
    async def create_task(
        self,
        title: str,
        description: str = "",
        priority: Priority = Priority.MEDIUM,
        assignee: Optional[AgentType] = None,
        story_id: Optional[UUID] = None,
        labels: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Task:
        """Create a new task with APM tracking."""
        # Start APM span
        with self._apm_span("task.create") as span:
            # Create task
            task = Task(
                title=title,
                description=description,
                priority=priority,
                assignee=assignee,
                story_id=story_id,
                labels=labels or [],
                metadata=metadata or {}
            )
            
            # Add creation event
            task.add_event("created", "system", {
                "priority": priority.value,
                "assignee": assignee.value if assignee else None
            })
            
            # Save to repository
            await self.repository.save(task)
            
            # Emit event
            await self.event_bus.emit(EventType.TASK_CREATED, task)
            
            # Record metrics
            if self.apm:
                await self.apm.record_metric(
                    MetricType.COUNTER,
                    "task.created",
                    1,
                    {
                        "priority": priority.value,
                        "assignee": assignee.value if assignee else "unassigned"
                    }
                )
            
            # Set span attributes
            if span:
                span.set_attribute("task.id", str(task.id))
                span.set_attribute("task.priority", priority.value)
            
            return task
    
    async def update_task(
        self,
        task_id: UUID,
        updates: Dict[str, Any],
        actor: str = "system"
    ) -> Optional[Task]:
        """Update a task with change tracking."""
        with self._apm_span("task.update") as span:
            # Get existing task
            task = await self.repository.get(task_id)
            if not task:
                return None
            
            # Track what changed
            changes = {}
            
            # Update fields
            if "title" in updates and updates["title"] != task.title:
                changes["title"] = {"from": task.title, "to": updates["title"]}
                task.title = updates["title"]
            
            if "description" in updates and updates["description"] != task.description:
                changes["description"] = {"updated": True}
                task.description = updates["description"]
            
            if "priority" in updates:
                new_priority = Priority(updates["priority"])
                if new_priority != task.priority:
                    changes["priority"] = {"from": task.priority.value, "to": new_priority.value}
                    task.priority = new_priority
            
            if "assignee" in updates:
                new_assignee = AgentType(updates["assignee"]) if updates["assignee"] else None
                if new_assignee != task.assignee:
                    changes["assignee"] = {
                        "from": task.assignee.value if task.assignee else None,
                        "to": new_assignee.value if new_assignee else None
                    }
                    task.assignee = new_assignee
            
            if "labels" in updates:
                changes["labels"] = {"updated": True}
                task.labels = updates["labels"]
            
            # Update metadata
            if "metadata" in updates:
                task.metadata.update(updates["metadata"])
                changes["metadata"] = {"updated": True}
            
            # Only save if there were changes
            if changes:
                task.updated_at = datetime.utcnow()
                task.add_event("updated", actor, changes)
                
                await self.repository.save(task)
                await self.event_bus.emit(EventType.TASK_UPDATED, task, changes)
                
                # Record metrics
                if self.apm:
                    await self.apm.record_metric(
                        MetricType.COUNTER,
                        "task.updated",
                        1,
                        {"fields_changed": len(changes)}
                    )
            
            return task
    
    async def transition_status(
        self,
        task_id: UUID,
        new_status: TaskStatus,
        actor: str = "system"
    ) -> Optional[Task]:
        """Transition a task to a new status."""
        with self._apm_span("task.transition_status") as span:
            task = await self.repository.get(task_id)
            if not task:
                return None
            
            old_status = task.status
            
            # Attempt transition
            if not task.transition_to(new_status, actor):
                # Invalid transition
                if self.apm:
                    await self.apm.record_metric(
                        MetricType.COUNTER,
                        "task.transition.invalid",
                        1,
                        {
                            "from": old_status.value,
                            "to": new_status.value
                        }
                    )
                return None
            
            # Save updated task
            await self.repository.save(task)
            
            # Emit status change event
            await self.event_bus.emit(
                EventType.TASK_STATUS_CHANGED,
                task,
                {"from": old_status, "to": new_status}
            )
            
            # Record metrics
            if self.apm:
                await self.apm.record_metric(
                    MetricType.COUNTER,
                    "task.transition",
                    1,
                    {
                        "from": old_status.value,
                        "to": new_status.value
                    }
                )
                
                # Record duration metrics for completion
                if new_status in [TaskStatus.COMPLETED, TaskStatus.FAILED]:
                    if task.metrics.total_duration:
                        await self.apm.record_metric(
                            MetricType.HISTOGRAM,
                            "task.duration",
                            task.metrics.total_duration,
                            {
                                "status": new_status.value,
                                "priority": task.priority.value
                            }
                        )
            
            return task
    
    async def extract_tasks_from_story(self, story_file: Path) -> List[Task]:
        """Extract tasks from a story markdown file."""
        with self._apm_span("task.extract_from_story") as span:
            if not story_file.exists():
                raise FileNotFoundError(f"Story file not found: {story_file}")
            
            content = story_file.read_text()
            tasks = []
            
            # Parse story metadata
            story_id = self._extract_story_id(content)
            
            # Extract task sections
            task_pattern = re.compile(
                r'### Task (\d+(?:\.\d+)*): (.+?)\n'
                r'(.*?)'
                r'(?=### Task|\Z)',
                re.DOTALL
            )
            
            for match in task_pattern.finditer(content):
                task_num = match.group(1)
                title = match.group(2).strip()
                content_block = match.group(3).strip()
                
                # Extract description and metadata
                description_lines = []
                assignee = None
                priority = Priority.MEDIUM
                labels = []
                
                for line in content_block.split('\n'):
                    if line.startswith('**Assignee:**'):
                        assignee_str = line.replace('**Assignee:**', '').strip()
                        try:
                            assignee = AgentType(assignee_str.lower())
                        except ValueError:
                            pass
                    elif line.startswith('**Priority:**'):
                        priority_str = line.replace('**Priority:**', '').strip()
                        try:
                            priority = Priority(priority_str.lower())
                        except ValueError:
                            pass
                    elif line.startswith('**Labels:**'):
                        labels_str = line.replace('**Labels:**', '').strip()
                        labels = [l.strip() for l in labels_str.split(',')]
                    elif line.strip():
                        description_lines.append(line)
                
                description = '\n'.join(description_lines)
                
                # Create task
                task = await self.create_task(
                    title=f"[{task_num}] {title}",
                    description=description,
                    priority=priority,
                    assignee=assignee,
                    story_id=story_id,
                    labels=labels,
                    metadata={
                        "source": str(story_file),
                        "task_number": task_num,
                        "extracted_at": datetime.utcnow().isoformat()
                    }
                )
                
                tasks.append(task)
            
            # Record extraction metrics
            if self.apm:
                await self.apm.record_metric(
                    MetricType.COUNTER,
                    "task.extracted",
                    len(tasks),
                    {"source": "story_file"}
                )
            
            if span:
                span.set_attribute("tasks.count", len(tasks))
                span.set_attribute("story.file", str(story_file))
            
            return tasks
    
    async def query_tasks(
        self,
        status: Optional[TaskStatus] = None,
        assignee: Optional[AgentType] = None,
        priority: Optional[Priority] = None,
        story_id: Optional[UUID] = None,
        labels: Optional[List[str]] = None,
        created_after: Optional[datetime] = None,
        limit: Optional[int] = None
    ) -> List[Task]:
        """Query tasks with filters."""
        with self._apm_span("task.query") as span:
            # Get all tasks from repository
            all_tasks = await self.repository.list()
            
            # Apply filters
            filtered_tasks = []
            for task in all_tasks:
                if status and task.status != status:
                    continue
                if assignee and task.assignee != assignee:
                    continue
                if priority and task.priority != priority:
                    continue
                if story_id and task.story_id != story_id:
                    continue
                if labels and not any(label in task.labels for label in labels):
                    continue
                if created_after and task.created_at < created_after:
                    continue
                
                filtered_tasks.append(task)
            
            # Sort by priority and creation date
            filtered_tasks.sort(
                key=lambda t: (-t.priority.weight, t.created_at),
                reverse=False
            )
            
            # Apply limit
            if limit:
                filtered_tasks = filtered_tasks[:limit]
            
            # Record query metrics
            if self.apm:
                await self.apm.record_metric(
                    MetricType.COUNTER,
                    "task.query",
                    1,
                    {
                        "result_count": len(filtered_tasks),
                        "has_filters": bool(status or assignee or priority or story_id or labels)
                    }
                )
            
            return filtered_tasks
    
    async def get_metrics_summary(self) -> Dict[str, Any]:
        """Get summary metrics for all tasks."""
        tasks = await self.repository.list()
        
        summary = {
            "total_tasks": len(tasks),
            "by_status": {},
            "by_priority": {},
            "by_assignee": {},
            "average_duration": None,
            "completion_rate": 0.0
        }
        
        # Count by status
        for status in TaskStatus:
            count = sum(1 for t in tasks if t.status == status)
            if count > 0:
                summary["by_status"][status.value] = count
        
        # Count by priority
        for priority in Priority:
            count = sum(1 for t in tasks if t.priority == priority)
            if count > 0:
                summary["by_priority"][priority.value] = count
        
        # Count by assignee
        assignee_counts = {}
        for task in tasks:
            if task.assignee:
                assignee_key = task.assignee.value
                assignee_counts[assignee_key] = assignee_counts.get(assignee_key, 0) + 1
        summary["by_assignee"] = assignee_counts
        
        # Calculate average duration for completed tasks
        completed_tasks = [t for t in tasks if t.status == TaskStatus.COMPLETED and t.metrics.total_duration]
        if completed_tasks:
            avg_duration = sum(t.metrics.total_duration for t in completed_tasks) / len(completed_tasks)
            summary["average_duration"] = avg_duration
        
        # Calculate completion rate
        if tasks:
            completed_count = len([t for t in tasks if t.status == TaskStatus.COMPLETED])
            summary["completion_rate"] = completed_count / len(tasks)
        
        return summary
    
    def _extract_story_id(self, content: str) -> Optional[UUID]:
        """Extract story ID from markdown content."""
        # Look for story ID in frontmatter or metadata
        id_pattern = re.compile(r'story[_-]id:\s*([a-f0-9-]+)', re.IGNORECASE)
        match = id_pattern.search(content)
        if match:
            try:
                return UUID(match.group(1))
            except ValueError:
                pass
        return None
    
    def _apm_span(self, operation: str):
        """Create APM span context manager."""
        if self.apm:
            return self.apm.span(operation)
        
        # Null context manager
        class NullSpan:
            def __enter__(self):
                return self
            def __exit__(self, *args):
                pass
            def set_attribute(self, key, value):
                pass
        
        return NullSpan()
    
    def register_plugin(self, plugin: Any):
        """Register a plugin for task lifecycle hooks."""
        self._plugins.append(plugin)
        
        # Subscribe plugin to events
        if hasattr(plugin, 'on_task_created'):
            self.event_bus.subscribe(
                EventType.TASK_CREATED,
                plugin.on_task_created
            )
        
        if hasattr(plugin, 'on_task_updated'):
            self.event_bus.subscribe(
                EventType.TASK_UPDATED,
                plugin.on_task_updated
            )
        
        if hasattr(plugin, 'on_task_status_changed'):
            self.event_bus.subscribe(
                EventType.TASK_STATUS_CHANGED,
                plugin.on_task_status_changed
            )