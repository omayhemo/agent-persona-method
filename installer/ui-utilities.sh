#!/bin/bash

# AP Mapping UI Utilities
# Interactive user interface components for enhanced user experience

# UI utilities version
UI_UTILITIES_VERSION="1.0.0"

# Terminal capabilities
TERM_COLS=$(tput cols 2>/dev/null || echo 80)
TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
HAS_COLOR=$(tput colors 2>/dev/null || echo 0)

# UI configuration
PROGRESS_BAR_WIDTH=$((TERM_COLS > 100 ? 50 : TERM_COLS / 2))
SPINNER_DELAY=0.1
MENU_WIDTH=$((TERM_COLS > 80 ? 60 : TERM_COLS - 20))

# Spinner characters
SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_SIMPLE=("-" "\\" "|" "/")

# Progress tracking
declare -gA PROGRESS_TASKS
declare -gA PROGRESS_CURRENT
declare -gA PROGRESS_TOTAL
PROGRESS_START_TIME=""

# Initialize UI utilities
init_ui_utilities() {
    # Check terminal capabilities
    if [ -t 1 ]; then
        INTERACTIVE_MODE=true
    else
        INTERACTIVE_MODE=false
        log_debug "Non-interactive mode detected" "UI"
    fi
    
    # Check for Unicode support
    if locale | grep -q "UTF-8"; then
        UNICODE_SUPPORT=true
    else
        UNICODE_SUPPORT=false
    fi
    
    # Select appropriate characters
    if [ "$UNICODE_SUPPORT" = true ]; then
        PROGRESS_FILL="█"
        PROGRESS_EMPTY="░"
        CHECK_MARK="✓"
        CROSS_MARK="✗"
        ARROW_RIGHT="→"
        BOX_CHARS=(╔ ═ ╗ ║ ╚ ╝ ├ ─ ┤)
    else
        PROGRESS_FILL="#"
        PROGRESS_EMPTY="-"
        CHECK_MARK="[OK]"
        CROSS_MARK="[FAIL]"
        ARROW_RIGHT="->"
        BOX_CHARS=(+ - + | + + + - +)
    fi
    
    # Set up signal handlers for cleanup
    trap '_ui_cleanup' EXIT
    trap '_ui_cleanup; exit 130' INT TERM
    
    log_debug "UI utilities initialized (v$UI_UTILITIES_VERSION)" "UI"
}

# Show progress bar
show_progress_bar() {
    local task_name="${1:-Processing}"
    local current="${2:-0}"
    local total="${3:-100}"
    local task_id="${4:-default}"
    
    # Don't show in non-interactive mode
    if [ "$INTERACTIVE_MODE" != true ]; then
        return
    fi
    
    # Store progress data
    PROGRESS_TASKS["$task_id"]="$task_name"
    PROGRESS_CURRENT["$task_id"]=$current
    PROGRESS_TOTAL["$task_id"]=$total
    
    # Calculate percentage
    local percentage=$((current * 100 / total))
    local filled=$((percentage * PROGRESS_BAR_WIDTH / 100))
    local empty=$((PROGRESS_BAR_WIDTH - filled))
    
    # Build progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="$PROGRESS_FILL"
    done
    for ((i=0; i<empty; i++)); do
        bar+="$PROGRESS_EMPTY"
    done
    
    # Calculate ETA if possible
    local eta_text=""
    if [ -n "$PROGRESS_START_TIME" ] && [ "$current" -gt 0 ]; then
        local elapsed=$(($(date +%s) - PROGRESS_START_TIME))
        local rate=$(bc -l <<< "scale=2; $current / $elapsed" 2>/dev/null || echo "0")
        if [ "$rate" != "0" ]; then
            local remaining=$(bc -l <<< "scale=0; ($total - $current) / $rate" 2>/dev/null || echo "0")
            if [ "$remaining" -gt 0 ]; then
                eta_text=" ETA: $(format_duration $remaining)"
            fi
        fi
    else
        PROGRESS_START_TIME=$(date +%s)
    fi
    
    # Clear line and display progress
    printf "\r\033[K"
    printf "%s: [%s] %3d%%%s" "$task_name" "$bar" "$percentage" "$eta_text"
    
    # Add newline if complete
    if [ "$current" -ge "$total" ]; then
        echo ""
        unset PROGRESS_TASKS["$task_id"]
        unset PROGRESS_CURRENT["$task_id"]
        unset PROGRESS_TOTAL["$task_id"]
    fi
}

# Show spinner
show_spinner() {
    local message="${1:-Loading}"
    local pid="${2:-}"
    
    # Don't show in non-interactive mode
    if [ "$INTERACTIVE_MODE" != true ]; then
        return
    fi
    
    # Select spinner characters
    local chars=("${SPINNER_SIMPLE[@]}")
    if [ "$UNICODE_SUPPORT" = true ]; then
        chars=("${SPINNER_CHARS[@]}")
    fi
    
    # Save cursor position
    tput sc 2>/dev/null || true
    
    # Show spinner
    local i=0
    while true; do
        printf "\r%s %s " "${chars[$i]}" "$message"
        
        # Check if process is still running
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            break
        fi
        
        sleep "$SPINNER_DELAY"
        i=$(((i + 1) % ${#chars[@]}))
        
        # Check for stop signal
        if [ -f "/tmp/spinner_stop_$$" ]; then
            rm -f "/tmp/spinner_stop_$$"
            break
        fi
    done
    
    # Clear spinner
    printf "\r\033[K"
    
    # Restore cursor position
    tput rc 2>/dev/null || true
}

# Stop spinner
stop_spinner() {
    touch "/tmp/spinner_stop_$$"
    sleep 0.2  # Give spinner time to stop
}

# Show menu
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local key=""
    
    # Don't show in non-interactive mode
    if [ "$INTERACTIVE_MODE" != true ]; then
        echo "1"  # Default to first option
        return
    fi
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
    while true; do
        # Clear screen for menu
        clear
        
        # Draw box around menu
        draw_box "$title" "${options[@]}"
        
        # Show options
        echo ""
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                print_color "$GREEN" "  $ARROW_RIGHT ${options[$i]}"
            else
                echo "    ${options[$i]}"
            fi
        done
        echo ""
        echo "Use arrow keys to navigate, Enter to select, 'q' to quit"
        
        # Read key
        read -rsn1 key
        
        case "$key" in
            A)  # Up arrow
                ((selected--))
                if [ "$selected" -lt 0 ]; then
                    selected=$((${#options[@]} - 1))
                fi
                ;;
            B)  # Down arrow
                ((selected++))
                if [ "$selected" -ge "${#options[@]}" ]; then
                    selected=0
                fi
                ;;
            "")  # Enter
                break
                ;;
            q|Q)  # Quit
                selected=-1
                break
                ;;
        esac
    done
    
    # Show cursor
    tput cnorm 2>/dev/null || true
    
    # Return selected index (1-based for compatibility)
    echo $((selected + 1))
}

# Prompt user
prompt_user() {
    local prompt="$1"
    local default="${2:-}"
    local options="${3:-}"  # e.g., "yes/no" or "1-5"
    
    # Build prompt string
    local prompt_str="$prompt"
    if [ -n "$default" ]; then
        prompt_str+=" [$default]"
    fi
    if [ -n "$options" ]; then
        prompt_str+=" ($options)"
    fi
    prompt_str+=": "
    
    # Read input
    local response
    if [ "$INTERACTIVE_MODE" = true ]; then
        read -rp "$prompt_str" response
    else
        # In non-interactive mode, use default
        response="$default"
        echo "$prompt_str$response" >&2
    fi
    
    # Use default if empty
    if [ -z "$response" ] && [ -n "$default" ]; then
        response="$default"
    fi
    
    # Validate yes/no responses
    if [[ "$options" =~ "yes/no" ]]; then
        case "${response,,}" in
            y|yes|true|1)
                echo "yes"
                return 0
                ;;
            n|no|false|0)
                echo "no"
                return 1
                ;;
            *)
                echo "$response"
                ;;
        esac
    else
        echo "$response"
    fi
}

# Confirm action
confirm_action() {
    local message="$1"
    local default="${2:-no}"
    
    if prompt_user "$message" "$default" "yes/no" | grep -q "yes"; then
        return 0
    else
        return 1
    fi
}

# Draw box
draw_box() {
    local title="$1"
    shift
    local content=("$@")
    
    # Calculate box dimensions
    local max_width=${#title}
    for line in "${content[@]}"; do
        local line_length=${#line}
        if [ "$line_length" -gt "$max_width" ]; then
            max_width=$line_length
        fi
    done
    
    # Add padding
    max_width=$((max_width + 4))
    if [ "$max_width" -gt "$MENU_WIDTH" ]; then
        max_width=$MENU_WIDTH
    fi
    
    # Draw top border
    echo -n "${BOX_CHARS[0]}"
    for ((i=0; i<max_width-2; i++)); do
        echo -n "${BOX_CHARS[1]}"
    done
    echo "${BOX_CHARS[2]}"
    
    # Draw title
    local title_padding=$(((max_width - ${#title} - 2) / 2))
    echo -n "${BOX_CHARS[3]}"
    for ((i=0; i<title_padding; i++)); do
        echo -n " "
    done
    print_color "$CYAN" "$title" "inline"
    for ((i=0; i<max_width-title_padding-${#title}-2; i++)); do
        echo -n " "
    done
    echo "${BOX_CHARS[3]}"
    
    # Draw separator
    echo -n "${BOX_CHARS[6]}"
    for ((i=0; i<max_width-2; i++)); do
        echo -n "${BOX_CHARS[7]}"
    done
    echo "${BOX_CHARS[8]}"
    
    # Draw bottom border
    echo -n "${BOX_CHARS[4]}"
    for ((i=0; i<max_width-2; i++)); do
        echo -n "${BOX_CHARS[1]}"
    done
    echo "${BOX_CHARS[5]}"
}

# Show status
show_status() {
    local status="$1"
    local message="$2"
    local details="${3:-}"
    
    case "$status" in
        success|ok|done)
            print_color "$GREEN" "$CHECK_MARK $message"
            ;;
        error|fail|failed)
            print_color "$RED" "$CROSS_MARK $message"
            ;;
        warning|warn)
            print_color "$YELLOW" "⚠️  $message"
            ;;
        info)
            print_color "$BLUE" "ℹ️  $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo "   $details"
    fi
}

# Multi-progress display
show_multi_progress() {
    local tasks=("$@")
    
    # Don't show in non-interactive mode
    if [ "$INTERACTIVE_MODE" != true ]; then
        return
    fi
    
    # Save cursor position
    tput sc 2>/dev/null || true
    
    # Display all progress bars
    for task_id in "${tasks[@]}"; do
        if [ -n "${PROGRESS_TASKS[$task_id]}" ]; then
            show_progress_bar \
                "${PROGRESS_TASKS[$task_id]}" \
                "${PROGRESS_CURRENT[$task_id]}" \
                "${PROGRESS_TOTAL[$task_id]}" \
                "$task_id"
            echo ""
        fi
    done
    
    # Restore cursor position
    tput rc 2>/dev/null || true
}

# Format duration
format_duration() {
    local seconds="$1"
    
    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    elif [ "$seconds" -lt 3600 ]; then
        local minutes=$((seconds / 60))
        local remaining=$((seconds % 60))
        echo "${minutes}m ${remaining}s"
    else
        local hours=$((seconds / 3600))
        local remaining=$((seconds % 3600))
        local minutes=$((remaining / 60))
        echo "${hours}h ${minutes}m"
    fi
}

# Show notification
show_notification() {
    local type="$1"
    local title="$2"
    local message="$3"
    
    # Terminal notification
    case "$type" in
        success)
            echo ""
            print_color "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_color "$GREEN" "✅ $title"
            print_color "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ;;
        error)
            echo ""
            print_color "$RED" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_color "$RED" "❌ $title"
            print_color "$RED" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ;;
        warning)
            echo ""
            print_color "$YELLOW" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_color "$YELLOW" "⚠️  $title"
            print_color "$YELLOW" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ;;
        info)
            echo ""
            print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_color "$BLUE" "ℹ️  $title"
            print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ;;
    esac
    
    echo ""
    echo "$message"
    echo ""
    
    # System notification if available
    if command -v notify-send >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        notify-send "$title" "$message" -i "dialog-$type" 2>/dev/null || true
    elif command -v osascript >/dev/null 2>&1; then
        # macOS notification
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    fi
}

# Input with validation
input_with_validation() {
    local prompt="$1"
    local validator="$2"  # Function name or regex
    local error_msg="${3:-Invalid input}"
    local default="${4:-}"
    
    while true; do
        local value
        value=$(prompt_user "$prompt" "$default")
        
        # Check if validator is a function
        if declare -f "$validator" >/dev/null 2>&1; then
            if $validator "$value"; then
                echo "$value"
                return 0
            else
                print_color "$RED" "$error_msg"
            fi
        else
            # Treat as regex
            if [[ "$value" =~ $validator ]]; then
                echo "$value"
                return 0
            else
                print_color "$RED" "$error_msg"
            fi
        fi
    done
}

# Path input with completion
input_path() {
    local prompt="$1"
    local default="${2:-}"
    local must_exist="${3:-false}"
    
    # Simple input in non-interactive mode
    if [ "$INTERACTIVE_MODE" != true ]; then
        echo "$default"
        return
    fi
    
    while true; do
        local path
        path=$(prompt_user "$prompt" "$default")
        
        # Expand path
        path="${path/#\~/$HOME}"
        path="$(realpath -m "$path" 2>/dev/null || echo "$path")"
        
        # Validate
        if [ "$must_exist" = true ] && [ ! -e "$path" ]; then
            print_color "$RED" "Path does not exist: $path"
            continue
        fi
        
        echo "$path"
        return 0
    done
}

# Show checklist
show_checklist() {
    local title="$1"
    shift
    local items=("$@")
    
    echo ""
    print_color "$CYAN" "$title"
    print_color "$CYAN" "$(printf '=%.0s' {1..${#title}})"
    echo ""
    
    for item in "${items[@]}"; do
        # Check if item starts with [x] or [ ]
        if [[ "$item" =~ ^\[x\] ]]; then
            print_color "$GREEN" "$CHECK_MARK ${item:4}"
        elif [[ "$item" =~ ^\[\ \] ]]; then
            echo "  ○ ${item:4}"
        else
            echo "  • $item"
        fi
    done
    echo ""
}

# Table display
show_table() {
    local -n headers=$1
    local -n rows=$2
    
    # Calculate column widths
    local -a widths
    for i in "${!headers[@]}"; do
        widths[$i]=${#headers[$i]}
    done
    
    for row in "${rows[@]}"; do
        IFS='|' read -ra cols <<< "$row"
        for i in "${!cols[@]}"; do
            local len=${#cols[$i]}
            if [ "$len" -gt "${widths[$i]}" ]; then
                widths[$i]=$len
            fi
        done
    done
    
    # Draw header
    echo -n "+"
    for width in "${widths[@]}"; do
        printf -- '-%.0s' $(seq 1 $((width + 2)))
        echo -n "+"
    done
    echo ""
    
    # Draw header content
    echo -n "|"
    for i in "${!headers[@]}"; do
        printf " %-${widths[$i]}s |" "${headers[$i]}"
    done
    echo ""
    
    # Draw separator
    echo -n "+"
    for width in "${widths[@]}"; do
        printf -- '=%.0s' $(seq 1 $((width + 2)))
        echo -n "+"
    done
    echo ""
    
    # Draw rows
    for row in "${rows[@]}"; do
        IFS='|' read -ra cols <<< "$row"
        echo -n "|"
        for i in "${!cols[@]}"; do
            printf " %-${widths[$i]}s |" "${cols[$i]}"
        done
        echo ""
    done
    
    # Draw footer
    echo -n "+"
    for width in "${widths[@]}"; do
        printf -- '-%.0s' $(seq 1 $((width + 2)))
        echo -n "+"
    done
    echo ""
}

# Pager for long output
show_pager() {
    local content="$1"
    local title="${2:-}"
    
    # Use less if available and interactive
    if [ "$INTERACTIVE_MODE" = true ] && command -v less >/dev/null 2>&1; then
        if [ -n "$title" ]; then
            echo -e "$title\n\n$content" | less -R
        else
            echo "$content" | less -R
        fi
    else
        # Just print
        if [ -n "$title" ]; then
            echo "$title"
            echo ""
        fi
        echo "$content"
    fi
}

# Cleanup function
_ui_cleanup() {
    # Show cursor
    tput cnorm 2>/dev/null || true
    
    # Clear any temporary files
    rm -f /tmp/spinner_stop_$$ 2>/dev/null || true
    
    # Reset terminal
    stty sane 2>/dev/null || true
}

# Export UI functions
export -f show_progress_bar
export -f show_spinner
export -f stop_spinner
export -f show_menu
export -f prompt_user
export -f confirm_action
export -f show_status
export -f show_notification
export -f show_checklist
export -f show_table

# Initialize if sourced directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "UI Utilities v$UI_UTILITIES_VERSION"
    echo "This script should be sourced, not executed directly"
    exit 1
fi