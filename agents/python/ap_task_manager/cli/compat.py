"""
Backward compatibility layer for existing Bash scripts.

This module provides CLI commands that match the interface of the original
Bash scripts, ensuring seamless migration.
"""

import asyncio
import json
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Optional
import click

from ..core.service import TaskService
from ..domain.entities import TaskStatus, Priority, AgentType
from ..infrastructure.repository import create_repository
from ..infrastructure.apm import create_apm_provider


# Global service instance (initialized on first use)
_service: Optional[TaskService] = None


def get_service() -> TaskService:
    """Get or create the task service instance."""
    global _service
    if _service is None:
        # Use JSON repository by default for compatibility
        repo_path = Path.home() / ".ap" / "tasks.json"
        repository = create_repository("json", file_path=repo_path)
        
        # Use console APM for visibility
        apm = create_apm_provider("console", verbose=False)
        
        _service = TaskService(repository=repository, apm_provider=apm)
    
    return _service


@click.group()
def cli():
    """AP Task Manager - Python implementation compatible with Bash scripts."""
    pass


@cli.command()
@click.argument('story_file', type=click.Path(exists=True))
@click.option('--verbose', '-v', is_flag=True, help='Verbose output')
def extract(story_file: str, verbose: bool):
    """
    Extract tasks from a story file.
    
    Compatible with: ./extract-tasks.sh story.md
    """
    async def _extract():
        service = get_service()
        story_path = Path(story_file)
        
        try:
            tasks = await service.extract_tasks_from_story(story_path)
            
            # Output in same format as Bash script
            for task in tasks:
                # Extract task number from title
                if task.title.startswith('['):
                    end_bracket = task.title.find(']')
                    if end_bracket > 0:
                        task_num = task.title[1:end_bracket]
                        title = task.title[end_bracket+1:].strip()
                    else:
                        task_num = ""
                        title = task.title
                else:
                    task_num = ""
                    title = task.title
                
                # Main output line
                print(f"Task {task_num}: {title}")
                
                # Additional details if verbose
                if verbose:
                    if task.assignee:
                        print(f"  Assignee: {task.assignee.value}")
                    if task.priority != Priority.MEDIUM:
                        print(f"  Priority: {task.priority.value}")
                    if task.description:
                        print(f"  Description: {task.description[:100]}...")
                    print()
            
            # Summary line like Bash script
            print(f"\nExtracted {len(tasks)} tasks from {story_file}")
            
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    asyncio.run(_extract())


@cli.command()
@click.option('--status', '-s', type=click.Choice(['pending', 'in_progress', 'completed', 'blocked', 'failed', 'archived']))
@click.option('--assignee', '-a', type=str)
@click.option('--priority', '-p', type=click.Choice(['critical', 'high', 'medium', 'low']))
@click.option('--story', type=str, help='Story ID')
@click.option('--format', '-f', type=click.Choice(['simple', 'detailed', 'json']), default='simple')
def query(status: Optional[str], assignee: Optional[str], priority: Optional[str], 
         story: Optional[str], format: str):
    """
    Query tasks with filters.
    
    Compatible with: ./query-tasks.sh [options]
    """
    async def _query():
        service = get_service()
        
        # Build query parameters
        query_params = {}
        
        if status:
            query_params['status'] = TaskStatus(status)
        
        if assignee:
            try:
                query_params['assignee'] = AgentType(assignee.lower())
            except ValueError:
                print(f"Warning: Unknown assignee '{assignee}'", file=sys.stderr)
        
        if priority:
            query_params['priority'] = Priority(priority)
        
        # Note: story parameter would need UUID parsing in real implementation
        
        try:
            tasks = await service.query_tasks(**query_params)
            
            if format == 'json':
                # JSON output
                output = [task.to_dict() for task in tasks]
                print(json.dumps(output, indent=2))
            
            elif format == 'detailed':
                # Detailed output
                for task in tasks:
                    print(f"ID: {task.id}")
                    print(f"Title: {task.title}")
                    print(f"Status: {task.status.value}")
                    print(f"Priority: {task.priority.value}")
                    if task.assignee:
                        print(f"Assignee: {task.assignee.value}")
                    if task.description:
                        print(f"Description: {task.description}")
                    print(f"Created: {task.created_at.strftime('%Y-%m-%d %H:%M')}")
                    print("-" * 40)
            
            else:
                # Simple output (default) - matches Bash script format
                for task in tasks:
                    status_symbol = {
                        TaskStatus.PENDING: "○",
                        TaskStatus.IN_PROGRESS: "◐",
                        TaskStatus.COMPLETED: "●",
                        TaskStatus.BLOCKED: "□",
                        TaskStatus.FAILED: "✗",
                        TaskStatus.ARCHIVED: "▪"
                    }.get(task.status, "?")
                    
                    assignee_str = f" @{task.assignee.value}" if task.assignee else ""
                    print(f"{status_symbol} {task.title}{assignee_str}")
            
            # Summary
            if format != 'json':
                print(f"\nTotal: {len(tasks)} tasks")
            
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    asyncio.run(_query())


@cli.command()
@click.argument('task_id')
@click.argument('new_status', type=click.Choice(['pending', 'in_progress', 'completed', 'blocked', 'failed']))
@click.option('--actor', '-u', default='cli', help='Who is making the update')
def update(task_id: str, new_status: str, actor: str):
    """
    Update task status.
    
    Compatible with: ./update-task.sh TASK_ID STATUS
    """
    async def _update():
        service = get_service()
        
        try:
            # In real implementation, would need to handle task ID lookup
            # For now, assume it's a UUID
            from uuid import UUID
            task_uuid = UUID(task_id)
            
            task = await service.transition_status(
                task_uuid,
                TaskStatus(new_status),
                actor
            )
            
            if task:
                print(f"✓ Task {task_id} updated to {new_status}")
                
                # Show transition time if applicable
                if task.status == TaskStatus.COMPLETED and task.metrics.total_duration:
                    duration_hours = task.metrics.total_duration / 3600
                    print(f"  Completed in {duration_hours:.1f} hours")
            else:
                print(f"✗ Failed to update task {task_id}", file=sys.stderr)
                print("  Task may not exist or transition may be invalid", file=sys.stderr)
                sys.exit(1)
                
        except ValueError as e:
            print(f"Error: Invalid task ID format", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    asyncio.run(_update())


@cli.command()
@click.option('--days', '-d', type=int, default=30, help='Archive tasks completed more than N days ago')
@click.option('--dry-run', is_flag=True, help='Show what would be archived without doing it')
def archive(days: int, dry_run: bool):
    """
    Archive completed tasks.
    
    Compatible with: ./archive-tasks.sh
    """
    async def _archive():
        service = get_service()
        
        try:
            # Query completed tasks
            tasks = await service.query_tasks(status=TaskStatus.COMPLETED)
            
            # Filter by age
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            tasks_to_archive = [
                task for task in tasks
                if task.completed_at and task.completed_at < cutoff_date
            ]
            
            if dry_run:
                print(f"Would archive {len(tasks_to_archive)} tasks:")
                for task in tasks_to_archive:
                    print(f"  - {task.title} (completed {task.completed_at.strftime('%Y-%m-%d')})")
            else:
                archived_count = 0
                for task in tasks_to_archive:
                    result = await service.transition_status(
                        task.id,
                        TaskStatus.ARCHIVED,
                        "archive-cli"
                    )
                    if result:
                        archived_count += 1
                
                print(f"✓ Archived {archived_count} tasks")
                
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    from datetime import timedelta
    asyncio.run(_archive())


@cli.command()
def stats():
    """
    Show task statistics.
    
    Additional command for monitoring.
    """
    async def _stats():
        service = get_service()
        
        try:
            summary = await service.get_metrics_summary()
            
            print("Task Statistics")
            print("=" * 40)
            print(f"Total Tasks: {summary['total_tasks']}")
            print()
            
            print("By Status:")
            for status, count in summary['by_status'].items():
                print(f"  {status}: {count}")
            print()
            
            print("By Priority:")
            for priority, count in summary['by_priority'].items():
                print(f"  {priority}: {count}")
            print()
            
            print("By Assignee:")
            if summary['by_assignee']:
                for assignee, count in summary['by_assignee'].items():
                    print(f"  {assignee}: {count}")
            else:
                print("  (none assigned)")
            print()
            
            if summary['average_duration']:
                avg_hours = summary['average_duration'] / 3600
                print(f"Average Task Duration: {avg_hours:.1f} hours")
            
            if summary['completion_rate']:
                print(f"Completion Rate: {summary['completion_rate']:.1%}")
                
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    asyncio.run(_stats())


def main():
    """Main entry point for CLI."""
    cli()


if __name__ == '__main__':
    main()