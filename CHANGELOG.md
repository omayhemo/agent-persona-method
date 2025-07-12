# Changelog

All notable changes to the AP Mapping will be documented in this file.

## [1.1.0-alpha.2] - 2025-01-10

### Added
- **Automatic Audio Player Installation**: Installer now checks for and installs required audio players
  - Automatically installs `mpg123` for ElevenLabs (MP3 support)
  - Automatically installs `alsa-utils` for Piper (WAV support)
  - Prevents audio static issues from the start

### Fixed
- **Audio Static Issue**: Fixed static/noise when using ElevenLabs on Linux/WSL
  - Prioritized MP3-capable players (mpg123, ffplay) over aplay
  - Added MP3-to-WAV conversion fallback when only aplay is available
  - Reordered audio player detection for better compatibility

### Changed
- **Voice Variety**: Added multiple ElevenLabs voices with automatic fallback
  - Each persona has a unique voice assignment
  - Automatically falls back to George voice if others aren't available
  - Works with both free and paid ElevenLabs plans

## [1.1.0-alpha] - 2025-01-10

### Added
- **Modular TTS System**: Complete overhaul of the text-to-speech system
  - New TTS Manager (`tts-manager.sh`) as central hub for all TTS operations
  - Support for multiple TTS providers:
    - Piper (local, offline) - Original provider
    - ElevenLabs (cloud, premium quality)
    - System TTS (OS built-in)
    - Discord (webhook notifications)
    - None (silent mode)
  - Provider interface pattern for easy extensibility
  - Smart caching system for cloud providers
  - Cross-platform audio playback support

### Changed
- **Installer Improvements**:
  - Interactive TTS provider selection during installation
  - Yellow-colored prompts for better user experience
  - Fixed installer hanging issues with proper stderr redirection
  - Automatic configuration of selected TTS provider
  
- **Voice Scripts Refactoring**:
  - All voice scripts now use the TTS manager
  - Removed hard dependency on Piper
  - Graceful fallback when TTS is unavailable
  
- **Settings Enhancement**:
  - New TTS configuration structure in settings.json
  - Support for per-persona voice customization
  - Multiple API key storage methods for security

### Fixed
- Installer hanging at project configuration step
- Voice scripts failing when Piper not installed
- Command substitution capturing prompts instead of displaying them

### Security
- API keys can be stored in environment variables, obfuscated, or system keychains
- No hardcoded credentials in any configuration files

## [1.0.0] - 2025-01-09

### Added
- Initial release of AP Mapping
- Agent Persona orchestration system
- Specialized agent roles (Orchestrator, Developer, Architect, etc.)
- Project-agnostic methodology framework
- Interactive installer with template system
- Voice notification support with Piper TTS
- Session notes management (Obsidian MCP and Markdown)
- Claude Code integration with custom commands
- Python hooks for automation
- Update management system (`ap-manager.sh`)

### Features
- `/ap` command to launch AP Orchestrator
- `/handoff` and `/switch` for agent transitions
- `/wrap` for session management
- Project documentation structure
- Configurable environment settings
- Git-aware installation process