#!/usr/bin/env bash

[[ "$SENDER" == front_app_switched ]] || exit 0

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
previous=$(sketchybar --query "$NAME" | jq -r '.label.value // ""')
sketchybar --set "$NAME" label="$INFO" --trigger spotify_resize

# Raycast hides and shows Beeper without closing its All Desktops window.
case "$previous:$INFO" in
	Beeper:*|"Beeper Desktop":*|*:Beeper|*:"Beeper Desktop")
		sketchybar --trigger space_windows_change
		;;
esac
