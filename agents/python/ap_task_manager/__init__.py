"""
AP Task Manager - Python-based task management system with APM integration.

This package provides a modern, extensible task management system for the AP Mapping,
replacing the legacy Bash scripts with a robust Python implementation.
"""

__version__ = "0.1.0"
__author__ = "AP Mapping Team"

from .domain.entities import Task, TaskStatus, Priority, AgentType
from .core.service import TaskService
from .api.client import TaskClient

__all__ = [
    "Task",
    "TaskStatus", 
    "Priority",
    "AgentType",
    "TaskService",
    "TaskClient",
]