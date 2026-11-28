// Bring an app to the front without the Spaces slide animation.
// If the app's window is on another Space, jump there instantly first, then
// activate the app. Usage: instant-focus "<App Name>"
import AppKit

let args = CommandLine.arguments
guard args.count == 2 else { fputs("usage: instant-focus <App Name>\n", stderr); exit(2) }
let name = args[1]

func launch() -> Never {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-a", name]
    try? p.run()
    p.waitUntilExit()
    exit(p.terminationStatus)
}

guard let app = NSWorkspace.shared.runningApplications.first(where: {
    $0.localizedName?.caseInsensitiveCompare(name) == .orderedSame
}) else { launch() }

let cid = CGSMainConnectionID()
if case .elsewhere(let place) = locate(app.processIdentifier, cid) {
    jump(to: place, cid)
}

// Direct activation is ~200ms faster than `open -a`; fall back to it if macOS
// refuses (activation from a background process can be declined).
app.activate(options: [.activateAllWindows])
let deadline = Date().addingTimeInterval(0.15)
while Date() < deadline {
    if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier { exit(0) }
    CFRunLoopRunInMode(.defaultMode, 0.005, false)
}
launch()
