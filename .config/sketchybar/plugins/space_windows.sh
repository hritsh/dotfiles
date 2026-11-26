#!/usr/bin/env bash

source "${0%/*}/../variables.sh"
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# SketchyBar provides a Space index and window counts keyed by app name.
space=$(jq -er '.space | select(type == "number" and . == floor and . > 0)' <<< "$INFO") || exit 0
(( space <= ${#SPACE_ICONS[@]} )) || exit 0
apps=$(jq -er '.apps | keys[]' <<< "$INFO")

icons=""
while IFS= read -r app; do
	[[ -n "$app" ]] || continue
	icon=$("$PLUGIN_DIR/space_icon_map.sh" "$app")
	icons+="${icons:+ }$icon"
done <<< "$apps"

drawing=off
number_padding=7
if [[ -n "$icons" ]]; then
	drawing=on
	number_padding=3
fi
sketchybar --set "space.$space" label="$icons" label.drawing="$drawing" \
	icon.padding_right="$number_padding" --trigger spotify_resize
