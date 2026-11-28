#!/usr/bin/env bash
# Render one half of the shared session pill: its half of the outline, a
# translucent fill for the time left in the session window, and the logo.
# Claude is the left half (fills from the left), Codex the right half (fills
# from the right), so the two meet in the middle like one pill.
# Usage: session_limits.sh <claude|codex> <fill 0-100> <0xffRRGGBB> <output.png> <width pt>

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
name=$1 fill=$2 ink="#${3#0xff}" output=$4 width=$5
case "$name" in
	claude) logo="${0%/*}/../icons/apps/claude.svg" ;;
	codex) logo="${0%/*}/../icons/apps/chatgpt.svg" ;;
	*) exit 1 ;;
esac
[[ -f "$logo" ]] || exit 1
mkdir -p "${output%/*}"
temporary=$(mktemp "${output%/*}/session-fill.XXXXXX") || exit 1

w=$((width * 2)) h=52 # 2x pixels
fw=$(((w - 4) * fill / 100))
if [[ "$name" == claude ]]; then
	outline="<rect x=\"2\" y=\"2\" width=\"$((w * 2))\" height=\"48\" rx=\"24\"/>"
	inside="<rect x=\"4\" y=\"4\" width=\"$((w * 2))\" height=\"44\" rx=\"22\"/>"
	fx=4 logo_x=18
else
	outline="<rect x=\"$((2 - w))\" y=\"2\" width=\"$((w * 2 - 4))\" height=\"48\" rx=\"24\"/>"
	inside="<rect x=\"$((-w))\" y=\"4\" width=\"$((w * 2 - 4))\" height=\"44\" rx=\"22\"/>"
	fx=$((w - 4 - fw)) logo_x=$((w - 42))
fi
logo_svg=$(sed "1s/<svg /<svg x=\"$logo_x\" y=\"14\" width=\"24\" height=\"24\" /" "$logo")

if rsvg-convert -o "$temporary" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h" color="$ink">
  <clipPath id="inside">$inside</clipPath>
  <rect x="$fx" y="4" width="$fw" height="44" fill="$ink" fill-opacity="0.22" clip-path="url(#inside)"/>
  <g fill="none" stroke="$ink" stroke-width="4">$outline</g>
  $logo_svg
</svg>
SVG
then
	mv -f "$temporary" "$output"
else
	rm -f "$temporary"
	exit 1
fi
