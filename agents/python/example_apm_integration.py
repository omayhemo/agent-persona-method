#!/usr/bin/env python3
"""
Example demonstrating APM integration with the Python task manager.

This shows how the new Python implementation provides rich observability
compared to the Bash scripts.
"""

import asyncio
import random
from datetime import datetime, timedelta
from pathlib import Path

# Add the package to path for demo
import sys
sys.path.insert(0, str(Path(__file__).parent))

from ap_task_manager import TaskService, Priority, AgentType, TaskStatus
from ap_task_manager.infrastructure.apm import create_apm_provider
from ap_task_manager.infrastructure.repository import create_repository
from ap_task_manager.infrastructure.events import EventType


async def simulate_task_lifecycle():
    """Simulate a complete task lifecycle with APM tracking."""
    
    print("🚀 AP Task Manager - APM Integration Demo")
    print("=" * 50)
    
    # Create service with console APM (visible output)
    apm = create_apm_provider("console", verbose=True)
    repository = create_repository("memory")  # In-memory for demo
    service = TaskService(repository=repository, apm_provider=apm)
    
    # Subscribe to events for demo
    def on_task_created(task, *args):
        print(f"📢 Event: Task created - {task.title}")
    
    def on_task_completed(task, *args):
        duration = task.metrics.total_duration
        if duration:
            print(f"📢 Event: Task completed in {duration:.1f} seconds")
    
    service.event_bus.subscribe(EventType.TASK_CREATED, on_task_created)
    service.event_bus.subscribe(EventType.TASK_COMPLETED, on_task_completed)
    
    print("\n1️⃣ Creating tasks with different priorities...")
    
    # Create multiple tasks
    tasks = []
    for i in range(5):
        priority = random.choice(list(Priority))
        assignee = random.choice(list(AgentType))
        
        task = await service.create_task(
            title=f"Task {i+1}: Implement feature #{i+1}",
            description=f"This is a demo task with {priority.value} priority",
            priority=priority,
            assignee=assignee,
            labels=["demo", "apm-test"],
            metadata={"demo_id": i+1}
        )
        tasks.append(task)
        await asyncio.sleep(0.1)  # Small delay for realistic timing
    
    print(f"\n✅ Created {len(tasks)} tasks")
    
    print("\n2️⃣ Simulating task progress...")
    
    # Simulate work on tasks
    for i, task in enumerate(tasks[:3]):  # Work on first 3 tasks
        # Start task
        await service.transition_status(
            task.id,
            TaskStatus.IN_PROGRESS,
            actor="demo-worker"
        )
        
        # Simulate work time
        work_time = random.uniform(0.5, 2.0)
        print(f"   ⏳ Working on task {i+1} for {work_time:.1f} seconds...")
        await asyncio.sleep(work_time)
        
        # Complete or fail randomly
        if random.random() > 0.2:  # 80% success rate
            await service.transition_status(
                task.id,
                TaskStatus.COMPLETED,
                actor="demo-worker"
            )
        else:
            await service.transition_status(
                task.id,
                TaskStatus.FAILED,
                actor="demo-worker"
            )
    
    print("\n3️⃣ Querying tasks with filters...")
    
    # Query examples
    pending_tasks = await service.query_tasks(status=TaskStatus.PENDING)
    print(f"   📋 Pending tasks: {len(pending_tasks)}")
    
    high_priority = await service.query_tasks(priority=Priority.HIGH)
    print(f"   🔥 High priority tasks: {len(high_priority)}")
    
    dev_tasks = await service.query_tasks(assignee=AgentType.DEVELOPER)
    print(f"   👨‍💻 Developer tasks: {len(dev_tasks)}")
    
    print("\n4️⃣ Generating metrics summary...")
    
    # Get metrics
    summary = await service.get_metrics_summary()
    
    print("\n📊 Task Metrics Summary:")
    print(f"   Total tasks: {summary['total_tasks']}")
    print(f"   By status: {summary['by_status']}")
    print(f"   By priority: {summary['by_priority']}")
    print(f"   Completion rate: {summary['completion_rate']:.1%}")
    
    if summary['average_duration']:
        print(f"   Average duration: {summary['average_duration']:.1f} seconds")
    
    # Flush APM data
    await apm.flush()
    
    print("\n5️⃣ Demonstrating event history...")
    
    # Show event history
    history = service.event_bus.get_history(limit=5)
    print(f"\n📜 Recent events ({len(history)} total):")
    for event in history[-5:]:
        print(f"   - {event.type.value} at {event.timestamp.strftime('%H:%M:%S')}")
    
    print("\n" + "=" * 50)
    print("✨ Demo completed! This demonstrates:")
    print("   - Automatic APM span creation for all operations")
    print("   - Metric collection (counters, histograms)")
    print("   - Event-driven architecture with pub/sub")
    print("   - Rich task lifecycle tracking")
    print("   - Performance measurement")
    print("\n🎯 In production, these metrics would go to:")
    print("   - OpenTelemetry → Jaeger/Tempo (traces)")
    print("   - Prometheus → Grafana (metrics)")
    print("   - Event stream → Kafka/RabbitMQ (events)")


async def demonstrate_batch_operations():
    """Show how batch operations are optimized with APM."""
    
    print("\n\n🔄 Batch Operations Demo")
    print("=" * 50)
    
    # Create service
    apm = create_apm_provider("console", verbose=True)
    service = TaskService(apm_provider=apm)
    
    print("\n Creating 20 tasks in batch...")
    
    # Create many tasks
    tasks = []
    for i in range(20):
        task = await service.create_task(
            title=f"Batch task {i+1}",
            priority=Priority.MEDIUM,
            assignee=AgentType.DEVELOPER
        )
        tasks.append(task)
    
    print(f"\n✅ Created {len(tasks)} tasks")
    
    print("\n📦 Updating all tasks to IN_PROGRESS in batch...")
    
    # Batch update simulation
    start_time = datetime.utcnow()
    
    # In a real implementation, this would be a single batch operation
    update_tasks = []
    for task in tasks:
        updated = await service.transition_status(
            task.id,
            TaskStatus.IN_PROGRESS,
            actor="batch-processor"
        )
        update_tasks.append(updated)
    
    duration = (datetime.utcnow() - start_time).total_seconds()
    
    print(f"\n⚡ Batch update completed in {duration:.2f} seconds")
    print(f"   Rate: {len(tasks)/duration:.1f} tasks/second")
    
    # Show how this would be even faster with true batch operations
    print("\n💡 With true batch operations in Python:")
    print("   - Single database transaction")
    print("   - One APM span for entire batch")
    print("   - 10-20x performance improvement")
    print("   - Atomic operations (all or nothing)")


async def demonstrate_plugin_system():
    """Show the plugin architecture."""
    
    print("\n\n🔌 Plugin System Demo")
    print("=" * 50)
    
    # Create a custom plugin
    class MetricsCollectorPlugin:
        def __init__(self):
            self.task_count = 0
            self.total_duration = 0
            
        async def on_task_created(self, task):
            self.task_count += 1
            print(f"   📊 Plugin: Task count is now {self.task_count}")
            
        async def on_task_completed(self, task):
            if task.metrics.total_duration:
                self.total_duration += task.metrics.total_duration
                avg = self.total_duration / self.task_count
                print(f"   📊 Plugin: Average duration is {avg:.1f}s")
    
    # Create service with plugin
    service = TaskService()
    plugin = MetricsCollectorPlugin()
    service.register_plugin(plugin)
    
    print("\n Creating tasks with plugin monitoring...")
    
    # Create and complete tasks
    for i in range(3):
        task = await service.create_task(
            title=f"Plugin demo task {i+1}",
            priority=Priority.LOW
        )
        
        await asyncio.sleep(random.uniform(0.1, 0.3))
        
        await service.transition_status(
            task.id, TaskStatus.IN_PROGRESS, "demo"
        )
        
        await asyncio.sleep(random.uniform(0.2, 0.5))
        
        await service.transition_status(
            task.id, TaskStatus.COMPLETED, "demo"
        )
    
    print("\n✨ Plugin collected metrics automatically!")


async def main():
    """Run all demonstrations."""
    
    # Basic APM integration
    await simulate_task_lifecycle()
    
    # Batch operations
    await demonstrate_batch_operations()
    
    # Plugin system
    await demonstrate_plugin_system()
    
    print("\n\n🎉 All demonstrations completed!")
    print("\n📚 Key advantages over Bash implementation:")
    print("   1. Rich observability with APM integration")
    print("   2. Event-driven architecture")
    print("   3. Plugin system for extensibility")
    print("   4. Type safety and error handling")
    print("   5. Async operations for performance")
    print("   6. Structured data with validation")
    print("   7. Multiple storage backends")
    print("   8. Batch operation optimization")


if __name__ == "__main__":
    asyncio.run(main())