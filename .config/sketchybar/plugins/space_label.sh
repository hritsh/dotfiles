#!/usr/bin/env bash
# Draw a space's app icons, tinted for whether the space is focused.
# Usage: space_label.sh <space id> [true|false: focused, read from state if omitted]

source "${0%/*}/../variables.sh"
STATE="$HOME/.cache/sketchybar/spaces"
sid=$1
apps_file="$STATE/$sid.apps"
focused=$2
[[ -n "$focused" ]] || { [[ "$(cat "$STATE/active" 2>/dev/null)" == "$sid" ]] && focused=true; }

color=$MUTED_HEX
[[ "$focused" == true ]] && color=$ACCENT_HEX

apps=()
[[ -f "$apps_file" ]] && while IFS= read -r a; do [[ -n "$a" ]] && apps+=("$a"); done <"$apps_file"

if ((${#apps[@]} == 0)); then
	sketchybar --set "space.$sid" label.drawing=off icon.padding_right=6
	exit 0
fi

read -r img width < <("$PLUGIN_DIR/app_icons.sh" "$color" "${apps[@]}")
sketchybar --set "space.$sid" label="" label.width="$width" \
	label.background.image="$img" label.drawing=on icon.padding_right=5
