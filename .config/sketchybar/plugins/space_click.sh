#!/usr/bin/env bash
# Switch to a Space with macOS's own "Switch to Desktop N" shortcuts (no yabai).
# They're bound to ctrl+option+N (1-10) and ctrl+option+shift+N (11-16).

sid=$1
codes=(29 18 19 20 21 23 22 26 28 25) # key codes for 0-9
((sid >= 1 && sid <= 16)) || exit 0
mods="control down, option down"
digit=$((sid % 10))
if ((sid > 10)); then
	mods+=", shift down"
	digit=$((sid - 10))
fi
osascript -e "tell application \"System Events\" to key code ${codes[$digit]} using {$mods}"
