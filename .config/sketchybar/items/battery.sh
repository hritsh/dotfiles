#!/usr/bin/env bash

COLOR="$CYAN"

sketchybar --add item battery right \
	--set battery \
	update_freq=3 \
	icon.color="$COLOR" \
	icon.padding_left=10 \
	icon.background.image="$ITEM_DIR/../icons/amphetamine-active.png" \
	icon.background.drawing=off \
	icon.background.image.scale=0.5 \
	icon.background.image.padding_left=9 \
	label.padding_right=10 \
	label.color="$COLOR" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.color="$BAR_COLOR" \
	background.drawing=on \
	script="$PLUGIN_DIR/power.sh" \
	--subscribe battery power_source_change mouse.clicked system_woke
