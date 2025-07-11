"""
Repository pattern implementation for task persistence.

Provides abstraction for data storage with multiple backend options.
"""

import json
import sqlite3
from abc import ABC, abstractmethod
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any
from uuid import UUID
import asyncio
import aiosqlite

from ..domain.entities import Task, TaskStatus, Priority, AgentType


class TaskRepository(ABC):
    """Abstract base class for task persistence."""
    
    @abstractmethod
    async def save(self, task: Task) -> None:
        """Save or update a task."""
        pass
    
    @abstractmethod
    async def get(self, task_id: UUID) -> Optional[Task]:
        """Get a task by ID."""
        pass
    
    @abstractmethod
    async def list(self) -> List[Task]:
        """List all tasks."""
        pass
    
    @abstractmethod
    async def delete(self, task_id: UUID) -> bool:
        """Delete a task by ID."""
        pass
    
    @abstractmethod
    async def clear(self) -> None:
        """Clear all tasks."""
        pass


class InMemoryRepository(TaskRepository):
    """In-memory task storage for testing and development."""
    
    def __init__(self):
        self._tasks: Dict[UUID, Task] = {}
        self._lock = asyncio.Lock()
    
    async def save(self, task: Task) -> None:
        """Save task in memory."""
        async with self._lock:
            self._tasks[task.id] = task
    
    async def get(self, task_id: UUID) -> Optional[Task]:
        """Get task from memory."""
        async with self._lock:
            return self._tasks.get(task_id)
    
    async def list(self) -> List[Task]:
        """List all tasks from memory."""
        async with self._lock:
            return list(self._tasks.values())
    
    async def delete(self, task_id: UUID) -> bool:
        """Delete task from memory."""
        async with self._lock:
            if task_id in self._tasks:
                del self._tasks[task_id]
                return True
            return False
    
    async def clear(self) -> None:
        """Clear all tasks from memory."""
        async with self._lock:
            self._tasks.clear()


class JSONFileRepository(TaskRepository):
    """JSON file-based task storage."""
    
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self._lock = asyncio.Lock()
        self._ensure_file()
    
    def _ensure_file(self) -> None:
        """Ensure the JSON file exists."""
        if not self.file_path.exists():
            self.file_path.parent.mkdir(parents=True, exist_ok=True)
            self.file_path.write_text("[]")
    
    async def _read_tasks(self) -> List[Task]:
        """Read tasks from JSON file."""
        try:
            content = self.file_path.read_text()
            data = json.loads(content) if content else []
            return [Task.from_dict(task_data) for task_data in data]
        except (json.JSONDecodeError, IOError):
            return []
    
    async def _write_tasks(self, tasks: List[Task]) -> None:
        """Write tasks to JSON file."""
        data = [task.to_dict() for task in tasks]
        self.file_path.write_text(json.dumps(data, indent=2))
    
    async def save(self, task: Task) -> None:
        """Save task to JSON file."""
        async with self._lock:
            tasks = await self._read_tasks()
            
            # Update existing or add new
            updated = False
            for i, existing in enumerate(tasks):
                if existing.id == task.id:
                    tasks[i] = task
                    updated = True
                    break
            
            if not updated:
                tasks.append(task)
            
            await self._write_tasks(tasks)
    
    async def get(self, task_id: UUID) -> Optional[Task]:
        """Get task from JSON file."""
        async with self._lock:
            tasks = await self._read_tasks()
            for task in tasks:
                if task.id == task_id:
                    return task
            return None
    
    async def list(self) -> List[Task]:
        """List all tasks from JSON file."""
        async with self._lock:
            return await self._read_tasks()
    
    async def delete(self, task_id: UUID) -> bool:
        """Delete task from JSON file."""
        async with self._lock:
            tasks = await self._read_tasks()
            original_count = len(tasks)
            tasks = [t for t in tasks if t.id != task_id]
            
            if len(tasks) < original_count:
                await self._write_tasks(tasks)
                return True
            return False
    
    async def clear(self) -> None:
        """Clear all tasks from JSON file."""
        async with self._lock:
            await self._write_tasks([])


class SQLiteRepository(TaskRepository):
    """SQLite-based task storage for production use."""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self._initialized = False
    
    async def _ensure_initialized(self) -> None:
        """Ensure database is initialized."""
        if self._initialized:
            return
        
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            await db.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    status TEXT NOT NULL,
                    priority TEXT NOT NULL,
                    story_id TEXT,
                    epic_id TEXT,
                    assignee TEXT,
                    labels TEXT,
                    metadata TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    started_at TEXT,
                    completed_at TEXT,
                    metrics TEXT,
                    events TEXT
                )
            """)
            
            # Create indexes
            await db.execute("CREATE INDEX IF NOT EXISTS idx_status ON tasks(status)")
            await db.execute("CREATE INDEX IF NOT EXISTS idx_assignee ON tasks(assignee)")
            await db.execute("CREATE INDEX IF NOT EXISTS idx_story_id ON tasks(story_id)")
            
            await db.commit()
        
        self._initialized = True
    
    def _task_to_row(self, task: Task) -> tuple:
        """Convert task to database row."""
        return (
            str(task.id),
            task.title,
            task.description,
            task.status.value,
            task.priority.value,
            str(task.story_id) if task.story_id else None,
            str(task.epic_id) if task.epic_id else None,
            task.assignee.value if task.assignee else None,
            json.dumps(task.labels),
            json.dumps(task.metadata),
            task.created_at.isoformat() if task.created_at else None,
            task.updated_at.isoformat() if task.updated_at else None,
            task.started_at.isoformat() if task.started_at else None,
            task.completed_at.isoformat() if task.completed_at else None,
            json.dumps(task.metrics.to_dict()),
            json.dumps([e.to_apm_format() for e in task.events[-100:]])  # Last 100 events
        )
    
    def _row_to_task(self, row: tuple) -> Task:
        """Convert database row to task."""
        task = Task()
        
        task.id = UUID(row[0])
        task.title = row[1]
        task.description = row[2] or ""
        task.status = TaskStatus(row[3])
        task.priority = Priority(row[4])
        
        if row[5]:
            task.story_id = UUID(row[5])
        if row[6]:
            task.epic_id = UUID(row[6])
        if row[7]:
            task.assignee = AgentType(row[7])
        
        task.labels = json.loads(row[8])
        task.metadata = json.loads(row[9])
        
        # Parse timestamps
        if row[10]:
            task.created_at = datetime.fromisoformat(row[10])
        if row[11]:
            task.updated_at = datetime.fromisoformat(row[11])
        if row[12]:
            task.started_at = datetime.fromisoformat(row[12])
        if row[13]:
            task.completed_at = datetime.fromisoformat(row[13])
        
        # Parse metrics
        metrics_data = json.loads(row[14])
        for key, value in metrics_data.items():
            setattr(task.metrics, key, value)
        
        # Note: Events are not fully restored from DB (would need separate table)
        
        return task
    
    async def save(self, task: Task) -> None:
        """Save task to SQLite."""
        await self._ensure_initialized()
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            await db.execute("""
                INSERT OR REPLACE INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, self._task_to_row(task))
            await db.commit()
    
    async def get(self, task_id: UUID) -> Optional[Task]:
        """Get task from SQLite."""
        await self._ensure_initialized()
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            async with db.execute(
                "SELECT * FROM tasks WHERE id = ?",
                (str(task_id),)
            ) as cursor:
                row = await cursor.fetchone()
                if row:
                    return self._row_to_task(row)
                return None
    
    async def list(self) -> List[Task]:
        """List all tasks from SQLite."""
        await self._ensure_initialized()
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            async with db.execute("SELECT * FROM tasks") as cursor:
                rows = await cursor.fetchall()
                return [self._row_to_task(row) for row in rows]
    
    async def delete(self, task_id: UUID) -> bool:
        """Delete task from SQLite."""
        await self._ensure_initialized()
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            cursor = await db.execute(
                "DELETE FROM tasks WHERE id = ?",
                (str(task_id),)
            )
            await db.commit()
            return cursor.rowcount > 0
    
    async def clear(self) -> None:
        """Clear all tasks from SQLite."""
        await self._ensure_initialized()
        
        async with aiosqlite.connect(str(self.db_path)) as db:
            await db.execute("DELETE FROM tasks")
            await db.commit()


def create_repository(storage_type: str = "memory", **kwargs) -> TaskRepository:
    """Factory function to create repository instances."""
    repositories = {
        "memory": InMemoryRepository,
        "json": JSONFileRepository,
        "sqlite": SQLiteRepository,
    }
    
    if storage_type not in repositories:
        raise ValueError(f"Unknown storage type: {storage_type}")
    
    return repositories[storage_type](**kwargs)