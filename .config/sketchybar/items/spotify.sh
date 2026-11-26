#!/usr/bin/env bash

COLOR="$SPOTIFY"
# Spotify's notification is forwarded by a small helper instead of
# `--add event spotify_change <notification>`: SketchyBar stacks another observer
# for those on every --reload, so the script ran once per reload per track change.
pkill -f "$PLUGIN_DIR/spotify-listener" 2>/dev/null
if [[ ! -x "$PLUGIN_DIR/spotify-listener" ]]; then
	swiftc -O "$PLUGIN_DIR/spotify_listener.swift" -o "$PLUGIN_DIR/spotify-listener"
fi
nohup "$PLUGIN_DIR/spotify-listener" >/dev/null 2>&1 &
disown

sketchybar --add item spotify q \
	--add event spotify_change \
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
