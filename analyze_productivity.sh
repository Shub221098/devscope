#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="${SCRIPT_DIR}/system_data.json"
HISTORY_DIR="${SCRIPT_DIR}/.data_history"
ANALYSIS_FILE="${SCRIPT_DIR}/productivity_analysis.txt"

# Create history directory if it doesn't exist
mkdir -p "$HISTORY_DIR"

# Archive current data to history
archive_data() {
    if [ -f "$DATA_FILE" ]; then
        local timestamp=$(date +%s)
        cp "$DATA_FILE" "${HISTORY_DIR}/data_${timestamp}.json"
    fi
}

# Get last N entries from history
get_last_entries() {
    local count=${1:-60}
    local entries=$(ls -t "${HISTORY_DIR}"/data_*.json 2>/dev/null | head -n "$count")
    
    if [ -z "$entries" ]; then
        echo "Error: No data history found. Run collector daemon first." >&2
        return 1
    fi
    
    echo "{"
    echo "  \"analysis_timestamp\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
    echo "  \"entries_analyzed\": $(echo "$entries" | wc -l),"
    echo "  \"data_entries\": ["
    
    local first=1
    for file in $entries; do
        if [ $first -eq 0 ]; then
            echo ","
        fi
        first=0
        cat "$file"
    done
    
    echo "  ]"
    echo "}"
}

# Prepare analysis prompt
prepare_prompt() {
    local data=$1
    cat << 'EOF'
Analyze the following system activity data collected over time. The data includes:
- Active window titles
- Top CPU consuming processes
- Recently executed commands
- System memory, CPU load, and uptime metrics

Based on this data, provide:
1. Overall productivity assessment
2. Time spent on different activities
3. Resource usage patterns
4. Peak activity periods
5. Recommendations for productivity improvement

Keep the analysis concise and actionable.

Data to analyze:
EOF
    echo "$data"
}

# Get insights from GitHub Copilot CLI
get_copilot_analysis() {
    local data=$1
    
    # Check if gh copilot is available
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not installed" >&2
        return 1
    fi
    
    if ! gh copilot --version &> /dev/null; then
        echo "Error: GitHub Copilot CLI is not available" >&2
        return 1
    fi
    
    # Prepare the prompt
    local prompt=$(prepare_prompt "$data")
    
    # Use gh copilot suggest
    if echo "$prompt" | gh copilot suggest 2>/dev/null; then
        return 0
    else
        echo "Error: Failed to get Copilot analysis" >&2
        return 1
    fi
}

# Main analysis function
analyze_productivity() {
    local entries_count=${1:-60}
    
    echo "=== Productivity Analyzer ===" >&2
    echo "Collecting last $entries_count entries..." >&2
    
    # Archive current data
    archive_data
    
    # Get last entries
    local data
    if ! data=$(get_last_entries "$entries_count"); then
        echo "Error: Failed to retrieve data entries" >&2
        return 1
    fi
    
    echo "Getting Copilot analysis..." >&2
    
    # Get analysis from Copilot
    if ! analysis=$(get_copilot_analysis "$data"); then
        echo "Error: Failed to get Copilot analysis" >&2
        echo "" >&2
        echo "Raw data collected:" >&2
        echo "$data" >&2
        return 1
    fi
    
    # Save analysis
    {
        echo "Productivity Analysis Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Entries analyzed: $(echo "$data" | grep -o '"entries_analyzed"' | wc -l)"
        echo "============================================"
        echo ""
        echo "$analysis"
    } | tee "$ANALYSIS_FILE"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -n, --entries NUM   Number of entries to analyze (default: 60)
    -h, --help          Show this help message

Examples:
    $0                  # Analyze last 60 entries
    $0 -n 100          # Analyze last 100 entries
    $0 --entries 30    # Analyze last 30 entries
EOF
}

# Parse arguments
entries=60
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--entries)
            entries="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Run analysis
analyze_productivity "$entries"
