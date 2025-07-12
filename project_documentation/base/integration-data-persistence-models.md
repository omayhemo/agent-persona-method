# AP Mapping Integration Data Persistence Models

## Overview

This document defines the data persistence architecture for the AP Mapping integration system. The design prioritizes simplicity, reliability, and compatibility with the bash/Python ecosystem while avoiding external dependencies.

## Persistence Strategy

### Core Principles
1. **File-Based Storage**: Leverage filesystem for persistence (no database dependencies)
2. **Human-Readable Formats**: JSON and Markdown for transparency and debugging
3. **Atomic Operations**: Ensure data consistency through atomic file operations
4. **Version Control Friendly**: Changes trackable through git
5. **Performance Optimized**: Efficient indexing and caching strategies

## Data Models

### 1. Task Model

#### Schema Definition
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^TASK-[0-9]+-[0-9]+(-[0-9]+)?$"
    },
    "content": {
      "type": "string",
      "minLength": 1
    },
    "status": {
      "type": "string",
      "enum": ["pending", "in_progress", "completed", "blocked"]
    },
    "priority": {
      "type": "string",
      "enum": ["high", "medium", "low"]
    },
    "metadata": {
      "type": "object",
      "properties": {
        "created_at": {"type": "string", "format": "date-time"},
        "updated_at": {"type": "string", "format": "date-time"},
        "created_by": {"type": "string"},
        "story_id": {"type": "string"},
        "epic_id": {"type": "string"},
        "persona": {"type": "string"},
        "line_number": {"type": "integer"},
        "file_path": {"type": "string"}
      }
    },
    "relationships": {
      "type": "object",
      "properties": {
        "depends_on": {"type": "array", "items": {"type": "string"}},
        "blocks": {"type": "array", "items": {"type": "string"}},
        "related_to": {"type": "array", "items": {"type": "string"}}
      }
    }
  },
  "required": ["id", "content", "status", "priority", "metadata"]
}
```

#### Storage Structure
```
.ap-state/
├── tasks/
│   ├── active/
│   │   ├── TASK-001-001.json
│   │   └── TASK-001-002.json
│   ├── completed/
│   │   └── YYYY-MM/
│   │       └── TASK-001-003.json
│   └── index/
│       ├── by-status.json
│       ├── by-story.json
│       └── by-persona.json
```

#### Operations
```bash
# Create/Update Task
persist_task() {
    local task_json="$1"
    local task_id=$(echo "$task_json" | jq -r '.id')
    local status=$(echo "$task_json" | jq -r '.status')
    
    # Determine storage location
    local storage_path=$(get_task_storage_path "$task_id" "$status")
    
    # Atomic write with temp file
    local temp_file="${storage_path}.tmp"
    echo "$task_json" > "$temp_file"
    mv -f "$temp_file" "$storage_path"
    
    # Update indexes
    update_task_indexes "$task_id" "$task_json"
}

# Query Tasks
query_tasks() {
    local query_type="$1"  # by-status|by-story|by-persona
    local query_value="$2"
    
    local index_file=".ap-state/tasks/index/${query_type}.json"
    jq -r ".\"$query_value\"[]" "$index_file" 2>/dev/null
}
```

### 2. Integration Point Model

#### Schema Definition
```json
{
  "id": "IP-001",
  "type": "task_creation|data_flow|state_management|automation_hooks|validation_points|reporting",
  "source": {
    "type": "persona|task",
    "name": "string",
    "file": "string"
  },
  "target": {
    "type": "tool|persona|system",
    "name": "string"
  },
  "configuration": {
    "enabled": true,
    "priority": 1-100,
    "automation_level": "full|semi|manual",
    "triggers": ["array of trigger conditions"]
  },
  "metrics": {
    "executions": 0,
    "failures": 0,
    "avg_duration_ms": 0,
    "last_execution": "ISO-8601"
  }
}
```

#### Storage Structure
```
.ap-state/
├── integrations/
│   ├── active/
│   │   ├── IP-001.json
│   │   └── IP-002.json
│   ├── disabled/
│   │   └── IP-003.json
│   └── metrics/
│       └── YYYY-MM-DD.jsonl
```

### 3. State Management Model

#### Schema Definition
```json
{
  "entity_type": "story|epic|task|session",
  "entity_id": "string",
  "current_state": {
    "status": "string",
    "phase": "string",
    "assigned_to": "string",
    "progress_percentage": 0-100
  },
  "state_history": [
    {
      "timestamp": "ISO-8601",
      "from_state": "object",
      "to_state": "object",
      "changed_by": "string",
      "reason": "string"
    }
  ],
  "checkpoints": {
    "last_checkpoint": "ISO-8601",
    "checkpoint_data": "object"
  }
}
```

#### Storage Structure
```
.ap-state/
├── states/
│   ├── current/
│   │   ├── story/
│   │   │   └── STORY-001.json
│   │   └── task/
│   │       └── TASK-001-001.json
│   └── history/
│       └── YYYY-MM/
│           └── state-changes.jsonl
```

### 4. Workflow Execution Model

#### Schema Definition
```json
{
  "workflow_id": "uuid",
  "workflow_type": "string",
  "initiated_by": "persona|user|automation",
  "start_time": "ISO-8601",
  "end_time": "ISO-8601",
  "status": "running|completed|failed|cancelled",
  "steps": [
    {
      "step_id": "string",
      "step_type": "task|validation|handoff|automation",
      "status": "pending|running|completed|failed|skipped",
      "start_time": "ISO-8601",
      "end_time": "ISO-8601",
      "input": "object",
      "output": "object",
      "errors": ["array"]
    }
  ],
  "context": {
    "story_id": "string",
    "epic_id": "string",
    "persona": "string"
  }
}
```

### 5. Session Data Model

#### Schema Definition
```json
{
  "session_id": "uuid",
  "start_time": "ISO-8601",
  "end_time": "ISO-8601",
  "active_persona": "string",
  "session_context": {
    "working_directory": "string",
    "active_story": "string",
    "active_tasks": ["array"],
    "environment": "object"
  },
  "events": [
    {
      "timestamp": "ISO-8601",
      "event_type": "string",
      "event_data": "object"
    }
  ],
  "metrics": {
    "tasks_created": 0,
    "tasks_completed": 0,
    "validations_run": 0,
    "handoffs": 0
  }
}
```

## Indexing Strategy

### Primary Indexes
```bash
# Index structure for fast queries
.ap-state/
├── indexes/
│   ├── task-by-status.idx      # Status -> Task IDs
│   ├── task-by-story.idx       # Story ID -> Task IDs
│   ├── task-by-persona.idx     # Persona -> Task IDs
│   ├── task-by-priority.idx    # Priority -> Task IDs
│   └── integration-by-type.idx # Type -> Integration IDs
```

### Index Update Strategy
```bash
# Atomic index update
update_index() {
    local index_name="$1"
    local key="$2"
    local value="$3"
    local operation="$4"  # add|remove
    
    local index_file=".ap-state/indexes/${index_name}.idx"
    local temp_file="${index_file}.tmp"
    
    # Lock for concurrent access
    (
        flock -x 200
        
        # Read current index
        local index_data=$(<"$index_file")
        
        # Update index
        if [[ "$operation" == "add" ]]; then
            index_data=$(echo "$index_data" | jq ".\"$key\" += [\"$value\"] | .\"$key\" |= unique")
        else
            index_data=$(echo "$index_data" | jq ".\"$key\" -= [\"$value\"]")
        fi
        
        # Write atomically
        echo "$index_data" > "$temp_file"
        mv -f "$temp_file" "$index_file"
        
    ) 200>>"${index_file}.lock"
}
```

## Data Integrity

### Consistency Mechanisms

#### 1. Write-Ahead Logging
```bash
# Log changes before applying
write_ahead_log() {
    local operation="$1"
    local data="$2"
    local wal_file=".ap-state/wal/$(date +%Y%m%d).wal"
    
    echo "$(date -Iseconds)|$operation|$data" >> "$wal_file"
}
```

#### 2. Checkpointing
```bash
# Regular state checkpoints
create_checkpoint() {
    local checkpoint_dir=".ap-state/checkpoints/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$checkpoint_dir"
    
    # Copy current state
    cp -r .ap-state/tasks/active "$checkpoint_dir/"
    cp -r .ap-state/states/current "$checkpoint_dir/"
    cp -r .ap-state/indexes "$checkpoint_dir/"
    
    # Create manifest
    echo "{\"timestamp\":\"$(date -Iseconds)\",\"version\":\"1.0\"}" > "$checkpoint_dir/manifest.json"
}
```

#### 3. Recovery Procedures
```bash
# Recover from checkpoint
recover_from_checkpoint() {
    local checkpoint="$1"
    
    # Validate checkpoint
    validate_checkpoint "$checkpoint" || return 1
    
    # Backup current state
    mv .ap-state .ap-state.backup.$(date +%Y%m%d_%H%M%S)
    
    # Restore checkpoint
    cp -r "$checkpoint" .ap-state
    
    # Replay WAL since checkpoint
    replay_wal_from "$checkpoint/manifest.json"
}
```

## Performance Optimization

### Caching Strategy
```bash
# In-memory cache for frequent queries
declare -A TASK_CACHE
declare -A INDEX_CACHE

# Cache with TTL
cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-300}"  # 5 minutes default
    
    TASK_CACHE["$key"]="$value"
    TASK_CACHE["${key}_expires"]=$(($(date +%s) + ttl))
}

# Cache-aware query
cached_query() {
    local key="$1"
    
    # Check cache
    if [[ -n "${TASK_CACHE[$key]}" ]]; then
        local expires="${TASK_CACHE[${key}_expires]}"
        if [[ $(date +%s) -lt $expires ]]; then
            echo "${TASK_CACHE[$key]}"
            return 0
        fi
    fi
    
    # Cache miss - query and cache
    local result=$(query_tasks "$@")
    cache_set "$key" "$result"
    echo "$result"
}
```

### Batch Operations
```bash
# Batch task updates
batch_update_tasks() {
    local updates_file="$1"
    
    # Start transaction
    local transaction_id=$(uuidgen)
    write_ahead_log "BEGIN_TRANSACTION" "$transaction_id"
    
    # Process updates
    while IFS= read -r update; do
        persist_task "$update"
    done < "$updates_file"
    
    # Commit transaction
    write_ahead_log "COMMIT_TRANSACTION" "$transaction_id"
    
    # Rebuild indexes once
    rebuild_all_indexes
}
```

## Migration Strategy

### Schema Evolution
```bash
# Version migrations
migrate_schema() {
    local current_version=$(cat .ap-state/version)
    local target_version="$1"
    
    # Apply migrations sequentially
    for version in $(seq $((current_version + 1)) $target_version); do
        apply_migration "v${version}"
    done
    
    # Update version
    echo "$target_version" > .ap-state/version
}
```

### Backward Compatibility
- All changes additive (no field removal)
- Version field in all documents
- Automatic upgrade on read
- Export/import utilities for major changes

## Monitoring & Metrics

### Performance Metrics
```jsonl
{"timestamp":"2025-01-11T10:00:00Z","operation":"persist_task","duration_ms":12,"status":"success"}
{"timestamp":"2025-01-11T10:00:01Z","operation":"query_tasks","duration_ms":5,"status":"success","result_count":15}
{"timestamp":"2025-01-11T10:00:02Z","operation":"update_index","duration_ms":8,"status":"success"}
```

### Health Checks
```bash
# System health check
check_persistence_health() {
    local health_status="healthy"
    local issues=()
    
    # Check file permissions
    [[ -w ".ap-state" ]] || issues+=("State directory not writable")
    
    # Check disk space
    local free_space=$(df -P .ap-state | awk 'NR==2 {print $4}')
    [[ $free_space -gt 1048576 ]] || issues+=("Low disk space")
    
    # Check index integrity
    validate_all_indexes || issues+=("Index corruption detected")
    
    # Report status
    if [[ ${#issues[@]} -gt 0 ]]; then
        health_status="unhealthy"
    fi
    
    echo "{\"status\":\"$health_status\",\"issues\":$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)}"
}
```

---

*Architecture Document Version: 1.0*  
*Last Updated: 2025-01-11*  
*Status: Foundation for AC3 - Data Persistence Models*