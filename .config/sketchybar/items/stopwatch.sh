#!/usr/bin/env bash

COLOR="$RED"

# Clean up any existing stopwatch state on bar restart
rm -f /tmp/sketchybar_stopwatch_state
rm -f /tmp/sketchybar_stopwatch_start
rm -f /tmp/sketchybar_stopwatch_elapsed
rm -f /tmp/sketchybar_stopwatch_color

# Invisible trigger button - right of notch (position e)
sketchybar --add item stopwatch_trigger e \
	--set stopwatch_trigger \
	icon="" \
	icon.drawing=off \
	label.drawing=off \
	background.color=0x00000000 \
	background.height=36 \
	padding_left=0 \
	padding_right=0 \
	width=30 \
	click_script="$PLUGIN_DIR/stopwatch.sh"

# The actual stopwatch pill - starts hidden
sketchybar --add item stopwatch e \
	--set stopwatch \
	update_freq=1 \
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
	background.padding_left=-10 \
	background.drawing=on \
	drawing=off \
	script="$PLUGIN_DIR/stopwatch.sh" \
	click_script="$PLUGIN_DIR/stopwatch.sh"
