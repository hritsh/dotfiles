#!/usr/bin/env bash
# Cache the provider logo and translucent fill together.

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
case "$1" in
	claude) logo=claude ;;
	codex) logo=chatgpt ;;
	*) exit 1 ;;
esac
fill=$2
ink="#${3#0xff}"
output=$4
cache=${output%/*}
mkdir -p "$cache"
temporary=$(mktemp "$cache/session-fill.XXXXXX") || exit 1
logo_svg=$(sed '1s/<svg /<svg x="12" y="13" width="26" height="26" /' "${0%/*}/../icons/apps/$logo.svg")
if rsvg-convert -o "$temporary" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="162" height="52" viewBox="0 0 162 52" color="$ink">
  <clipPath id="pill"><rect x="4" y="4" width="154" height="44" rx="22"/></clipPath>
  <rect x="4" y="4" width="$((154 * fill / 100))" height="44"
        fill="$ink" fill-opacity="0.23" clip-path="url(#pill)"/>
  $logo_svg
</svg>
SVG
then
	mv -f "$temporary" "$output"
else
	rm -f "$temporary"
	exit 1
fi
