#!/usr/bin/env bash

COLOR="$RED"

# Clean up any existing stopwatch state on bar restart
rm -f /tmp/sketchybar_stopwatch_state
rm -f /tmp/sketchybar_stopwatch_start
rm -f /tmp/sketchybar_stopwatch_elapsed
rm -f /tmp/sketchybar_stopwatch_color

# The stopwatch takes the combined clock’s slot while it is running.
sketchybar --add item stopwatch right \
	--set stopwatch \
	update_freq=1 \
	width=136 \
	icon="󱎫" \
	icon.color="$COLOR" \
	icon.padding_left=10 \
	label="00:00:00" \
	label.color="$COLOR" \
	label.padding_right=10 \
	background.color="$BAR_COLOR" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.padding_right=2 \
	background.drawing=on \
	drawing=off \
	script="$PLUGIN_DIR/stopwatch.sh" \
	click_script="$PLUGIN_DIR/stopwatch.sh"
