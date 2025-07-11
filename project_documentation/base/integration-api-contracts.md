# AP Method Integration API Contracts

## Overview

This document defines the API contracts for all integration points within the AP Method system. These contracts establish clear interfaces between components, ensuring reliable communication and data exchange.

## API Design Principles

1. **RESTful Patterns**: Even for bash scripts, follow REST-like conventions
2. **Versioning**: All APIs versioned for backward compatibility
3. **Idempotency**: Operations safe to retry
4. **Error Handling**: Consistent error formats and codes
5. **Documentation**: Self-documenting through clear naming and structure

## Core Integration APIs

### 1. Task Management API

#### Create Task
```bash
# Contract: task_create
# Input: JSON task object
# Output: Task ID or error
# Version: v1

api_task_create() {
    local task_json="$1"
    
    # Validate against schema
    validate_json "$task_json" "task.schema.json" || return 1
    
    # Process task
    local task_id=$(generate_task_id)
    local enriched_task=$(echo "$task_json" | jq ".id = \"$task_id\"")
    
    # Persist and return
    persist_task "$enriched_task" && echo "$task_id"
}

# Example usage:
# task_id=$(api_task_create '{"content":"Implement feature X","priority":"high","status":"pending"}')
```

#### Update Task Status
```bash
# Contract: task_update_status
# Input: Task ID, New Status
# Output: Success/Error
# Version: v1

api_task_update_status() {
    local task_id="$1"
    local new_status="$2"
    
    # Validate status
    [[ "$new_status" =~ ^(pending|in_progress|completed|blocked)$ ]] || {
        error_response "INVALID_STATUS" "Status must be one of: pending, in_progress, completed, blocked"
        return 1
    }
    
    # Update task
    update_task_field "$task_id" "status" "$new_status"
}
```

#### Query Tasks
```bash
# Contract: task_query
# Input: Query parameters (JSON)
# Output: Array of tasks
# Version: v1

api_task_query() {
    local query_params="$1"
    
    # Parse query parameters
    local status=$(echo "$query_params" | jq -r '.status // "all"')
    local persona=$(echo "$query_params" | jq -r '.persona // "all"')
    local limit=$(echo "$query_params" | jq -r '.limit // 100')
    
    # Execute query
    query_tasks_with_filters "$status" "$persona" "$limit"
}

# Example:
# tasks=$(api_task_query '{"status":"in_progress","persona":"developer","limit":10}')
```

### 2. Integration Point API

#### Enable Integration
```bash
# Contract: integration_enable
# Input: Integration Point ID
# Output: Success/Error
# Version: v1

api_integration_enable() {
    local ip_id="$1"
    
    # Validate integration exists
    integration_exists "$ip_id" || {
        error_response "NOT_FOUND" "Integration point $ip_id not found"
        return 1
    }
    
    # Enable integration
    update_integration_config "$ip_id" "enabled" "true"
    
    # Start monitoring
    start_integration_monitoring "$ip_id"
    
    success_response "Integration $ip_id enabled"
}
```

#### Configure Integration
```bash
# Contract: integration_configure
# Input: Integration ID, Configuration JSON
# Output: Success/Error
# Version: v1

api_integration_configure() {
    local ip_id="$1"
    local config_json="$2"
    
    # Validate configuration
    validate_integration_config "$ip_id" "$config_json" || return 1
    
    # Apply configuration
    apply_integration_config "$ip_id" "$config_json"
    
    # Reload if active
    reload_integration "$ip_id"
}
```

### 3. Workflow API

#### Start Workflow
```bash
# Contract: workflow_start
# Input: Workflow type, Context JSON
# Output: Workflow ID
# Version: v1

api_workflow_start() {
    local workflow_type="$1"
    local context_json="$2"
    
    # Create workflow instance
    local workflow_id=$(uuidgen)
    local workflow_data=$(cat <<EOF
{
    "workflow_id": "$workflow_id",
    "workflow_type": "$workflow_type",
    "status": "running",
    "start_time": "$(date -Iseconds)",
    "context": $context_json
}
EOF
)
    
    # Initialize workflow
    initialize_workflow "$workflow_data"
    
    # Start execution
    execute_workflow_async "$workflow_id" &
    
    echo "$workflow_id"
}
```

#### Query Workflow Status
```bash
# Contract: workflow_status
# Input: Workflow ID
# Output: Workflow status object
# Version: v1

api_workflow_status() {
    local workflow_id="$1"
    
    # Retrieve workflow data
    get_workflow_data "$workflow_id" || {
        error_response "NOT_FOUND" "Workflow $workflow_id not found"
        return 1
    }
}
```

### 4. Validation API

#### Validate Document
```bash
# Contract: validate_document
# Input: Document path, Validation type
# Output: Validation result
# Version: v1

api_validate_document() {
    local document_path="$1"
    local validation_type="$2"
    
    # Select validator
    local validator=$(get_validator_for_type "$validation_type")
    
    # Execute validation
    local result=$($validator "$document_path")
    local exit_code=$?
    
    # Format response
    cat <<EOF
{
    "document": "$document_path",
    "validation_type": "$validation_type",
    "valid": $([ $exit_code -eq 0 ] && echo "true" || echo "false"),
    "results": $result
}
EOF
}
```

### 5. Data Transfer API

#### Transfer Data Between Personas
```bash
# Contract: data_transfer
# Input: Transfer request JSON
# Output: Transfer ID
# Version: v1

api_data_transfer() {
    local transfer_request="$1"
    
    # Parse request
    local source=$(echo "$transfer_request" | jq -r '.source')
    local target=$(echo "$transfer_request" | jq -r '.target')
    local data=$(echo "$transfer_request" | jq -r '.data')
    
    # Validate transfer
    validate_transfer_permission "$source" "$target" || {
        error_response "FORBIDDEN" "Transfer not allowed from $source to $target"
        return 1
    }
    
    # Execute transfer
    local transfer_id=$(uuidgen)
    execute_data_transfer "$transfer_id" "$source" "$target" "$data"
    
    echo "$transfer_id"
}
```

## Event-Driven Contracts

### Event Publication
```bash
# Contract: publish_event
# Input: Event type, Event data
# Output: Event ID
# Version: v1

api_publish_event() {
    local event_type="$1"
    local event_data="$2"
    
    local event=$(cat <<EOF
{
    "event_id": "$(uuidgen)",
    "event_type": "$event_type",
    "timestamp": "$(date -Iseconds)",
    "data": $event_data
}
EOF
)
    
    # Publish to event bus
    publish_to_event_bus "$event"
}
```

### Event Subscription
```bash
# Contract: subscribe_event
# Input: Event pattern, Handler function
# Output: Subscription ID
# Version: v1

api_subscribe_event() {
    local event_pattern="$1"
    local handler_function="$2"
    
    # Register subscription
    local subscription_id=$(uuidgen)
    register_event_subscription "$subscription_id" "$event_pattern" "$handler_function"
    
    echo "$subscription_id"
}
```

## Error Handling Contracts

### Standard Error Response
```json
{
    "error": {
        "code": "ERROR_CODE",
        "message": "Human-readable error message",
        "details": {
            "field": "Additional context"
        },
        "timestamp": "ISO-8601"
    }
}
```

### Error Codes
```bash
# Standard error codes
declare -A ERROR_CODES=(
    ["INVALID_INPUT"]="400"
    ["UNAUTHORIZED"]="401"
    ["FORBIDDEN"]="403"
    ["NOT_FOUND"]="404"
    ["CONFLICT"]="409"
    ["INTERNAL_ERROR"]="500"
    ["NOT_IMPLEMENTED"]="501"
)

# Error response helper
error_response() {
    local code="$1"
    local message="$2"
    local details="${3:-{}}"
    
    cat <<EOF
{
    "error": {
        "code": "$code",
        "message": "$message",
        "details": $details,
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
}
```

## Batch Operation Contracts

### Batch Task Operations
```bash
# Contract: task_batch_update
# Input: Array of task updates
# Output: Batch result
# Version: v1

api_task_batch_update() {
    local updates_json="$1"
    
    local results=()
    local success_count=0
    local error_count=0
    
    # Process each update
    echo "$updates_json" | jq -c '.[]' | while read -r update; do
        local task_id=$(echo "$update" | jq -r '.task_id')
        local result=$(api_task_update "$update")
        local status=$?
        
        if [[ $status -eq 0 ]]; then
            ((success_count++))
        else
            ((error_count++))
        fi
        
        results+=("{\"task_id\":\"$task_id\",\"status\":$status,\"result\":$result}")
    done
    
    # Return batch result
    cat <<EOF
{
    "total": $(echo "$updates_json" | jq '. | length'),
    "success": $success_count,
    "errors": $error_count,
    "results": [$(IFS=,; echo "${results[*]}")]
}
EOF
}
```

## Pagination Contracts

### Paginated Response Format
```json
{
    "data": [],
    "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 100,
        "total_pages": 5
    },
    "links": {
        "first": "?page=1",
        "last": "?page=5",
        "next": "?page=2",
        "prev": null
    }
}
```

### Pagination Implementation
```bash
# Contract: paginate_results
# Input: Full result set, Page number, Items per page
# Output: Paginated response
# Version: v1

api_paginate_results() {
    local results="$1"
    local page="${2:-1}"
    local per_page="${3:-20}"
    
    local total=$(echo "$results" | jq '. | length')
    local total_pages=$(( (total + per_page - 1) / per_page ))
    local offset=$(( (page - 1) * per_page ))
    
    # Extract page of results
    local page_data=$(echo "$results" | jq ".[$offset:$offset + $per_page]")
    
    # Build response
    cat <<EOF
{
    "data": $page_data,
    "pagination": {
        "page": $page,
        "per_page": $per_page,
        "total": $total,
        "total_pages": $total_pages
    },
    "links": $(build_pagination_links $page $total_pages)
}
EOF
}
```

## Async Operation Contracts

### Async Job Submission
```bash
# Contract: job_submit
# Input: Job specification
# Output: Job ID
# Version: v1

api_job_submit() {
    local job_spec="$1"
    
    # Create job
    local job_id=$(uuidgen)
    local job_data=$(cat <<EOF
{
    "job_id": "$job_id",
    "status": "queued",
    "submitted_at": "$(date -Iseconds)",
    "spec": $job_spec
}
EOF
)
    
    # Queue job
    queue_job "$job_data"
    
    # Return job ID for polling
    echo "$job_id"
}
```

### Job Status Polling
```bash
# Contract: job_status
# Input: Job ID
# Output: Job status
# Version: v1

api_job_status() {
    local job_id="$1"
    
    get_job_status "$job_id" || {
        error_response "NOT_FOUND" "Job $job_id not found"
        return 1
    }
}
```

## Rate Limiting Contracts

### Rate Limit Headers
```bash
# Contract: rate_limit_check
# Input: Client ID, Operation
# Output: Allowed/Denied with headers
# Version: v1

api_rate_limit_check() {
    local client_id="$1"
    local operation="$2"
    
    local limit_info=$(check_rate_limit "$client_id" "$operation")
    local allowed=$(echo "$limit_info" | jq -r '.allowed')
    
    # Set rate limit headers
    cat <<EOF
{
    "allowed": $allowed,
    "headers": {
        "X-RateLimit-Limit": $(echo "$limit_info" | jq -r '.limit'),
        "X-RateLimit-Remaining": $(echo "$limit_info" | jq -r '.remaining'),
        "X-RateLimit-Reset": $(echo "$limit_info" | jq -r '.reset')
    }
}
EOF
}
```

## Contract Testing

### Contract Test Framework
```bash
# Test contract compliance
test_api_contract() {
    local api_function="$1"
    local test_cases="$2"
    
    local passed=0
    local failed=0
    
    # Run each test case
    echo "$test_cases" | jq -c '.[]' | while read -r test_case; do
        local input=$(echo "$test_case" | jq -r '.input')
        local expected=$(echo "$test_case" | jq -r '.expected')
        
        local actual=$($api_function "$input")
        
        if validate_response "$actual" "$expected"; then
            ((passed++))
        else
            ((failed++))
            echo "FAILED: $api_function with input $input"
        fi
    done
    
    echo "Contract tests: $passed passed, $failed failed"
}
```

## Version Migration

### API Version Management
```bash
# Support multiple API versions
api_router() {
    local version="${1:-v1}"
    local operation="$2"
    shift 2
    
    case "$version" in
        v1)
            "api_${operation}_v1" "$@"
            ;;
        v2)
            "api_${operation}_v2" "$@"
            ;;
        *)
            error_response "INVALID_VERSION" "API version $version not supported"
            return 1
            ;;
    esac
}
```

---

*Architecture Document Version: 1.0*  
*Last Updated: 2025-01-11*  
*Status: Foundation for AC3 - API Contracts*