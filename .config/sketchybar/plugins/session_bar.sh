#!/usr/bin/env bash
# Draw one popup row: label, a bar filled with what's left, a tick at even pace
# (where you'd be if usage were spread evenly over the window), the percentage
# left and when it resets.
# Usage: session_bar.sh <output.png> <label> <left %> <pace %|-> <reset text> <0xffRRGGBB>

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
output=$1 label=$2 left=$3 pace=$4 reset=$5 ink="#${6#0xff}"
mkdir -p "${output%/*}"
temporary=$(mktemp "${output%/*}/session-bar.XXXXXX") || exit 1

W=520 H=40 bx=84 bw=260 by=17 bh=8 # 2x pixels
fw=$((bw * left / 100))
font="font-family=\"'GohuFont 14 Nerd Font'\" font-size=\"26\""
tick=""
if [[ "$pace" != - ]]; then
	tx=$((bx + bw * pace / 100))
	tick="<rect x=\"$((tx - 2))\" y=\"8\" width=\"4\" height=\"26\" rx=\"2\" fill=\"#c0caf5\"/>"
fi
if rsvg-convert -o "$temporary" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H" viewBox="0 0 $W $H">
  <text x="0" y="29" $font fill="#565f89">$label</text>
  <rect x="$bx" y="$by" width="$bw" height="$bh" rx="4" fill="#3b4261"/>
  <rect x="$bx" y="$by" width="$fw" height="$bh" rx="4" fill="$ink"/>
  $tick
  <text x="$((bx + bw + 14))" y="29" $font fill="$ink">$left%</text>
  <text x="$W" y="29" $font fill="#565f89" text-anchor="end">$reset</text>
</svg>
SVG
then mv -f "$temporary" "$output"; else rm -f "$temporary"; exit 1; fi
