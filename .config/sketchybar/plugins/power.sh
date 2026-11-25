#!/usr/bin/env bash

source "${0%/*}/../variables.sh"

if [[ "$SENDER" == mouse.clicked && "$BUTTON" == right ]]; then
	/usr/bin/osascript <<'APPLESCRIPT'
with timeout of 10 seconds
	tell application id "com.if.Amphetamine"
		if session is active then
			end session
		else
			start new session
		end if
	end tell
end timeout
APPLESCRIPT
fi

battery=$(/usr/bin/pmset -g batt)
percentage=$(printf '%s\n' "$battery" | /usr/bin/grep -Eo '[0-9]+%' | head -n 1)

# Amphetamine owns these assertions for both manual and triggered sessions.
if /usr/bin/pmset -g assertions | /usr/bin/grep -Eq '\(Amphetamine\): .* (PreventUserIdleSystemSleep|PreventSystemSleep) '; then
	sketchybar --set "$NAME" icon="" icon.width=29 icon.background.drawing=on \
		label="$percentage" label.color="$RED" background.border_color="$RED"
	exit
fi

case "${percentage%[%]}" in
	9[0-9]|100) icon="" ;;
	[6-8][0-9]) icon="" ;;
	[3-5][0-9]) icon="" ;;
	[1-2][0-9]) icon="" ;;
	*) icon="" ;;
esac

if [[ "$battery" == *"'AC Power'"* ]]; then
	icon=""
fi

sketchybar --set "$NAME" icon="$icon" icon.width=dynamic icon.background.drawing=off \
	label="$percentage" label.color="$CYAN" background.border_color="$CYAN"
