#!/usr/bin/env python3
"""
Notification Hook - Executes when notifications are triggered

This hook receives JSON input when Claude Code wants to send notifications.
Can be used for desktop notifications, sound alerts, or external integrations.

Input format (via stdin):
{
    "type": "notification_type",
    "message": "notification message",
    "level": "info/warning/error",
    "context": {...}
}

Return:
- Exit code 0: Success
- Exit code 1: Error
- JSON output (stdout): Optional response data
"""

import sys
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler('/tmp/notification.log')]
)
logger = logging.getLogger(__name__)


def main():
    """Main hook entry point"""
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        logger.info(f"Notification hook triggered: {input_data}")
        
        # Extract notification information
        notification_type = input_data.get('type', 'general')
        message = input_data.get('message', '')
        level = input_data.get('level', 'info')
        context = input_data.get('context', {})
        
        # Add your custom logic here
        # Example: Send desktop notification, play sound, send to Slack, etc.
        
        # For now, just log the notification
        timestamp = datetime.now().isoformat()
        logger.info(f"[{timestamp}] {level.upper()}: {message}")
        
        # Example: You could implement OS-specific notifications
        # if sys.platform == "darwin":  # macOS
        #     os.system(f'osascript -e \'display notification "{message}" with title "Claude Code"\'')
        # elif sys.platform == "linux":
        #     os.system(f'notify-send "Claude Code" "{message}"')
        
        # Call notification manager for audio/TTS notifications
        import subprocess
        import os
        
        # Get notification manager path
        ap_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        notification_manager = os.path.join(ap_root, 'agents', 'scripts', 'notification-manager.sh')
        
        if os.path.exists(notification_manager):
            # Call notification manager
            subprocess.run([
                notification_manager, 'notify', 'notification',
                context.get('persona', 'orchestrator'),
                f"{level}: {message}. {context.get('details', '')}"
            ], capture_output=True)
        
        # Return success
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Error in Notification hook: {e}")
        # On error, exit gracefully
        sys.exit(1)


if __name__ == "__main__":
    main()