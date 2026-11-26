#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh" # Loads all defined colors

sketchybar --add item spacer.1 left \
	--set spacer.1 background.drawing=off \
	label.drawing=off \
	icon.drawing=off \
	width=10

for i in "${!SPACE_ICONS[@]}"; do
	sid=$((i + 1))
	sketchybar --add space space.$sid left \
		--set space.$sid associated_space=$sid \
		icon="$sid" \
		icon.font="$FONT:Regular:11.0" \
		icon.color="$SPACE_INACTIVE_COLOR" \
		icon.y_offset=4 \
		icon.padding_left=7 \
		icon.padding_right=7 \
		label.drawing=off \
		label.font="sketchybar-app-font:Regular:11.0" \
		label.color="$SPACE_INACTIVE_COLOR" \
		label.padding_left=0 \
		label.padding_right=7 \
		background.padding_left=2 \
		background.padding_right=2 \
		background.height=22 \
		background.corner_radius=6 \
		background.border_color="$SPACE_ACTIVE_COLOR" \
		background.border_width=0 \
		background.drawing=on \
		script="$PLUGIN_DIR/space.sh"
done

sketchybar --add item spacer.2 left \
	--set spacer.2 background.drawing=off \
	label.drawing=off \
	icon.drawing=off \
	width=5

sketchybar --add bracket spaces '/space.*/' \
	--set spaces background.border_width=0 \
	background.corner_radius=4 \
	background.color="$SPACE_BACKGROUND" \
	background.height=26 \
	background.drawing=on

sketchybar --add item separator left \
	--set separator icon.drawing=off label.drawing=off width=14 \
	associated_display=active

sketchybar --add item space_window_listener left \
	--set space_window_listener drawing=off updates=on script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_window_listener space_windows_change
