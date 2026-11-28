#!/bin/bash
# Build instant-focus against InstantSpaceSwitcher's C library (MIT).
set -e
dir="${0%/*}"
iss="$HOME/src/InstantSpaceSwitcher"
out="$HOME/.cache/raycast/instant-focus"
[[ -d "$iss" ]] || git clone -q --depth 1 https://github.com/jurplel/InstantSpaceSwitcher.git "$iss"
tmp=$(mktemp -d)
for c in ISS event_serialize; do clang -O2 -c "$iss/Sources/ISS/$c.c" -I "$iss/Sources/ISS/include" -o "$tmp/$c.o"; done
mkdir -p "${out%/*}"
swiftc -O "$dir/instant-focus.swift" "$tmp"/*.o -import-objc-header "$iss/Sources/ISS/include/ISS.h" \
	-framework ApplicationServices -framework IOKit -o "$out"
rm -rf "$tmp"
