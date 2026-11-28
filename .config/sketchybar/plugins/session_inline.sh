#!/usr/bin/env bash
# One-line version of the popup bars for the extra display's bar:
# "5h ▬▬▬|▬ 24%   7d ▬▬▬▬|▬ 59%", ticks at even pace.
# Usage: session_inline.sh <output.png> <claude|codex> <0xffRRGGBB> <5h left> <5h pace|-> <7d left> <7d pace|->

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
output=$1 name=$2 ink="#${3#0xff}"
shift 3
case "$name" in
	claude) logo="${0%/*}/../icons/apps/claude.svg" ;;
	codex) logo="${0%/*}/../icons/apps/chatgpt.svg" ;;
	*) exit 1 ;;
esac
mkdir -p "${output%/*}"
temporary=$(mktemp "${output%/*}/session-inline.XXXXXX") || exit 1

H=44 bw=120 bh=8 by=18 seg=226 sep=28 # 2x pixels
font="font-family=\"'GohuFont 14 Nerd Font'\" font-size=\"28\""
svg=$(sed "s/currentColor/$ink/g; 1s/<svg /<svg x=\"0\" y=\"10\" width=\"24\" height=\"24\" /" "$logo")
x=40
for label in 5h 7d; do
	left=$1 pace=$2
	shift 2
	bx=$((x + 38))
	svg+="<text x=\"$x\" y=\"31\" $font fill=\"#c0caf5\">$label</text>"
	svg+="<rect x=\"$bx\" y=\"$by\" width=\"$bw\" height=\"$bh\" rx=\"4\" fill=\"#3b4261\"/>"
	svg+="<rect x=\"$bx\" y=\"$by\" width=\"$((bw * left / 100))\" height=\"$bh\" rx=\"4\" fill=\"$ink\"/>"
	if [[ "$pace" != - ]]; then
		svg+="<rect x=\"$((bx + bw * pace / 100 - 2))\" y=\"9\" width=\"4\" height=\"26\" rx=\"2\" fill=\"#c0caf5\"/>"
	fi
	svg+="<text x=\"$((bx + bw + 12))\" y=\"31\" $font fill=\"$ink\">$left%</text>"
	x=$((x + seg + sep))
done
W=$((40 + 2 * seg + sep + 6))
if rsvg-convert -o "$temporary" <<<"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$W\" height=\"$H\" viewBox=\"0 0 $W $H\">$svg</svg>"
then mv -f "$temporary" "$output"; else rm -f "$temporary"; exit 1; fi
