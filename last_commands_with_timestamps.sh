#!/bin/bash

if [ ! -f ~/.bash_history ]; then
    echo "Error: ~/.bash_history not found" >&2
    exit 1
fi

current_timestamp=$(date '+%Y-%m-%d %H:%M:%S')

echo "{"
echo "  \"timestamp\": \"$current_timestamp\","
echo "  \"commands\": ["

tail -n 10 ~/.bash_history | awk -v ts="$current_timestamp" '
BEGIN {
    count = 0
}
{
    if (count > 0) print ","
    gsub(/"/, "\\\"")
    printf "    {\n"
    printf "      \"command\": \"%s\",\n", $0
    printf "      \"retrieved_at\": \"%s\"\n", ts
    printf "    }"
    count++
}
END {
    print "\n  ]"
    print "}"
}'
