#!/bin/bash

# Function to get WhatsApp notifications using AppleScript
get_whatsapp_count() {
  osascript <<EOF
    set appList to {"WhatsApp"}
    set totalUnread to 0
    
    tell application "System Events"
      tell process "Dock"
        try
          repeat with appName in appList
            set unreadCount to value of attribute "AXStatusLabel" of UI element appName of list 1
            if unreadCount exists then
              set totalUnread to totalUnread + unreadCount
            end if
          end repeat
          return totalUnread
        on error errMsg
          return 0
        end try
      end tell
    end tell
EOF
}

get_ticktick_count() {
  lsappinfo -all info -only StatusLabel "TickTick" | awk -F'"' '/StatusLabel/ { gsub(",", "", $6); print $6 }'
}

get_mail_count() {
	lsappinfo -all info -only StatusLabel "Mail" | sed -nE 's/.*"StatusLabel"=\{ "label"="([^"]*)".*/\1/p'
}

notification_counter_update() {
  local whatsapp_count=$(get_whatsapp_count)
  local ticktick_count=$(get_ticktick_count)
  local mail_count=$(get_mail_count)
  local mail_count_clean=${mail_count//,/}

  local label=""

  [ "$ticktick_count" -gt 0 ] 2>/dev/null && label+="   ${ticktick_count}"
  [ "$whatsapp_count" -gt 0 ] 2>/dev/null && label+="   ${whatsapp_count}"
  [ "$mail_count_clean" -gt 0 ] 2>/dev/null && label+="   ${mail_count} ."

  [[ -z $label ]] && label=" •"

  sketchybar --set notification_counter label="${label}"
}

# Initial update
notification_counter_update
