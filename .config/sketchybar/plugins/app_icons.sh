#!/usr/bin/env bash
# Render app icons as one tinted PNG strip for SketchyBar.
# Usage: app_icons.sh <hex color, e.g. #f7768e> <app name>...
# Prints "<png path> <width in points>". Apps with an SVG in icons/apps use it,
# everything else falls back to its sketchybar-app-font glyph.

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
DIR="${0%/*}/.."
CACHE="$HOME/.cache/sketchybar/icons"
mkdir -p "$CACHE"

color=$1
shift
(($#)) || exit 0

SIZE=32 # 16pt at 2x
GAP=10  # 5pt between icons

slug() {
	local s
	s=$(tr '[:upper:]' '[:lower:]' <<<"$1")
	s=${s% (beta)}
	tr -c 'a-z0-9\n' '-' <<<"$s"
}

render() { # app -> cached png
	local app=$1 name out svg glyph
	name=$(slug "$app")
	out="$CACHE/$name-${color#\#}.png"
	[[ -s "$out" ]] && { echo "$out"; return; }
	svg="$DIR/icons/apps/$name.svg"
	if [[ -f "$svg" ]]; then
		sed "s/currentColor/$color/g" "$svg" | rsvg-convert -w 26 -h 26 |
			magick - -background none -gravity center -extent ${SIZE}x${SIZE} "$out"
	else
		glyph=$("$DIR/plugins/space_icon_map.sh" "$app")
		printf '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="64"><text x="8" y="48" font-family="sketchybar-app-font" font-size="40" fill="%s">%s</text></svg>' \
			"$color" "$glyph" | rsvg-convert |
			magick - -trim +repage -resize 22x22 -background none -gravity center -extent ${SIZE}x${SIZE} "$out"
	fi
	echo "$out"
}

files=()
for app in "$@"; do files+=("$(render "$app")"); done

key=$(printf '%s\n' "$color" "$@" | md5 -q)
strip="$CACHE/strip-$key.png"
if [[ ! -s "$strip" ]]; then
	magick "${files[@]}" -background none -splice ${GAP}x0 +append -chop ${GAP}x0 +repage "$strip"
fi
n=$#
echo "$strip $(((n * SIZE + (n - 1) * GAP) / 2))"
