#!/usr/bin/env bash

source "${0%/*}/../variables.sh"
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
STATE="$HOME/.cache/sketchybar/spaces"
mkdir -p "$STATE"

# SketchyBar provides a Space index and window counts keyed by app name.
space=$(jq -er '.space | select(type == "number" and . == floor and . > 0)' <<<"$INFO") || exit 0
((space <= ${#SPACE_ICONS[@]})) || exit 0
jq -r '.apps | keys[]' <<<"$INFO" >"$STATE/$space.apps"

"$PLUGIN_DIR/space_label.sh" "$space"
sketchybar --trigger spotify_resize
