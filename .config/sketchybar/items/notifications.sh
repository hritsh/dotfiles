#!/bin/bash

sketchybar --add item notification_counter right \
  --set notification_counter \
  update_freq=5 \
  label.font="$FONT:Regular:15.5" \
  background.padding_left=10 \
  background.padding_right=3 \
  label.padding_right=1 \
  script="$PLUGIN_DIR/notifications.sh"

# sketchybar --add event notification_update system_woke
# sketchybar --subscribe notification_counter notification_update
