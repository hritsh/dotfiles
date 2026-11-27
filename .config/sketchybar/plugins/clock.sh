#!/usr/bin/env bash

label=$(date '+%l:%M %p %a %m/%d')
sketchybar --set "$NAME" label="${label# }"
