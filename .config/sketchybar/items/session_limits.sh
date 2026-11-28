#!/usr/bin/env bash

# One pill right of the notch: Claude is the left half, Codex the right half.
# Each half draws its own coloured outline; the top and bottom edges are lit from
# the outer end for the time left in the session window.
sketchybar --add item session_limits.claude e \
	--add item session_limits.codex e

common=(
	icon=""
	label="—"
	label.font="$FONT:Regular:12"
	background.height=26
	background.color=0x00000000
	background.border_width=0
	background.drawing=on
	background.image.scale=0.5
	background.image.drawing=on
)

# Claude: logo on the left, percentage after it. padding_left=-7 puts the pill
# against the real notch (NOTCH_WIDTH 200 vs the physical 185); Codex needs the
# same -7 to butt up against Claude.
sketchybar --set session_limits.claude "${common[@]}" \
	icon.width=25 icon.padding_left=0 icon.padding_right=0 \
	label.color="$ORANGE" label.align=left label.padding_left=0 label.padding_right=5 \
	padding_left=-7 padding_right=0 \
	click_script="$PLUGIN_DIR/session_click.sh"

# Codex: mirror image, percentage then logo on the outer right.
sketchybar --set session_limits.codex "${common[@]}" \
	icon.drawing=off \
	label.color="$CYAN" label.align=left label.padding_left=5 label.padding_right=25 \
	padding_left=-7 padding_right=2 \
	click_script="$PLUGIN_DIR/session_click.sh"

# One popup for both, hung off the Claude half; either half toggles it.
popup=popup.session_limits.claude
sketchybar --set session_limits.claude popup.align=center popup.height=24 popup.background.color=0xff000000 \
	click_script="$PLUGIN_DIR/session_click.sh" \
	--set session_limits.codex click_script="$PLUGIN_DIR/session_click.sh"
for provider in claude codex; do
	color="$CYAN" title="Codex" logo=chatgpt
	[[ "$provider" == claude ]] && color="$ORANGE" title="Claude" logo=claude
	read -r logo_png _ < <("$PLUGIN_DIR/app_icons.sh" "#${color#0xff}" "$logo")
	# Header: logo, name, and what's running (filled in by the watcher).
	sketchybar --add item "session_limits.$provider.title" "$popup" \
		--set "session_limits.$provider.title" icon="" icon.width=16 icon.padding_left=16 icon.padding_right=8 \
			icon.background.drawing=on icon.background.image="$logo_png" icon.background.image.scale=0.4 padding_left=12 \
			label="$title" label.color="$color" label.padding_right=14
	# Bars, drawn as images by session_bar.sh.
	for kind in session weekly; do
		sketchybar --add item "session_limits.$provider.$kind" "$popup" \
			--set "session_limits.$provider.$kind" icon.drawing=off padding_left=12 padding_right=12 \
				label="" label.width=290 label.padding_left=16 label.padding_right=14 \
				label.background.drawing=on label.background.image.scale=0.5 label.background.image.drawing=on
	done
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
