#!/bin/bash

set -o pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="${SCRIPT_DIR}/system_data.json"
LOG_FILE="${SCRIPT_DIR}/collector.log"
PID_FILE="${SCRIPT_DIR}/collector.pid"
MAX_DATA_SIZE=52428800  # 50MB in bytes
MAX_LOG_SIZE=10485760   # 10MB in bytes
INTERVAL=60             # Run every 60 seconds

# Collector scripts
COLLECTORS=(
    "get_active_window.sh"
    "top_cpu_processes.sh"
    "last_commands_with_timestamps.sh"
    "system_stats.sh"
)

# Logging function
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Cleanup old log files
cleanup_logs() {
    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "${LOG_FILE}.$(date +%s)"
        log_message "INFO" "Log file rotated"
    fi
}

# Cleanup old data files
cleanup_data() {
    if [ -f "$DATA_FILE" ] && [ $(stat -f%z "$DATA_FILE" 2>/dev/null || stat -c%s "$DATA_FILE" 2>/dev/null) -gt $MAX_DATA_SIZE ]; then
        mv "$DATA_FILE" "${DATA_FILE}.$(date +%s)"
        log_message "WARN" "Data file rotated (size exceeded)"
    fi
}

# Verify all collector scripts exist
verify_collectors() {
    local missing=0
    for script in "${COLLECTORS[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            log_message "ERROR" "Collector script not found: $script"
            missing=$((missing + 1))
        fi
    done
    return $missing
}

# Run all collectors
run_collectors() {
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local json_output="{"
    json_output="$json_output\n  \"timestamp\": \"$timestamp\","
    json_output="$json_output\n  \"data\": {"
    
    local first=1
    for script in "${COLLECTORS[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        
        if [ ! -x "$script_path" ]; then
            log_message "ERROR" "Collector script not executable: $script"
            continue
        fi
        
        if [ $first -eq 0 ]; then
            json_output="$json_output,"
        fi
        first=0
        
        local script_name="${script%.sh}"
        json_output="$json_output\n    \"$script_name\": "
        
        if output=$("$script_path" 2>&1); then
            json_output="$json_output$output"
            log_message "INFO" "Collector succeeded: $script"
        else
            log_message "ERROR" "Collector failed: $script - $output"
            json_output="$json_output{\"error\": \"failed to collect data\"}"
        fi
    done
    
    json_output="$json_output\n  }\n}"
    echo -e "$json_output" > "$DATA_FILE"
}

# Setup signal handlers
cleanup_on_exit() {
    log_message "INFO" "Shutting down collector daemon"
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup_on_exit SIGTERM SIGINT

# Main daemon loop
start_daemon() {
    if [ -f "$PID_FILE" ]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo "Error: Collector daemon already running (PID: $old_pid)" >&2
            exit 1
        fi
    fi
    
    echo $$ > "$PID_FILE"
    log_message "INFO" "Collector daemon started (PID: $$)"
    
    verify_collectors || {
        log_message "FATAL" "One or more collector scripts missing"
        exit 1
    }
    
    # Run immediately on start
    run_collectors
    cleanup_data
    cleanup_logs
    
    # Then run on interval
    while true; do
        sleep $INTERVAL
        run_collectors
        cleanup_data
        cleanup_logs
    done
}

# Stop daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill $pid
            log_message "INFO" "Collector daemon stopped"
        fi
    fi
}

# Show status
show_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Collector daemon is running (PID: $pid)"
            return 0
        fi
    fi
    echo "Collector daemon is not running"
    return 1
}

# Main
case "${1:-start}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
