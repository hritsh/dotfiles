#!/bin/bash
# Shared runner for the Focus script commands: builds instant-focus if needed.
dir="$HOME/.config/raycast/instant-focus"
bin="$HOME/.cache/raycast/instant-focus"
if [[ ! -x "$bin" || "$dir/instant-focus.swift" -nt "$bin" ]]; then
	"$dir/build.sh" || exit 1
fi
exec "$bin" "$1"
