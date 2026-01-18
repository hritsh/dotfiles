#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

STATE_FILE="/tmp/sketchybar_stopwatch_state"
START_FILE="/tmp/sketchybar_stopwatch_start"
ELAPSED_FILE="/tmp/sketchybar_stopwatch_elapsed"
COLOR_FILE="/tmp/sketchybar_stopwatch_color"

# Initialize files if they don't exist
[ ! -f "$STATE_FILE" ] && echo "hidden" > "$STATE_FILE"
[ ! -f "$ELAPSED_FILE" ] && echo "0" > "$ELAPSED_FILE"
[ ! -f "$COLOR_FILE" ] && echo "red" > "$COLOR_FILE"

STATE=$(cat "$STATE_FILE")

format_time() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$((total_seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $seconds
}

# Handle clicks
case "$BUTTON" in
    "left")
        if [ "$STATE" = "hidden" ]; then
            # Show stopwatch and start it
            echo "running" > "$STATE_FILE"
            echo "$(date +%s)" > "$START_FILE"
            echo "0" > "$ELAPSED_FILE"
            echo "red" > "$COLOR_FILE"
            # Show stopwatch, hide calendar
            sketchybar --set stopwatch drawing=on \
                       --set calendar drawing=off
        elif [ "$STATE" = "running" ]; then
            # Pause stopwatch
            START=$(cat "$START_FILE")
            PREV_ELAPSED=$(cat "$ELAPSED_FILE")
            NOW=$(date +%s)
            TOTAL_ELAPSED=$((PREV_ELAPSED + NOW - START))
            echo "$TOTAL_ELAPSED" > "$ELAPSED_FILE"
            echo "paused" > "$STATE_FILE"
        elif [ "$STATE" = "paused" ]; then
            # Resume stopwatch
            echo "$(date +%s)" > "$START_FILE"
            echo "running" > "$STATE_FILE"
        fi
        ;;
    "right")
        # Reset and hide stopwatch, show calendar
        echo "hidden" > "$STATE_FILE"
        echo "0" > "$ELAPSED_FILE"
        sketchybar --set stopwatch drawing=off \
                   --set calendar drawing=on
        ;;
esac

# Re-read state after potential changes
STATE=$(cat "$STATE_FILE")

# Update display based on state
if [ "$STATE" = "running" ]; then
    START=$(cat "$START_FILE")
    PREV_ELAPSED=$(cat "$ELAPSED_FILE")
    NOW=$(date +%s)
    TOTAL_ELAPSED=$((PREV_ELAPSED + NOW - START))
    LABEL=$(format_time $TOTAL_ELAPSED)
    
    # Toggle color for blinking effect
    CURRENT_COLOR=$(cat "$COLOR_FILE")
    if [ "$CURRENT_COLOR" = "red" ]; then
        COLOR="$RED"
        echo "yellow" > "$COLOR_FILE"
    else
        COLOR="$YELLOW"
        echo "red" > "$COLOR_FILE"
    fi
    
    sketchybar --set stopwatch \
        icon="󱎫" \
        label="$LABEL" \
        icon.color="$COLOR" \
        label.color="$COLOR" \
        background.border_color="$COLOR"
elif [ "$STATE" = "paused" ]; then
    ELAPSED=$(cat "$ELAPSED_FILE")
    LABEL=$(format_time $ELAPSED)
    sketchybar --set stopwatch \
        icon="󰏤" \
        label="$LABEL" \
        icon.color="$YELLOW" \
        label.color="$YELLOW" \
        background.border_color="$YELLOW"
fi
