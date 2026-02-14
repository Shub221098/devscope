#!/bin/bash

ps aux --sort=-%cpu | head -6 | tail -n +2 | awk '
BEGIN {
    print "{"
    print "  \"processes\": ["
    count = 0
}
{
    if (count > 0) print ","
    printf "    {\n"
    printf "      \"name\": \"%s\",\n", $11
    printf "      \"cpu_percentage\": %.1f\n", $3
    printf "    }"
    count++
}
END {
    print "\n  ]"
    print "}"
}' | sed 's/\\/\\\\/g'
