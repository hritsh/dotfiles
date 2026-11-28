// Background helper: whenever an app becomes active (Cmd-Tab, Dock, a notification,
// a link...) and none of its windows are on a Space that's showing, jump to its
// most recent window's Space instantly. Pair it with macOS's own switch turned off:
//   defaults write com.apple.dock workspaces-auto-swoosh -bool false; killall Dock
// Event driven only: it sleeps until macOS posts an activation.
import AppKit

let cid = CGSMainConnectionID()
// Accessibility is needed to post the swipe; ask once, then keep checking per event.
_ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)

let observer = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
) { note in
    guard AXIsProcessTrusted(),
          let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          app.activationPolicy == .regular,
          case .elsewhere(let place) = locate(app.processIdentifier, cid) else { return }
    jump(to: place, cid)
}
RunLoop.main.run()
