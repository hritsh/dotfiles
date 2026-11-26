#!/usr/bin/env bash

source "${0%/*}/../variables.sh"

# The plugin runs from SketchyBar, which may have a minimal PATH.
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

resize() {
	local display title_end available max_chars right notch_start
	local gap=8
	display=$(sketchybar --query displays) || return
	title_end=$(sketchybar --query front_app | jq -r '
		.bounding_rects["display-1"] | select(.origin[0] >= 0) |
		(.origin[0] + .size[0] | ceil)') || return
	notch_start=$(jq -r --argjson notch "$NOTCH_WIDTH" '
		.[] | select(."arrangement-id" == 1) |
		((.frame.x + (.frame.w - $notch) / 2 - 3) | floor)
	' <<< "$display") || return
	[[ -n "$notch_start" ]] || return
	available=$((notch_start - ${title_end:-0} - gap))

	# Leave room for the icon and label padding before budgeting text.
	max_chars=$(( (available - 29) / 8 ))
	(( max_chars > 42 )) && max_chars=42

	while (( max_chars > 0 )); do
		sketchybar --set "$NAME" label.max_chars="$max_chars" label.drawing=on drawing=on "$@"
		right=$(sketchybar --query "$NAME" | jq -r '
			.bounding_rects["display-1"] | select(.origin[0] >= 0) |
			(.origin[0] + .size[0] | ceil)')
		# Check the rendered bounds too, since fallback glyphs can be wider.
		[[ -n "$right" ]] && (( right <= notch_start )) && return
		(( max_chars -= 1 ))
	done

	if (( available >= 22 )); then
		sketchybar --set "$NAME" label.drawing=off drawing=on "$@"
		right=$(sketchybar --query "$NAME" | jq -r '
			.bounding_rects["display-1"] | select(.origin[0] >= 0) |
			(.origin[0] + .size[0] | ceil)')
		[[ -n "$right" ]] && (( right <= notch_start )) && return
	fi
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
