#!/bin/bash

if command -v xdotool &> /dev/null; then
    xdotool getactivewindow getwindowname
elif command -v wmctrl &> /dev/null; then
    wmctrl -l | grep ' -1 ' | sed 's/^[^ ]* *[^ ]* *[^ ]* *-1 //'
else
    echo "Error: xdotool or wmctrl is required" >&2
    exit 1
fi
