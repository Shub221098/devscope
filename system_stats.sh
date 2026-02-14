#!/bin/bash

# Get memory usage
memory_info=$(free -b | grep Mem)
total_mem=$(echo $memory_info | awk '{print $2}')
used_mem=$(echo $memory_info | awk '{print $3}')
free_mem=$(echo $memory_info | awk '{print $4}')
mem_percent=$(awk "BEGIN {printf \"%.1f\", ($used_mem / $total_mem) * 100}")

# Get CPU load average
load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
load_1=$(echo $load_avg | awk '{print $1}')
load_5=$(echo $load_avg | awk '{print $2}')
load_15=$(echo $load_avg | awk '{print $3}')

# Get uptime
uptime_info=$(cat /proc/uptime)
uptime_seconds=$(echo $uptime_info | awk '{print int($1)}')
uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(((uptime_seconds % 86400) / 3600))
uptime_minutes=$(((uptime_seconds % 3600) / 60))

# Get timestamp
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Output JSON
echo "{"
echo "  \"timestamp\": \"$timestamp\","
echo "  \"memory\": {"
echo "    \"total_bytes\": $total_mem,"
echo "    \"used_bytes\": $used_mem,"
echo "    \"free_bytes\": $free_mem,"
echo "    \"usage_percent\": $mem_percent"
echo "  },"
echo "  \"cpu\": {"
echo "    \"load_average_1m\": $load_1,"
echo "    \"load_average_5m\": $load_5,"
echo "    \"load_average_15m\": $load_15"
echo "  },"
echo "  \"uptime\": {"
echo "    \"total_seconds\": $uptime_seconds,"
echo "    \"days\": $uptime_days,"
echo "    \"hours\": $uptime_hours,"
echo "    \"minutes\": $uptime_minutes"
echo "  }"
echo "}"
