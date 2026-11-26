#!/usr/bin/env bash

source "${0%/*}/../variables.sh"

color=$SPACE_INACTIVE_COLOR
border=0
if [[ "$SELECTED" == true ]]; then
	color=$SPACE_ACTIVE_COLOR
	border=1
fi

sketchybar --set "$NAME" icon="$SID" icon.color="$color" label.color="$color" \
	background.border_width="$border" click_script="yabai -m space --focus $SID 2>/dev/null"
