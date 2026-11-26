#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

sketchybar --add item spacer.1 left \
	--set spacer.1 background.drawing=off label.drawing=off icon.drawing=off width=4

for i in "${!SPACE_ICONS[@]}"; do
	sid=$((i + 1))
	sketchybar --add space space.$sid left \
		--set space.$sid associated_space=$sid \
		icon="$sid" \
		icon.font="$FONT:Regular:14.0" \
		icon.color="$SPACE_INACTIVE_COLOR" \
		icon.padding_left=8 \
		icon.padding_right=8 \
		label.drawing=off \
		label.padding_left=0 \
		label.padding_right=8 \
		label.background.drawing=on \
		label.background.image.scale=0.5 \
		label.background.image.drawing=on \
		background.color="$ACCENT_FILL" \
		background.corner_radius=5 \
		background.height=18 \
		background.drawing=off \
		padding_left=1 \
		padding_right=1 \
		script="$PLUGIN_DIR/space.sh"
done

sketchybar --add item spacer.2 left \
	--set spacer.2 background.drawing=off label.drawing=off icon.drawing=off width=4

# One accent outline around all of the spaces
sketchybar --add bracket spaces '/space\..*/' spacer.1 spacer.2 \
	--set spaces background.color="$SURFACE" \
	background.border_color="$ACCENT" \
	background.border_width=1 \
	background.corner_radius="$PILL_RADIUS" \
	background.height="$PILL_HEIGHT" \
	background.drawing=on

sketchybar --add item separator left \
	--set separator icon.drawing=off label.drawing=off width=6 \
	associated_display=active

sketchybar --add item space_window_listener left \
	--set space_window_listener drawing=off updates=on script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_window_listener space_windows_change
