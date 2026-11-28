#!/usr/bin/env bash
# Right click on the wattage widget: connect the iPad as a Sidecar display, or
# disconnect it if it's already one.
[[ "$BUTTON" == right ]] || exit 0
launcher="$HOME/.local/bin/SidecarLauncher"
device="iPad"
[[ -x "$launcher" ]] || exit 0
if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Sidecar Display"; then
	sketchybar --set wattage label="iPad off…"
	"$launcher" disconnect "$device" >/dev/null 2>&1
else
	sketchybar --set wattage label="iPad…"
	"$launcher" connect "$device" >/dev/null 2>&1 || sketchybar --set wattage label="no iPad"
fi
