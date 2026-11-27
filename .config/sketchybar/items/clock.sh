#!/usr/bin/env bash

sketchybar --add item clock right \
	--set clock update_freq=15 width=136 \
		icon.drawing=off \
		label.color="$MAGENTA" label.font="$FONT:Regular:12" label.width=136 label.align=center label.padding_left=0 label.padding_right=0 \
		background.height=26 background.corner_radius="$CORNER_RADIUS" \
		background.padding_right=2 background.border_width="$BORDER_WIDTH" \
		background.border_color="$MAGENTA" background.color="$BAR_COLOR" background.drawing=on \
		script="$PLUGIN_DIR/clock.sh" click_script="$PLUGIN_DIR/stopwatch.sh" \
	--subscribe clock system_woke
