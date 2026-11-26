#!/usr/bin/env bash

source "${0%/*}/../variables.sh"
STATE="$HOME/.cache/sketchybar/spaces"
mkdir -p "$STATE"

# space_change runs this for every Space; only the two whose focus flipped need a redraw.
if [[ "$SENDER" == space_change && "$(cat "$STATE/$SID.sel" 2>/dev/null)" == "$SELECTED" ]]; then
	exit 0
fi
echo "$SELECTED" >"$STATE/$SID.sel"

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
