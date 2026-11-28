#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Maximize Below Bar
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🪟
# @raycast.packageName Window
# @raycast.description Maximise the focused window without covering SketchyBar

dir="${0%/*}"
bin="$HOME/.cache/raycast/maximize-below-bar"
if [[ ! -x "$bin" || "$dir/maximize-below-bar.swift" -nt "$bin" ]]; then
	mkdir -p "${bin%/*}"
	swiftc -O "$dir/maximize-below-bar.swift" -o "$bin" || exit 1
fi
exec "$bin"
