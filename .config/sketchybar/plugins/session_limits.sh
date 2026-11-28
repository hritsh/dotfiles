#!/usr/bin/env bash
# Render one half of the shared session pill. Both edges are lit from the outer
# end: the top edge for the share of the session window that's left (the even
# pace), the bottom edge for the share of usage that's left. Claude is the left
# half, Codex the right.
# Usage: session_limits.sh <claude|codex> <time left 0-100> <usage left 0-100> <0xffRRGGBB> <output.png> <width pt>

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
name=$1 pace=$2 usage=$3 ink="#${4#0xff}" output=$5 width=$6
case "$name" in
	claude) logo="${0%/*}/../icons/apps/claude.svg" ;;
	codex) logo="${0%/*}/../icons/apps/chatgpt.svg" ;;
	*) exit 1 ;;
esac
mkdir -p "${output%/*}"
temporary=$(mktemp "${output%/*}/session-fill.XXXXXX") || exit 1

w=$((width * 2)) h=52 cap=26 # 2x pixels; cap = the rounded outer end
top=$((cap + (w - cap) * pace / 100))
bottom=$((cap + (w - cap) * usage / 100))
half=$((h / 2))
if [[ "$name" == claude ]]; then
	outline="<rect x=\"2\" y=\"2\" width=\"$((w * 2))\" height=\"48\" rx=\"24\"/>"
	lit_clip="<rect x=\"0\" y=\"0\" width=\"$top\" height=\"$half\"/><rect x=\"0\" y=\"$half\" width=\"$bottom\" height=\"$half\"/>"
	logo_x=18
else
	outline="<rect x=\"$((2 - w))\" y=\"2\" width=\"$((w * 2 - 4))\" height=\"48\" rx=\"24\"/>"
	lit_clip="<rect x=\"$((w - top))\" y=\"0\" width=\"$top\" height=\"$half\"/><rect x=\"$((w - bottom))\" y=\"$half\" width=\"$bottom\" height=\"$half\"/>"
	logo_x=$((w - 42))
fi
logo_svg=$(sed "1s/<svg /<svg x=\"$logo_x\" y=\"14\" width=\"24\" height=\"24\" /" "$logo")

if rsvg-convert -o "$temporary" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h" color="$ink">
  <clipPath id="lit">$lit_clip</clipPath>
  <g fill="none" stroke-width="4">
    <g stroke="$ink" stroke-opacity="0.28">$outline</g>
    <g stroke="$ink" clip-path="url(#lit)">$outline</g>
  </g>
  $logo_svg
</svg>
SVG
then
	mv -f "$temporary" "$output"
else
	rm -f "$temporary"
	exit 1
fi
