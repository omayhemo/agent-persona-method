# AP Method Project Structure

This document provides a comprehensive overview of the entire project structure including all files, directories, and hidden elements.

## Directory Tree

```
/mnt/c/code/agentic-persona/
├── .claude/                              # Claude Code configuration
│   ├── commands/                         # Custom slash commands
│   │   ├── ap.md                        # Launch AP Orchestrator command - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── buildit.md                   # Build command
│   │   ├── handoff.md                   # Agent handoff command - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── session-note-setup.md       # Session notes setup - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── switch.md                    # Compact and switch agent command - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   └── wrap.md                      # Wrap up session command - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   ├── hooks/                           # Claude Code hook scripts
│   │   ├── notification.py              # Notification handling - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── post_tool_use.py            # Post-tool execution hook - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── pre_tool_use.py             # Pre-tool execution hook - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   ├── stop.py                     # Session stop hook - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   │   └── subagent_stop.py            # Subagent stop hook - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   ├── settings.json                    # Project settings - this command should be apart of the installation - always check that the installation is up to date with the latest version
│   └── settings.local.json              # Local overrides
│
├── .git/                                # Git repository
│   ├── branches/
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks/                           # Git hooks
│   ├── info/
│   ├── logs/
│   ├── objects/                         # Git objects
│   ├── packed-refs
│   └── refs/
│
├── .piper/                              # Piper configuration
├── .gitignore                           # Git ignore file
│
├── agents/                              # AP Method core directory
│   ├── README.md                        # Agents documentation
│   ├── agentic-setup                    # Setup script (executable)
│   ├── ide-ap-orchestrator.cfg.md      # IDE orchestrator config
│   ├── ide-ap-orchestrator.md          # IDE orchestrator docs
│   │
│   ├── checklists/                      # Quality assurance checklists
│   │   ├── architect-checklist.md
│   │   ├── change-checklist.md
│   │   ├── frontend-architecture-checklist.md
│   │   ├── pm-checklist.md
│   │   ├── po-acceptance-criteria-checklist.md
│   │   ├── po-backlog-prioritization-checklist.md
│   │   ├── po-master-checklist.md
│   │   ├── po-requirements-definition-checklist.md
│   │   ├── po-user-story-checklist.md
│   │   ├── project-brief-template.md
│   │   ├── qa-automation-quality-checklist.md
│   │   ├── qa-deployment-readiness-checklist.md
│   │   ├── qa-requirements-validation-checklist.md
│   │   ├── qa-test-execution-readiness-checklist.md
│   │   ├── qa-test-strategy-checklist.md
│   │   ├── story-dod-checklist.md
│   │   └── story-draft-checklist.md
│   │
│   ├── data/                            # Knowledge base
│   │   ├── ap-kb.md                     # AP method knowledge base
│   │   └── technical-preferences.txt    # Technical preferences
│   │
│   ├── personas/                        # Agent persona definitions
│   │   ├── analyst.md                   # Business Analyst persona
│   │   ├── ap.md                        # AP Orchestrator persona
│   │   ├── architect.md                 # System Architect persona
│   │   ├── communication_standards.md   # Communication guidelines
│   │   ├── design-architect.md          # Design Architect persona
│   │   ├── dev.md                       # Developer persona
│   │   ├── pm.md                        # Product Manager persona
│   │   ├── po.md                        # Product Owner persona
│   │   ├── qa.md                        # QA Engineer persona
│   │   └── sm.md                        # Scrum Master persona
│   │
│   ├── scripts/                         # Utility scripts
│   │   ├── README.md                    # Scripts documentation
│   │   └── setup-piper-chat.sh          # Piper chat setup
│   │
│   ├── tasks/                           # Task definitions
│   │   ├── brainstorming.md
│   │   ├── checklist-mappings.yml
│   │   ├── checklist-run-task.md
│   │   ├── conduct-stakeholder-review-task.md
│   │   ├── core-dump.md
│   │   ├── correct-course.md
│   │   ├── create-ai-frontend-prompt.md
│   │   ├── create-architecture.md
│   │   ├── create-automation-plan.md
│   │   ├── create-deep-research-prompt.md
│   │   ├── create-epic-task.md
│   │   ├── create-frontend-architecture.md
│   │   ├── create-next-story-task.md
│   │   ├── create-prd.md
│   │   ├── create-project-brief.md
│   │   ├── create-requirements-task.md
│   │   ├── create-test-plan.md
│   │   ├── create-test-strategy.md
│   │   ├── create-user-stories-task.md
│   │   ├── create-uxui-spec.md
│   │   ├── deep-research-prompt-generation.md
│   │   ├── define-acceptance-criteria-task.md
│   │   ├── doc-sharding-task.md
│   │   ├── execute-quality-review.md
│   │   ├── library-indexing-task.md
│   │   ├── prioritize-backlog-task.md
│   │   ├── run-qa-checklist.md
│   │   └── validate-requirements.md
│   │
│   ├── templates/                       # Document templates
│   │   ├── architecture-tmpl.md
│   │   ├── automation-test-case-tmpl.md
│   │   ├── defect-report-tmpl.md
│   │   ├── doc-sharding-tmpl.md
│   │   ├── epic-tmpl.md
│   │   ├── feature-specification-template.md
│   │   ├── front-end-architecture-tmpl.md
│   │   ├── front-end-spec-tmpl.md
│   │   ├── prd-tmpl.md
│   │   ├── product-backlog-template.md
│   │   ├── project-brief-tmpl.md
│   │   ├── qa-checklist-tmpl.md
│   │   ├── qa_templates.md
│   │   ├── stakeholder-feedback-template.md
│   │   ├── story-template.md
│   │   ├── story-tmpl.md
│   │   ├── test-plan-tmpl.md
│   │   ├── test-report-tmpl.md
│   │   └── test-strategy-tmpl.md
│   │
│   └── voice/                           # Voice notification scripts
│       ├── speakAnalyst.sh
│       ├── speakArchitect.sh
│       ├── speakBase.sh
│       ├── speakDesignArchitect.sh
│       ├── speakDeveloper.sh
│       ├── speakOrchestrator.sh
│       ├── speakPM.sh
│       ├── speakPO.sh
│       ├── speakQA.sh
│       └── speakSM.sh
│
├── dist/                                # Distribution packages
│   └── ap-method-v1.0.0/               # Version 1.0.0 distribution
│       ├── LICENSE
│       ├── README.md
│       ├── VERSION
│       ├── agents/                      # Complete agents directory copy
│       └── installer/                   # Installation system
│           ├── README.md
│           ├── install.sh
│           └── templates/               # Installation templates
│
├── installer/                           # Installer system source
│   ├── README.md                       # Installer documentation
│   ├── install.sh                      # Main installation script
│   └── templates/                      # Template files
│       ├── CLAUDE.md.markdown.template
│       ├── CLAUDE.md.obsidian.template
│       ├── claude/
│       │   ├── commands/               # Command templates
│       │   └── settings.json.template
│       ├── gitignore.template
│       ├── hooks/                      # Hook templates
│       └── project_documentation/      # Project doc templates
│
├── logs/                               # Application logs
│   ├── exceptions.log
│   ├── obsidian-mcp-*.log             # Obsidian MCP logs
│   ├── obsidian-mcp-current.log       # Current log symlink
│   └── rejections.log
│
├── project_documentation/              # Project documentation
│   ├── README.md
│   ├── base/                          # Core project documents
│   ├── claude-code/                   # Claude Code documentation
│   │   ├── core/                      # Core features docs
│   │   ├── enterprise/                # Enterprise features
│   │   ├── reference/                 # Reference documentation
│   │   └── resources/                 # Additional resources
│   ├── elevenlabs-api/                # ElevenLabs API docs
│   │   ├── authentication/
│   │   ├── endpoints/
│   │   ├── introduction/
│   │   └── text-to-speech/
│   ├── epics/                         # Epic documentation
│   ├── qa/                            # QA documentation
│   ├── rules/                         # Project rules
│   ├── session_notes/                 # Session notes
│   │   ├── archive/                   # Archived sessions
│   │   └── session-*.md               # Individual session files
│   └── stories/                       # User stories
│
├── CLAUDE.md                          # Claude Code instructions
├── LICENSE                            # MIT License
├── README.md                          # Project README
├── build-distribution.sh              # Build distribution script
├── elevenlabs_native.sh               # ElevenLabs native script
├── elevenlabs_setup.md                # ElevenLabs setup guide
├── elevenlabs_simple.py               # Simple TTS Python script
├── elevenlabs_simple.sh               # Simple TTS shell script
├── elevenlabs_tts.py                  # Full TTS Python implementation
├── elevenlabs_tts.sh                  # Full TTS shell script
├── elevenlabs_wsl_setup.sh            # WSL setup for ElevenLabs
└── install_audio.sh                   # Audio installation script

## File Statistics

### Total Counts
- **Directories**: ~50
- **Files**: ~250+
- **Hidden Directories**: 3 (.claude, .git, .piper)
- **Executable Scripts**: ~100+

### Key File Types
- **Markdown Documentation** (.md): ~200 files
- **Shell Scripts** (.sh): ~20 files
- **Python Scripts** (.py): ~10 files
- **YAML Configuration** (.yml): ~2 files
- **JSON Configuration** (.json): ~5 files
- **Templates**: ~30 files

### File Permissions
- **Regular Files**: 644 (rw-r--r--)
- **Executable Scripts**: 755 (rwxr-xr-x)
- **Directories**: 755 (drwxr-xr-x)

## Notable Features

1. **Claude Code Integration**
   - Custom slash commands in `.claude/commands/`
   - Hook scripts for session management
   - Settings configuration with local overrides

2. **Agent Persona System**
   - 10 specialized agent personas
   - Comprehensive task library
   - Quality assurance checklists
   - Document templates

3. **Distribution System**
   - Self-contained installer
   - Template-based configuration
   - Version management

4. **Documentation Structure**
   - Hierarchical organization
   - Session note tracking
   - API documentation (ElevenLabs, Claude Code)
   - Project-specific documentation areas

5. **Voice Integration**
   - ElevenLabs TTS scripts
   - Agent-specific voice notifications
   - WSL audio support

## Environment
- **Platform**: Linux (WSL2)
- **OS**: Linux 6.6.87.1-microsoft-standard-WSL2
- **Git**: Repository initialized
- **Working Directory**: /mnt/c/code/agentic-persona
- **Primary Branch**: main