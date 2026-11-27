#!/usr/bin/env bash

# The first item starts at the physical notch edge, mirroring Spotify.
sketchybar --add item session_limits.claude e \
	--add item session_limits.codex e
for provider in claude codex; do
	color="$CYAN"
	padding=0
	other=claude
	if [[ "$provider" == claude ]]; then
		color="$ORANGE"
		padding=-7
		other=codex
	fi
	sketchybar --set "session_limits.$provider" \
		width=81 icon="" icon.width=18 icon.padding_left=0 icon.padding_right=0 \
		label="—" label.font="$FONT:Regular:12" label.color="$color" \
		label.width=61 label.align=center label.padding_left=0 label.padding_right=0 \
		background.height=26 background.corner_radius="$CORNER_RADIUS" \
		background.color="$BAR_COLOR" background.border_width="$BORDER_WIDTH" \
		background.border_color="$color" background.drawing=on \
		background.padding_left="$padding" background.padding_right=2 \
		background.image.scale=0.5 \
		click_script="sketchybar --set session_limits.$other popup.drawing=off --set session_limits.$provider popup.drawing=toggle" \
		--add item "session_limits.$provider.weekly" "popup.session_limits.$provider" \
		--set "session_limits.$provider.weekly" icon="Weekly" icon.color="$color" \
			icon.padding_left=8 icon.padding_right=9 label="Unavailable" label.padding_right=8
done

# Watch T3's cache and only wake the countdown once a minute.
watcher="$HOME/.cache/sketchybar/session-limits-watcher"
mkdir -p "${watcher%/*}"
pkill -f "^$watcher " 2>/dev/null
if [[ ! -x "$watcher" || "$PLUGIN_DIR/session_limits.swift" -nt "$watcher" ]]; then
	swiftc -O "$PLUGIN_DIR/session_limits.swift" -o "$watcher" || return
fi
bar_pid=$PPID
if [[ -n "$bar_pid" ]]; then
	nohup "$watcher" "$PLUGIN_DIR" "$bar_pid" </dev/null >"${watcher}.log" 2>&1 &
	disown
fi
