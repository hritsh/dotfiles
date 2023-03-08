#!/bin/sh
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

next ()
{
  osascript -e 'tell application "Spotify" to play next track'
}

play () 
{
  osascript -e 'tell application "Spotify" to playpause'
}

update ()
{
  PLAYING=1
  if [ "$(echo "$INFO" | jq -r '.["Player State"]')" = "Playing" ]; then
    PLAYING=0
    LABEL_TITLE="$(echo $(echo "$INFO" | jq -r .Artist) - $(echo "$INFO" | jq -r .Name))"
    # check if app is closed
  elif [ "$(echo "$INFO" | jq -r '.["Player State"]')" = "Stopped" ]; then
    PLAYING=-1
    LABEL_TITLE=""
  fi

  args=()
  if [ $PLAYING -eq 0 ]; then
    args+=(--set spotify.anchor icon=$ICON_SPOTIFY label="$LABEL_TITLE" icon.padding_left=6)
  elif [ $PLAYING -eq 1 ]; then
    args+=(--set spotify.anchor icon=$ICON_SPOTIFY_PAUSE_BAR drawing=on icon.padding_left=6 icon.padding_right=3)
  else
    args+=(--set spotify.anchor icon= label="$LABEL_TITLE" drawing=off)
  fi
  sketchybar -m "${args[@]}"
}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    next
  else
    play
  fi
}

add_hover() {
    sketchybar --animate linear 10 --set $NAME background.border_color=$BAR_GREEN
}

remove_hover() {
    sketchybar --animate linear 10 --set $NAME background.border_color=$BAR_BACKGROUND
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "mouse.entered") add_hover
  ;;
  "mouse.exited") remove_hover
  ;;
  *) update
  ;;
esac