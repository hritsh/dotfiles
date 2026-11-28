#!/usr/bin/env bash

read -r time ampm day date < <(date '+%l:%M %p %a %m/%d')
sketchybar --set clock label="$time" --set clock.ampm label="$ampm" \
	--set clock.day label="$day" --set clock.date label="$date"
