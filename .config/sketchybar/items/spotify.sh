#!/usr/bin/env sh
SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

sketchybar --add       event           spotify_change $SPOTIFY_EVENT        \
           --add       item            spotify.anchor right                \
           --set       spotify.anchor  script="$PLUGIN_DIR/spotify.sh"      \
                                       icon=$ICON_SPOTIFY                               \
                                       icon.color=$BAR_GREEN \
                                       icon.padding_left=$DATA_ICON_PADDING_LEFT \
                                       label.color=$BAR_GREEN \
                                       label="N/A"      \
                                       label.padding_right=$DATA_LABEL_PADDING_RIGHT \
                                       label.width="dynamic" \
                                       icon.padding_right=$DATA_ICON_PADDING_RIGHT              \
           --subscribe spotify.anchor  mouse.clicked                        \
                                       spotify_change                       \
           --add       event           spotify.play popup.spotify.anchor    \
           --subscribe spotify.play    mouse.clicked spotify_change         \