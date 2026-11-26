#!/bin/bash

get_ticktick_count() {
  lsappinfo -all info -only StatusLabel "TickTick" | awk -F'"' '/StatusLabel/ { gsub(",", "", $6); print $6 }'
}

get_dock_badge() {
	/usr/bin/lsappinfo -all info -only StatusLabel "$1" | sed -nE 's/.*"StatusLabel"=\{ "label"="([^"]*)".*/\1/p'
}

notification_counter_update() {
  local beeper_count=$(get_dock_badge com.automattic.beeper.desktop)
  local beeper_count_clean=${beeper_count//,/}
  local ticktick_count=$(get_ticktick_count)
  local mail_count=$(get_dock_badge com.deanoss.comail)
  local mail_count_clean=${mail_count//,/}

  local label=""

  [ "$ticktick_count" -gt 0 ] 2>/dev/null && label+="${label:+ } ${ticktick_count}"
  if [[ "$beeper_count_clean" =~ ^[1-9][0-9]*[+]?$ ]]; then
    label+="${label:+ }󰭹 ${beeper_count}"
  fi
  if [[ "$mail_count_clean" =~ ^[1-9][0-9]*$ ]]; then
    mail_count=$(printf '%s\n' "$mail_count_clean" | /usr/bin/sed -E \
      -e ':group' -e 's/^([0-9]+)([0-9]{3})(,|$)/\1,\2\3/' -e 't group')
    label+="${label:+ } ${mail_count}"
  fi

  [[ -z $label ]] && label=" •"

  sketchybar --set notification_counter label="${label}"
}

# Initial update
notification_counter_update
