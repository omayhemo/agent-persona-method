"""
Event bus implementation for task lifecycle events.

Provides pub/sub functionality for decoupled event handling.
"""

import asyncio
from enum import Enum
from typing import Dict, List, Callable, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import logging


logger = logging.getLogger(__name__)


class EventType(Enum):
    """Task lifecycle event types."""
    TASK_CREATED = "task.created"
    TASK_UPDATED = "task.updated"
    TASK_DELETED = "task.deleted"
    TASK_STATUS_CHANGED = "task.status_changed"
    TASK_ASSIGNED = "task.assigned"
    TASK_COMPLETED = "task.completed"
    TASK_FAILED = "task.failed"
    TASK_BLOCKED = "task.blocked"
    TASK_ARCHIVED = "task.archived"
    
    # Batch events
    BATCH_CREATED = "batch.created"
    BATCH_UPDATED = "batch.updated"
    
    # System events
    EXTRACTION_STARTED = "extraction.started"
    EXTRACTION_COMPLETED = "extraction.completed"
    METRICS_COLLECTED = "metrics.collected"


@dataclass
class Event:
    """Event data structure."""
    type: EventType
    timestamp: datetime
    data: Any
    metadata: Optional[Dict[str, Any]] = None
    correlation_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "type": self.type.value,
            "timestamp": self.timestamp.isoformat(),
            "data": self.data,
            "metadata": self.metadata,
            "correlation_id": self.correlation_id
        }


class EventBus:
    """
    Asynchronous event bus for task events.
    
    Supports both sync and async handlers with error isolation.
    """
    
    def __init__(self):
        self._subscribers: Dict[EventType, List[Callable]] = {}
        self._event_history: List[Event] = []
        self._history_limit = 1000
        self._error_handlers: List[Callable] = []
        
    def subscribe(
        self,
        event_type: EventType,
        handler: Callable,
        priority: int = 0
    ) -> None:
        """
        Subscribe to an event type.
        
        Args:
            event_type: The type of event to subscribe to
            handler: Callable that will receive (event, *args)
            priority: Higher priority handlers are called first
        """
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        
        # Insert handler maintaining priority order
        handlers = self._subscribers[event_type]
        insert_pos = 0
        
        # Find insertion position based on priority
        for i, (_, existing_priority) in enumerate(handlers):
            if priority > existing_priority:
                break
            insert_pos = i + 1
        
        handlers.insert(insert_pos, (handler, priority))
        logger.debug(f"Subscribed {handler.__name__} to {event_type.value}")
    
    def unsubscribe(self, event_type: EventType, handler: Callable) -> None:
        """Unsubscribe from an event type."""
        if event_type in self._subscribers:
            self._subscribers[event_type] = [
                (h, p) for h, p in self._subscribers[event_type]
                if h != handler
            ]
    
    async def emit(
        self,
        event_type: EventType,
        data: Any,
        *args,
        metadata: Optional[Dict[str, Any]] = None,
        correlation_id: Optional[str] = None
    ) -> None:
        """
        Emit an event to all subscribers.
        
        Args:
            event_type: Type of event
            data: Primary event data (usually the task)
            *args: Additional arguments passed to handlers
            metadata: Optional event metadata
            correlation_id: Optional correlation ID for tracing
        """
        event = Event(
            type=event_type,
            timestamp=datetime.utcnow(),
            data=data,
            metadata=metadata,
            correlation_id=correlation_id
        )
        
        # Add to history
        self._add_to_history(event)
        
        # Get subscribers for this event type
        handlers = self._subscribers.get(event_type, [])
        
        # Also get wildcard subscribers if implemented
        # handlers.extend(self._subscribers.get(EventType.ALL, []))
        
        logger.debug(
            f"Emitting {event_type.value} to {len(handlers)} handlers"
        )
        
        # Execute handlers
        for handler, _ in handlers:
            try:
                # Check if handler is async
                if asyncio.iscoroutinefunction(handler):
                    await handler(data, *args)
                else:
                    # Run sync handler in thread pool to avoid blocking
                    await asyncio.get_event_loop().run_in_executor(
                        None, handler, data, *args
                    )
            except Exception as e:
                logger.error(
                    f"Error in event handler {handler.__name__}: {e}",
                    exc_info=True
                )
                # Call error handlers
                for error_handler in self._error_handlers:
                    try:
                        await self._call_handler(
                            error_handler,
                            event,
                            handler,
                            e
                        )
                    except Exception as eh_error:
                        logger.error(
                            f"Error in error handler: {eh_error}",
                            exc_info=True
                        )
    
    def add_error_handler(self, handler: Callable) -> None:
        """Add a handler for errors in event processing."""
        self._error_handlers.append(handler)
    
    def _add_to_history(self, event: Event) -> None:
        """Add event to history with size limit."""
        self._event_history.append(event)
        
        # Trim history if needed
        if len(self._event_history) > self._history_limit:
            self._event_history = self._event_history[-self._history_limit:]
    
    def get_history(
        self,
        event_type: Optional[EventType] = None,
        limit: int = 100
    ) -> List[Event]:
        """Get event history, optionally filtered by type."""
        history = self._event_history
        
        if event_type:
            history = [e for e in history if e.type == event_type]
        
        return history[-limit:]
    
    async def _call_handler(self, handler: Callable, *args) -> Any:
        """Call handler with proper async/sync handling."""
        if asyncio.iscoroutinefunction(handler):
            return await handler(*args)
        else:
            return await asyncio.get_event_loop().run_in_executor(
                None, handler, *args
            )
    
    def clear(self) -> None:
        """Clear all subscribers and history."""
        self._subscribers.clear()
        self._event_history.clear()
        self._error_handlers.clear()
    
    def get_subscriber_count(self, event_type: Optional[EventType] = None) -> int:
        """Get count of subscribers for an event type or all types."""
        if event_type:
            return len(self._subscribers.get(event_type, []))
        else:
            return sum(len(handlers) for handlers in self._subscribers.values())


# Global event bus instance (can be overridden)
_global_event_bus = EventBus()


def get_event_bus() -> EventBus:
    """Get the global event bus instance."""
    return _global_event_bus


def set_event_bus(bus: EventBus) -> None:
    """Set a custom global event bus instance."""
    global _global_event_bus
    _global_event_bus = bus