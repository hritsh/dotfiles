#!/bin/bash
# Build instant-focus and instant-follow against InstantSpaceSwitcher's C library (MIT).
set -e
dir="${0%/*}"
iss="$HOME/src/InstantSpaceSwitcher"
[[ -d "$iss" ]] || git clone -q --depth 1 https://github.com/jurplel/InstantSpaceSwitcher.git "$iss"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for c in ISS event_serialize; do clang -O2 -c "$iss/Sources/ISS/$c.c" -I "$iss/Sources/ISS/include" -o "$tmp/$c.o"; done
build() { # main.swift output
	mkdir -p "${2%/*}" "$tmp/$1"
	cp "$dir/$1" "$tmp/$1/main.swift" # top-level code must live in main.swift
	swiftc -O "$tmp/$1/main.swift" "$dir/spaces.swift" "$tmp"/*.o -import-objc-header "$iss/Sources/ISS/include/ISS.h" \
		-framework ApplicationServices -framework IOKit -o "$2"
}
build instant-focus.swift "$HOME/.cache/raycast/instant-focus"
# Fixed path: macOS ties the Accessibility grant to it.
build instant-follow.swift "$HOME/.local/bin/instant-follow"
