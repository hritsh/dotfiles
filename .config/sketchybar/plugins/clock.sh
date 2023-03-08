#!/usr/bin/env sh
source "$HOME/.config/sketchybar/icons.sh"

ICON="$ICON_CLOCK"
LABEL=$(date '+%H:%M:%S')
# 12 hour format
LABEL=$(date '+%I:%M %p')
sketchybar --set $NAME icon="$ICON" label="$LABEL"