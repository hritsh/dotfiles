eval "$(/opt/homebrew/bin/brew shellenv)"

##
# Your previous /Users/hritish/.zprofile file was backed up as /Users/hritish/.zprofile.macports-saved_2022-03-27_at_17:34:06
##

# MacPorts Installer addition on 2022-03-27_at_17:34:06: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.


# MacPorts Installer addition on 2022-03-27_at_17:34:06: adding an appropriate MANPATH variable for use with MacPorts.
export MANPATH="/opt/local/share/man:$MANPATH"
# Finished adapting your MANPATH environment variable for use with MacPorts.

function firefox-window() {
/usr/bin/env osascript <<-EOF
tell application "System Events"
    if (name of processes) contains "Firefox" then
        tell application "Firefox" to activate
        keystroke "n" using command down
    else
        tell application "Firefox" to activate
    end if
end tell
EOF
}
