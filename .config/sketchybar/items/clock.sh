#!/usr/bin/env bash

# One pill, one item per word so the gaps can be tighter than the font's full-width
# space: time and AM/PM in magenta, then the day and date in a dimmer magenta.
# Right-side items are added right to left.
DIM=0xaabb9af7
word=(icon.drawing=off label.font="$FONT:Regular:12" label.padding_left=0
	padding_left=0 padding_right=0 click_script="$PLUGIN_DIR/stopwatch.sh")

sketchybar --add item clock.date right \
	--set clock.date "${word[@]}" label.color="$DIM" label.padding_right=10 padding_right=2 \
	--add item clock.day right \
	--set clock.day "${word[@]}" label.color="$DIM" label.padding_right=3 \
	--add item clock.ampm right \
	--set clock.ampm "${word[@]}" label.color="$MAGENTA" label.padding_right=6 \
	--add item clock right \
	--set clock update_freq=15 \
		icon="󰥔" icon.color="$MAGENTA" icon.padding_left=10 icon.padding_right=3 \
		label.color="$MAGENTA" label.font="$FONT:Regular:12" label.padding_left=3 label.padding_right=3 \
		padding_left=0 padding_right=0 \
		script="$PLUGIN_DIR/clock.sh" click_script="$PLUGIN_DIR/stopwatch.sh" \
	--subscribe clock system_woke \
	--add bracket clock.pill clock clock.ampm clock.day clock.date \
	--set clock.pill background.height=26 background.corner_radius="$CORNER_RADIUS" \
		background.border_width="$BORDER_WIDTH" background.border_color="$MAGENTA" \
		background.color="$BAR_COLOR" background.drawing=on
