#!/usr/bin/env bash

sketchybar --set "$NAME" icon="" label="$(plugins/wattsec-cli | awk '{printf "%.2fW", $1}')"