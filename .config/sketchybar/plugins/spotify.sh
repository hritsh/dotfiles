#!/usr/bin/env bash

source "${0%/*}/../variables.sh"

# The plugin runs from SketchyBar, which may have a minimal PATH.
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# SketchyBar can emit unescaped quotes in item text. Read text and geometry
# separately so a song title cannot invalidate the layout measurement.
item_value() {
	sketchybar --query "$1" | sed -nE '/^[[:space:]]*"'"$2"'": \{/ {
		n
		s/^[[:space:]]*"value": "(.*)",$/\1/p
	}'
}

rect() { # item -> "left right"
	{ printf '{\n'; sketchybar --query "$1" | sed -n '/^[[:space:]]*"bounding_rects": {/,$p'; } |
		jq -r '.bounding_rects["display-1"] | select(.origin[0] >= 0) |
			"\(.origin[0] | floor) \(.origin[0] + .size[0] | floor)"'
}

# Spotify sits flush against the notch and grows left. Size it to the exact pixel
# so the gap to the window title matches the gap between the spaces and the title.
resize() {
	local text spaces_end title_start title_end gap left right limit chars
	text=$(item_value "$NAME" label)
	for arg in "$@"; do [[ "$arg" == label=* ]] && text=${arg#label=}; done

	read -r _ spaces_end < <(rect spaces) || return
	# The window title follows the active display. While another display (the
	# iPad) is active it isn't on this bar, so only the spaces bound Spotify; keep
	# the last measured spaces-to-title gap for that.
	if read -r title_start title_end < <(rect front_app); then
		gap=$((title_start - spaces_end))
		echo "$gap" >"$HOME/.cache/sketchybar/spotify-gap"
		limit=$((title_end + gap))
	else
		gap=$(cat "$HOME/.cache/sketchybar/spotify-gap" 2>/dev/null)
		limit=$((spaces_end + ${gap:-13}))
	fi

	# Whole text first; if it doesn't fit, step down from an estimate (7.7pt/char).
	sketchybar --set "$NAME" label.width=dynamic label.max_chars=0 label.padding_left=0 \
		label.drawing=on drawing=on "$@"
	read -r left right < <(rect "$NAME") || { sketchybar --set "$NAME" drawing=off; return; }
	if (( left < limit )); then
		chars=$(( ${#text} - ((limit - left) * 10 + 76) / 77 ))
		while (( chars > 2 )); do
			sketchybar --set "$NAME" label.max_chars="$chars"
			read -r left right < <(rect "$NAME")
			(( left >= limit )) && break
			(( chars -= 1 ))
		done
		# The estimate can start low: grow back while the next character still fits.
		while (( chars > 2 && chars < ${#text} )); do
			sketchybar --set "$NAME" label.max_chars=$((chars + 1))
			read -r left right < <(rect "$NAME")
			(( left < limit )) && { sketchybar --set "$NAME" label.max_chars="$chars"; read -r left right < <(rect "$NAME"); break; }
			(( chars += 1 ))
		done
		if (( chars <= 2 )); then
			sketchybar --set "$NAME" label.drawing=off # icon only
			read -r left right < <(rect "$NAME")
			(( left >= limit )) || { sketchybar --set "$NAME" drawing=off; return; }
		fi
		# Spare pixels go between the icon and the text, so the pill meets the gap
		# exactly and the outer padding stays the same as the window title's.
		(( left > limit && chars > 2 )) && sketchybar --set "$NAME" label.padding_left=$((left - limit))
	fi
	return 0
}

update() {
	local media state track icon
	if ! pgrep -x Spotify &>/dev/null; then
		sketchybar --set "$NAME" drawing=off label=""
		return
	fi

	if [[ -n "$PLAYER_STATE" ]]; then
		# Sent by spotify-listener straight from Spotify's notification.
		state=$(tr '[:upper:]' '[:lower:]' <<<"$PLAYER_STATE")
		track=$TRACK
	else
		media=$(osascript <<'APPLESCRIPT'
tell application "Spotify"
	if it is running then
		set playback to player state as string
		if playback is "playing" or playback is "paused" then
			return playback & linefeed & (name of current track) & " - " & (artist of current track)
		end if
	end if
end tell
APPLESCRIPT
		)
		state=${media%%$'\n'*}
		track=${media#*$'\n'}
	fi

	case "$state" in
		playing) icon="" ;;
		paused) icon="" ;;
		*) sketchybar --set "$NAME" drawing=off label=""; return ;;
	esac
	track=${track//$'\n'/ }
	track=${track//$'\r'/ }
	resize icon="$icon" label="$track"
}

case "$SENDER" in
	mouse.clicked)
		if [[ "$BUTTON" == right ]]; then
			osascript -e 'tell application "Spotify" to play next track'
		else
			# Flip the icon right away; Spotify's own notification lands ~1s later.
			if [[ "$(item_value "$NAME" icon)" == "" ]]; then
				sketchybar --set "$NAME" icon=""
			else
				sketchybar --set "$NAME" icon=""
			fi
			osascript -e 'tell application "Spotify" to playpause' &
		fi
		;;
	spotify_resize|space_change|display_change)
		if [[ -n "$(item_value "$NAME" label)" ]]; then
			resize
		fi
		;;
	*) update ;;
esac
