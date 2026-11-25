#!/usr/bin/env bash

COLOR="$SPOTIFY"
SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

sketchybar --add item spotify left \
	--add event spotify_change "$SPOTIFY_EVENT" \
	--add event spotify_resize \
	--set spotify \
	scroll_texts=on \
	icon= \
	icon.color="$COLOR" \
	icon.padding_left=6 \
	background.color="$BAR_COLOR" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.padding_right=3 \
	background.drawing=on \
	label.padding_right=5 \
	label.max_chars=42 \
	drawing=off \
	display=1 \
	updates=on \
	script="$PLUGIN_DIR/spotify.sh" \
	--subscribe spotify mouse.clicked spotify_change spotify_resize space_change display_change
