#!/usr/bin/env python3
"""
Stop Hook - Executes when Claude Code stops

This hook is triggered when Claude Code is about to stop or exit.
Useful for cleanup tasks, final logging, or saving state.

Input format (via stdin):
{
    "reason": "user_requested/error/completion",
    "session_duration": 12345,
    "tools_used": [...],
    "context": {...}
}

Return:
- Exit code 0: Success
- Exit code 1: Error (logged but doesn't prevent Claude from stopping)
- JSON output (stdout): Optional final messages
"""

import sys
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler('/tmp/stop.log')]
)
logger = logging.getLogger(__name__)


def main():
    """Main hook entry point"""
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        logger.info(f"Stop hook triggered: {input_data}")
        
        # Extract stop information
        reason = input_data.get('reason', 'unknown')
        session_duration = input_data.get('session_duration', 0)
        tools_used = input_data.get('tools_used', [])
        context = input_data.get('context', {})
        
        # Add your custom logic here
        # Example: Save session state, cleanup temp files, send summary, etc.
        
        # Log session summary
        timestamp = datetime.now().isoformat()
        logger.info(f"Session ended at {timestamp}")
        logger.info(f"Reason: {reason}")
        logger.info(f"Duration: {session_duration} seconds")
        logger.info(f"Tools used: {', '.join(tools_used) if tools_used else 'None'}")
        
        # Example: You could save session state
        # session_file = f"/tmp/claude_session_{timestamp}.json"
        # with open(session_file, 'w') as f:
        #     json.dump(input_data, f, indent=2)
        
        # Call notification manager for audio/TTS notifications
        import subprocess
        import os
        
        # Get notification manager path
        ap_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        notification_manager = os.path.join(ap_root, 'agents', 'scripts', 'notification-manager.sh')
        
        if os.path.exists(notification_manager):
            # Call notification manager
            subprocess.run([
                notification_manager, 'notify', 'stop',
                context.get('persona', 'orchestrator'),
                f"Session ended: {reason}"
            ], capture_output=True)
        
        # Return success
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Error in Stop hook: {e}")
        # On error, exit gracefully
        sys.exit(1)


if __name__ == "__main__":
    main()