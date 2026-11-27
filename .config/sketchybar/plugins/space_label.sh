#!/usr/bin/env bash
# Draw a space's app icons, tinted for whether the space is focused.
# Usage: space_label.sh <space id> [true|false: focused, read from state if omitted]

source "${0%/*}/../variables.sh"
STATE="$HOME/.cache/sketchybar/spaces"
sid=$1
apps_file="$STATE/$sid.apps"
focused=$2
trailing_padding=3
style=compact-v2
[[ -n "$focused" ]] || { [[ "$(cat "$STATE/active" 2>/dev/null)" == "$sid" ]] && focused=true; }

color=$MUTED_HEX
[[ "$focused" == true ]] && color=$ACCENT_HEX

apps=()
if [[ -f "$apps_file" ]]; then
	while IFS= read -r app; do
		[[ -n "$app" ]] || continue
		# macOS reports the same All Desktops window on each Space.
		case "$app" in
			Beeper|"Beeper Desktop") [[ "$focused" == true ]] || continue ;;
		esac
		apps+=("$app")
	done <"$apps_file"
fi

# Skip the redraw when neither the apps nor the focus changed.
key="$style|$color|$trailing_padding|${apps[*]}"
[[ "$(cat "$STATE/$sid.drawn" 2>/dev/null)" == "$key" ]] && exit 0
if ((${#apps[@]} == 0)); then
	sketchybar --set "space.$sid" label.drawing=off icon.padding_right=6 --trigger spotify_resize &&
		printf '%s\n' "$key" >"$STATE/$sid.drawn"
	exit 0
fi

read -r img width < <("$PLUGIN_DIR/app_icons.sh" "$color" "${apps[@]}")
[[ -s "$img" && "$width" =~ ^[0-9]+$ ]] || exit 0
sketchybar --set "space.$sid" label="" label.width="$((width + trailing_padding))" \
	label.background.image="$img" label.drawing=on icon.padding_right=5 --trigger spotify_resize &&
	printf '%s\n' "$key" >"$STATE/$sid.drawn"
