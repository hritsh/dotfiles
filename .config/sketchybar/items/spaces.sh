#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

# SketchyBar recreates its items on reload; old draw records no longer apply.
find "$HOME/.cache/sketchybar/spaces" -maxdepth 1 \
	\( -name '*.drawn' -o -name '*.sel' \) -delete 2>/dev/null

sketchybar --add item spacer.1 left \
	--set spacer.1 background.drawing=off label.drawing=off icon.drawing=off width=1

for i in "${!SPACE_ICONS[@]}"; do
	sid=$((i + 1))
	sketchybar --add space space.$sid left \
		--set space.$sid associated_space=$sid \
		icon="$sid" \
		icon.font="$FONT:Regular:14.0" \
		icon.color="$SPACE_INACTIVE_COLOR" \
		icon.padding_left=6 \
		icon.padding_right=6 \
		label.drawing=off \
		label.padding_left=0 \
		label.padding_right=6 \
		label.background.drawing=on \
		label.background.image.scale=0.5 \
		label.background.image.drawing=on \
		background.color="$ACCENT_FILL" \
		background.corner_radius=9 \
		background.height=18 \
		background.drawing=off \
		padding_left=1 \
		padding_right=1 \
		script="$PLUGIN_DIR/space.sh"
done

sketchybar --add item spacer.2 left \
	--set spacer.2 background.drawing=off label.drawing=off icon.drawing=off width=1

# One accent outline around all of the spaces
sketchybar --add bracket spaces '/space\..*/' spacer.1 spacer.2 \
	--set spaces background.color="$SURFACE" \
	background.border_color="$ACCENT" \
	background.border_width="$BORDER_WIDTH" \
	background.corner_radius="$CORNER_RADIUS" \
	background.height="$PILL_HEIGHT" \
	background.drawing=on

sketchybar --add item separator left \
	--set separator icon.drawing=off label.drawing=off width=13 \
	associated_display=active

sketchybar --add item space_window_listener left \
	--set space_window_listener drawing=off updates=on script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_window_listener space_windows_change
