#!/usr/bin/env bash

source "${0%/*}/../variables.sh"
STATE="$HOME/.cache/sketchybar/spaces"
mkdir -p "$STATE"

color=$SPACE_INACTIVE_COLOR
fill=off
if [[ "$SELECTED" == true ]]; then
	color=$SPACE_ACTIVE_COLOR
	fill=on
	echo "$SID" >"$STATE/active"
fi

sketchybar --set "$NAME" icon="$SID" icon.color="$color" background.drawing="$fill" \
	click_script="$PLUGIN_DIR/space_click.sh $SID"
"$PLUGIN_DIR/space_label.sh" "$SID" "${SELECTED:-false}"
