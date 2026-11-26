#!/usr/bin/env bash

source "${0%/*}/../variables.sh"

# The plugin runs from SketchyBar, which may have a minimal PATH.
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

left_edge() {
	sketchybar --query "$NAME" | jq -r '
		.bounding_rects["display-1"] | select(.origin[0] >= 0) | (.origin[0] | floor)'
}

# Spotify sits against the notch (position q) and grows to the left, so fit the
# longest label whose left edge still keeps a normal gap from the window title.
resize() {
	local title_end limit max_chars left
	local gap=10 # same visual gap as between the other pills
	title_end=$(sketchybar --query front_app | jq -r '
		.bounding_rects["display-1"] | select(.origin[0] >= 0) |
		(.origin[0] + .size[0] | ceil)') || return
	# front_app's rect includes its 5pt outer padding; measure from the pill itself.
	limit=$(( ${title_end:-0} - 5 + gap ))

	# Start one char over a rough estimate, then step down until it fits.
	max_chars=$(( ($(sketchybar --query displays | jq -r --argjson notch "$NOTCH_WIDTH" '
		.[] | select(."arrangement-id" == 1) | ((.frame.w - $notch) / 2 | floor)') - limit - 29) / 8 + 1 ))
	(( max_chars > 42 )) && max_chars=42

	while (( max_chars > 0 )); do
		sketchybar --set "$NAME" label.max_chars="$max_chars" label.drawing=on drawing=on "$@"
		left=$(left_edge)
		[[ -n "$left" ]] && (( left >= limit )) && return
		(( max_chars -= 1 ))
	done

	sketchybar --set "$NAME" label.drawing=off drawing=on "$@"
	left=$(left_edge)
	[[ -n "$left" ]] && (( left >= limit )) && return
	sketchybar --set "$NAME" drawing=off "$@"
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
	resize icon="$icon" label="$track"
}

case "$SENDER" in
	mouse.clicked)
		if [[ "$BUTTON" == right ]]; then
			osascript -e 'tell application "Spotify" to play next track'
		else
			# Flip the icon right away; Spotify's own notification lands ~1s later.
			if [[ "$(sketchybar --query "$NAME" | jq -r '.icon.value')" == "" ]]; then
				sketchybar --set "$NAME" icon=""
			else
				sketchybar --set "$NAME" icon=""
			fi
			osascript -e 'tell application "Spotify" to playpause' &
		fi
		;;
	spotify_resize|space_change|display_change)
		if [[ -n "$(sketchybar --query "$NAME" | jq -r '.label.value // empty')" ]]; then
			resize
		fi
		;;
	*) update ;;
esac
