#!/usr/bin/env python3
"""
SubagentStop Hook - Executes when a subagent stops

This hook is triggered when a subagent (launched via Task tool) completes.
Useful for processing subagent results, cleanup, or triggering follow-up actions.

Input format (via stdin):
{
    "agent_id": "unique_agent_id",
    "task_description": "what the agent was doing",
    "result": {...},
    "success": true/false,
    "duration": 12345,
    "context": {...}
}

Return:
- Exit code 0: Success
- Exit code 1: Error (logged but doesn't affect subagent result)
- JSON output (stdout): Optional processing results
"""

import sys
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler('/tmp/subagent_stop.log')]
)
logger = logging.getLogger(__name__)


def main():
    """Main hook entry point"""
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        logger.info(f"SubagentStop hook triggered: {input_data}")
        
        # Extract subagent information
        agent_id = input_data.get('agent_id', 'unknown')
        task_description = input_data.get('task_description', 'No description')
        result = input_data.get('result', {})
        success = input_data.get('success', True)
        duration = input_data.get('duration', 0)
        context = input_data.get('context', {})
        
        # Add your custom logic here
        # Example: Process results, update tracking, trigger next steps, etc.
        
        # Log subagent completion
        timestamp = datetime.now().isoformat()
        status = "succeeded" if success else "failed"
        logger.info(f"[{timestamp}] Subagent {agent_id} {status}")
        logger.info(f"Task: {task_description}")
        logger.info(f"Duration: {duration} seconds")
        
        # Example: You could aggregate results from multiple subagents
        # results_file = f"/tmp/subagent_results.json"
        # existing_results = []
        # if os.path.exists(results_file):
        #     with open(results_file, 'r') as f:
        #         existing_results = json.load(f)
        # existing_results.append({
        #     'timestamp': timestamp,
        #     'agent_id': agent_id,
        #     'task': task_description,
        #     'success': success,
        #     'duration': duration
        # })
        # with open(results_file, 'w') as f:
        #     json.dump(existing_results, f, indent=2)
        
        # Call notification manager for audio/TTS notifications
        import subprocess
        import os
        
        # Get notification manager path
        ap_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        notification_manager = os.path.join(ap_root, 'agents', 'scripts', 'notification-manager.sh')
        
        if os.path.exists(notification_manager):
            # Call notification manager
            status_text = "completed successfully" if success else "failed"
            subprocess.run([
                notification_manager, 'notify', 'subagent_stop',
                context.get('persona', 'orchestrator'),
                f"Subagent {status_text}: {task_description}"
            ], capture_output=True)
        
        # Return success
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Error in SubagentStop hook: {e}")
        # On error, exit gracefully
        sys.exit(1)


if __name__ == "__main__":
    main()