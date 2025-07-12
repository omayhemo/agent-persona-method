#!/bin/bash

# AP Mapping Report Generator
# Generates comprehensive installation reports and summaries

# Source logging framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging-framework.sh"

# Report configuration
REPORT_DIR="${REPORT_DIR:-./reports}"
REPORT_FORMAT="${REPORT_FORMAT:-text}"  # text, json, html
REPORT_INCLUDE_LOGS="${REPORT_INCLUDE_LOGS:-true}"
REPORT_INCLUDE_ERRORS="${REPORT_INCLUDE_ERRORS:-true}"
REPORT_INCLUDE_PERFORMANCE="${REPORT_INCLUDE_PERFORMANCE:-true}"
REPORT_INCLUDE_SUMMARY="${REPORT_INCLUDE_SUMMARY:-true}"

# Report data collectors
declare -A INSTALLATION_STATS=()
declare -A ERROR_SUMMARY=()
declare -a INSTALLATION_STEPS=()
declare -a WARNINGS=()
declare -a ERRORS=()

# Initialize report generator
init_report_generator() {
    mkdir -p "$REPORT_DIR"
    
    # Initialize counters
    INSTALLATION_STATS["start_time"]=$(date +%s)
    INSTALLATION_STATS["steps_total"]=0
    INSTALLATION_STATS["steps_completed"]=0
    INSTALLATION_STATS["steps_failed"]=0
    INSTALLATION_STATS["warnings"]=0
    INSTALLATION_STATS["errors"]=0
    
    log_debug "Report generator initialized" "REPORT"
}

# Track installation step
track_step() {
    local step_name="$1"
    local status="$2"  # started, completed, failed
    local details="${3:-}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$status" in
        "started")
            INSTALLATION_STEPS+=("$timestamp|STARTED|$step_name|$details")
            ((INSTALLATION_STATS["steps_total"]++))
            ;;
        "completed")
            INSTALLATION_STEPS+=("$timestamp|COMPLETED|$step_name|$details")
            ((INSTALLATION_STATS["steps_completed"]++))
            ;;
        "failed")
            INSTALLATION_STEPS+=("$timestamp|FAILED|$step_name|$details")
            ((INSTALLATION_STATS["steps_failed"]++))
            ;;
    esac
    
    log_trace "Step tracked: $step_name - $status" "REPORT"
}

# Record warning
record_warning() {
    local warning_msg="$1"
    local context="${2:-}"
    
    WARNINGS+=("$(date '+%Y-%m-%d %H:%M:%S')|$context|$warning_msg")
    ((INSTALLATION_STATS["warnings"]++))
}

# Record error
record_error() {
    local error_msg="$1"
    local context="${2:-}"
    local error_code="${3:-1}"
    
    ERRORS+=("$(date '+%Y-%m-%d %H:%M:%S')|$context|$error_code|$error_msg")
    ((INSTALLATION_STATS["errors"]++))
    
    # Update error summary
    ERROR_SUMMARY["$context"]=$((${ERROR_SUMMARY["$context"]:-0} + 1))
}

# Generate text report
generate_text_report() {
    local report_file="$1"
    
    {
        echo "========================================"
        echo "AP Mapping Installation Report"
        echo "========================================"
        echo ""
        
        # Summary section
        if [[ "$REPORT_INCLUDE_SUMMARY" == "true" ]]; then
            generate_summary_section
        fi
        
        # Installation steps
        echo ""
        echo "Installation Steps"
        echo "------------------"
        for step in "${INSTALLATION_STEPS[@]}"; do
            IFS='|' read -r timestamp status name details <<< "$step"
            printf "%-20s %-10s %-30s %s\n" "$timestamp" "$status" "$name" "$details"
        done
        
        # Warnings section
        if [[ ${#WARNINGS[@]} -gt 0 ]] && [[ "$REPORT_INCLUDE_ERRORS" == "true" ]]; then
            echo ""
            echo "Warnings (${#WARNINGS[@]})"
            echo "---------"
            for warning in "${WARNINGS[@]}"; do
                IFS='|' read -r timestamp context msg <<< "$warning"
                echo "[$timestamp] $context: $msg"
            done
        fi
        
        # Errors section
        if [[ ${#ERRORS[@]} -gt 0 ]] && [[ "$REPORT_INCLUDE_ERRORS" == "true" ]]; then
            echo ""
            echo "Errors (${#ERRORS[@]})"
            echo "-------"
            for error in "${ERRORS[@]}"; do
                IFS='|' read -r timestamp context code msg <<< "$error"
                echo "[$timestamp] $context (Code: $code): $msg"
            done
            
            # Error summary
            echo ""
            echo "Error Summary by Component:"
            for component in "${!ERROR_SUMMARY[@]}"; do
                echo "  $component: ${ERROR_SUMMARY[$component]} errors"
            done
        fi
        
        # Performance section
        if [[ "$REPORT_INCLUDE_PERFORMANCE" == "true" ]] && [[ "$PERF_TRACKING" == "true" ]]; then
            echo ""
            echo "Performance Metrics"
            echo "-------------------"
            generate_performance_report
        fi
        
        # Recommendations
        echo ""
        echo "Recommendations"
        echo "---------------"
        generate_recommendations
        
        # Footer
        echo ""
        echo "========================================"
        echo "Report generated: $(date)"
        echo "========================================"
        
    } > "$report_file"
}

# Generate summary section
generate_summary_section() {
    local end_time=$(date +%s)
    local duration=$((end_time - INSTALLATION_STATS["start_time"]))
    local duration_min=$((duration / 60))
    local duration_sec=$((duration % 60))
    
    echo "Summary"
    echo "-------"
    echo "Installation Status: $(get_overall_status)"
    echo "Start Time: $(date -d @${INSTALLATION_STATS["start_time"]} '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r ${INSTALLATION_STATS["start_time"]} '+%Y-%m-%d %H:%M:%S')"
    echo "End Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Duration: ${duration_min}m ${duration_sec}s"
    echo ""
    echo "Steps Summary:"
    echo "  Total: ${INSTALLATION_STATS["steps_total"]}"
    echo "  Completed: ${INSTALLATION_STATS["steps_completed"]}"
    echo "  Failed: ${INSTALLATION_STATS["steps_failed"]}"
    echo ""
    echo "Issues Summary:"
    echo "  Warnings: ${INSTALLATION_STATS["warnings"]}"
    echo "  Errors: ${INSTALLATION_STATS["errors"]}"
}

# Get overall installation status
get_overall_status() {
    if [[ ${INSTALLATION_STATS["errors"]} -gt 0 ]] || [[ ${INSTALLATION_STATS["steps_failed"]} -gt 0 ]]; then
        echo "FAILED"
    elif [[ ${INSTALLATION_STATS["warnings"]} -gt 0 ]]; then
        echo "COMPLETED WITH WARNINGS"
    else
        echo "SUCCESS"
    fi
}

# Generate JSON report
generate_json_report() {
    local report_file="$1"
    
    {
        echo "{"
        echo "  \"report\": {"
        echo "    \"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "    \"version\": \"1.0\","
        echo "    \"status\": \"$(get_overall_status)\","
        
        # Summary
        echo "    \"summary\": {"
        echo "      \"duration_seconds\": $(($(date +%s) - INSTALLATION_STATS["start_time"])),"
        echo "      \"steps\": {"
        echo "        \"total\": ${INSTALLATION_STATS["steps_total"]},"
        echo "        \"completed\": ${INSTALLATION_STATS["steps_completed"]},"
        echo "        \"failed\": ${INSTALLATION_STATS["steps_failed"]}"
        echo "      },"
        echo "      \"issues\": {"
        echo "        \"warnings\": ${INSTALLATION_STATS["warnings"]},"
        echo "        \"errors\": ${INSTALLATION_STATS["errors"]}"
        echo "      }"
        echo "    },"
        
        # Steps
        echo "    \"steps\": ["
        local first=true
        for step in "${INSTALLATION_STEPS[@]}"; do
            IFS='|' read -r timestamp status name details <<< "$step"
            [[ $first == true ]] && first=false || echo ","
            echo -n "      {\"timestamp\": \"$timestamp\", \"status\": \"$status\", \"name\": \"$name\", \"details\": \"$details\"}"
        done
        echo ""
        echo "    ],"
        
        # Warnings
        echo "    \"warnings\": ["
        first=true
        for warning in "${WARNINGS[@]}"; do
            IFS='|' read -r timestamp context msg <<< "$warning"
            [[ $first == true ]] && first=false || echo ","
            echo -n "      {\"timestamp\": \"$timestamp\", \"context\": \"$context\", \"message\": \"$msg\"}"
        done
        echo ""
        echo "    ],"
        
        # Errors
        echo "    \"errors\": ["
        first=true
        for error in "${ERRORS[@]}"; do
            IFS='|' read -r timestamp context code msg <<< "$error"
            [[ $first == true ]] && first=false || echo ","
            echo -n "      {\"timestamp\": \"$timestamp\", \"context\": \"$context\", \"code\": $code, \"message\": \"$msg\"}"
        done
        echo ""
        echo "    ]"
        
        echo "  }"
        echo "}"
    } > "$report_file"
}

# Generate HTML report
generate_html_report() {
    local report_file="$1"
    
    {
        cat << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>AP Mapping Installation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success { color: #4CAF50; font-weight: bold; }
        .warning { color: #ff9800; font-weight: bold; }
        .error { color: #f44336; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #4CAF50; color: white; }
        tr:hover { background: #f5f5f5; }
        .step-completed { color: #4CAF50; }
        .step-failed { color: #f44336; }
        .metrics { display: flex; justify-content: space-around; margin: 20px 0; }
        .metric { text-align: center; padding: 20px; background: #f9f9f9; border-radius: 5px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #333; }
        .metric-label { color: #666; margin-top: 5px; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>AP Mapping Installation Report</h1>
EOF
        
        # Summary section
        local status=$(get_overall_status)
        local status_class="success"
        [[ "$status" == "FAILED" ]] && status_class="error"
        [[ "$status" == "COMPLETED WITH WARNINGS" ]] && status_class="warning"
        
        echo "        <div class='summary'>"
        echo "            <h2>Summary</h2>"
        echo "            <p>Status: <span class='$status_class'>$status</span></p>"
        echo "            <p>Generated: $(date)</p>"
        echo "        </div>"
        
        # Metrics
        echo "        <div class='metrics'>"
        echo "            <div class='metric'>"
        echo "                <div class='metric-value'>${INSTALLATION_STATS["steps_completed"]}</div>"
        echo "                <div class='metric-label'>Steps Completed</div>"
        echo "            </div>"
        echo "            <div class='metric'>"
        echo "                <div class='metric-value'>${INSTALLATION_STATS["warnings"]}</div>"
        echo "                <div class='metric-label'>Warnings</div>"
        echo "            </div>"
        echo "            <div class='metric'>"
        echo "                <div class='metric-value'>${INSTALLATION_STATS["errors"]}</div>"
        echo "                <div class='metric-label'>Errors</div>"
        echo "            </div>"
        echo "        </div>"
        
        # Installation steps
        echo "        <h2>Installation Steps</h2>"
        echo "        <table>"
        echo "            <tr><th>Timestamp</th><th>Status</th><th>Step</th><th>Details</th></tr>"
        
        for step in "${INSTALLATION_STEPS[@]}"; do
            IFS='|' read -r timestamp status name details <<< "$step"
            local step_class=""
            [[ "$status" == "COMPLETED" ]] && step_class="step-completed"
            [[ "$status" == "FAILED" ]] && step_class="step-failed"
            echo "            <tr><td>$timestamp</td><td class='$step_class'>$status</td><td>$name</td><td>$details</td></tr>"
        done
        
        echo "        </table>"
        
        # Errors and warnings
        if [[ ${#ERRORS[@]} -gt 0 ]]; then
            echo "        <h2>Errors</h2>"
            echo "        <ul>"
            for error in "${ERRORS[@]}"; do
                IFS='|' read -r timestamp context code msg <<< "$error"
                echo "            <li class='error'>[$timestamp] $context: $msg (Code: $code)</li>"
            done
            echo "        </ul>"
        fi
        
        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo "        <h2>Warnings</h2>"
            echo "        <ul>"
            for warning in "${WARNINGS[@]}"; do
                IFS='|' read -r timestamp context msg <<< "$warning"
                echo "            <li class='warning'>[$timestamp] $context: $msg</li>"
            done
            echo "        </ul>"
        fi
        
        # Recommendations
        echo "        <h2>Recommendations</h2>"
        echo "        <div style='background: #f9f9f9; padding: 15px; border-radius: 5px;'>"
        generate_recommendations | while IFS= read -r line; do
            echo "            <p>$line</p>"
        done
        echo "        </div>"
        
        echo "    </div>"
        echo "</body>"
        echo "</html>"
    } > "$report_file"
}

# Generate recommendations based on installation results
generate_recommendations() {
    local has_errors=$([[ ${INSTALLATION_STATS["errors"]} -gt 0 ]] && echo "true" || echo "false")
    local has_warnings=$([[ ${INSTALLATION_STATS["warnings"]} -gt 0 ]] && echo "true" || echo "false")
    
    if [[ "$has_errors" == "true" ]]; then
        echo "• Review error messages above and address the root causes"
        echo "• Check the debug logs for detailed error information"
        echo "• Ensure all prerequisites are met before retrying"
        
        # Specific error recommendations
        for error in "${ERRORS[@]}"; do
            IFS='|' read -r timestamp context code msg <<< "$error"
            case "$context" in
                "PERMISSIONS")
                    echo "• Run installer with appropriate permissions or as administrator"
                    ;;
                "DEPENDENCIES")
                    echo "• Install missing dependencies: check prerequisite documentation"
                    ;;
                "DISK_SPACE")
                    echo "• Free up disk space before retrying installation"
                    ;;
                "NETWORK")
                    echo "• Check network connectivity and proxy settings"
                    ;;
            esac
        done
    fi
    
    if [[ "$has_warnings" == "true" ]]; then
        echo "• Review warnings to ensure optimal configuration"
        echo "• Some features may not work as expected"
    fi
    
    if [[ "$has_errors" == "false" ]] && [[ "$has_warnings" == "false" ]]; then
        echo "• Installation completed successfully!"
        echo "• Review the installation summary for confirmation"
        echo "• Test the installation with the provided verification commands"
    fi
    
    # Always include
    echo "• Keep this report for future reference and troubleshooting"
    echo "• For support, include this report with your inquiry"
}

# Generate installation report
generate_report() {
    local report_name="${1:-installation-report}"
    local format="${2:-$REPORT_FORMAT}"
    
    INSTALLATION_STATS["end_time"]=$(date +%s)
    
    local report_file="$REPORT_DIR/${report_name}-$(date +%Y%m%d-%H%M%S).${format}"
    
    log_info "Generating $format report..." "REPORT"
    
    case "$format" in
        "json")
            generate_json_report "$report_file"
            ;;
        "html")
            generate_html_report "$report_file"
            ;;
        *)
            generate_text_report "$report_file"
            ;;
    esac
    
    # Include logs if requested
    if [[ "$REPORT_INCLUDE_LOGS" == "true" ]] && [[ -f "$LOG_FILE" ]]; then
        local log_copy="$REPORT_DIR/${report_name}-$(date +%Y%m%d-%H%M%S).log"
        cp "$LOG_FILE" "$log_copy"
        log_debug "Log file included: $log_copy" "REPORT"
    fi
    
    log_info "Report generated: $report_file" "REPORT"
    echo "$report_file"
}

# Generate quick summary (for console output)
generate_quick_summary() {
    local status=$(get_overall_status)
    local duration=$(($(date +%s) - INSTALLATION_STATS["start_time"]))
    
    echo ""
    echo "Installation Summary"
    echo "==================="
    echo "Status: $status"
    echo "Duration: $((duration / 60))m $((duration % 60))s"
    echo "Steps: ${INSTALLATION_STATS["steps_completed"]}/${INSTALLATION_STATS["steps_total"]} completed"
    
    if [[ ${INSTALLATION_STATS["errors"]} -gt 0 ]]; then
        echo "Errors: ${INSTALLATION_STATS["errors"]}"
    fi
    
    if [[ ${INSTALLATION_STATS["warnings"]} -gt 0 ]]; then
        echo "Warnings: ${INSTALLATION_STATS["warnings"]}"
    fi
    
    echo ""
}

# Cleanup old reports
cleanup_old_reports() {
    local days="${1:-30}"
    
    if [[ -d "$REPORT_DIR" ]]; then
        log_debug "Cleaning up reports older than $days days" "REPORT"
        find "$REPORT_DIR" -type f -mtime +$days -name "*.txt" -o -name "*.json" -o -name "*.html" -delete
    fi
}

# Export report functions
export -f init_report_generator track_step record_warning record_error
export -f generate_report generate_quick_summary cleanup_old_reports