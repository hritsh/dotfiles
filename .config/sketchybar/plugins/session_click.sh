#!/usr/bin/env bash
# Left click opens the usage popup; right click flips the pill between percent
# left and time until reset (the watcher handles SIGUSR1).
if [[ "$BUTTON" == right ]]; then
	pkill -USR1 -f "^$HOME/.cache/sketchybar/session-limits-watcher "
else
	sketchybar --set session_limits.claude popup.drawing=toggle
fi
