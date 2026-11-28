// Bring an app to the front without the Spaces slide animation.
// If the app's window is on another Space, jump there instantly first (with
// InstantSpaceSwitcher's synthetic dock swipe), then activate the app.
// Usage: instant-focus "<App Name>"
import AppKit

@_silgen_name("CGSMainConnectionID") func CGSMainConnectionID() -> Int32
@_silgen_name("CGSCopyManagedDisplaySpaces") func CGSCopyManagedDisplaySpaces(_ cid: Int32) -> CFArray
@_silgen_name("CGSCopySpacesForWindows") func CGSCopySpacesForWindows(_ cid: Int32, _ mask: Int32, _ windows: CFArray) -> CFArray?
@_silgen_name("CGSGetActiveSpace") func CGSGetActiveSpace(_ cid: Int32) -> UInt64

let args = CommandLine.arguments
guard args.count == 2 else { fputs("usage: instant-focus <App Name>\n", stderr); exit(2) }
let name = args[1]
let t0 = Date()
func mark(_ s: String) { if ProcessInfo.processInfo.environment["IF_DEBUG"] != nil { fputs("\(s) \(Int(Date().timeIntervalSince(t0)*1000))ms\n", stderr) } }

func launch() -> Never {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-a", name]
    try? p.run()
    p.waitUntilExit()
    mark("open")
    exit(p.terminationStatus)
}

guard let app = NSWorkspace.shared.runningApplications.first(where: {
    $0.localizedName?.caseInsensitiveCompare(name) == .orderedSame
}) else { launch() }

mark("apps")
let cid = CGSMainConnectionID()

// Every user Space: which display it's on, its position there, whether it's showing.
struct Place { let display: String; let index: Int; let current: Bool }
var places = [UInt64: Place]()
for display in CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] ?? [] {
    let uuid = display["Display Identifier"] as? String ?? ""
    let current = (display["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? UInt64
    let spaces = (display["Spaces"] as? [[String: Any]] ?? []).filter { ($0["type"] as? Int) == 0 }
    for (i, space) in spaces.enumerated() {
        guard let id = space["ManagedSpaceID"] as? UInt64 else { continue }
        places[id] = Place(display: uuid, index: i, current: id == current)
    }
}

mark("spaces")
// The app's normal windows, front to back (most recently used first).
let windows = (CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? [])
    .filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == app.processIdentifier && ($0[kCGWindowLayer as String] as? Int) == 0 }
    .filter {
        let b = $0[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
        return (b["Width"] ?? 0) > 60 && (b["Height"] ?? 0) > 60
    }
    .compactMap { $0[kCGWindowNumber as String] as? UInt32 }

mark("windows")
var target: (space: UInt64, place: Place)?
for window in windows {
    let ids = CGSCopySpacesForWindows(cid, 7, [window] as CFArray) as? [UInt64] ?? []
    let found = ids.compactMap { id in places[id].map { (id, $0) } }
    if found.contains(where: { $0.1.current }) { target = nil; break } // already visible
    if target == nil, let first = found.first { target = first }
}

func activate() -> Never {
    // Direct activation is ~200ms faster than `open -a`; fall back to it if macOS
    // refuses (activation from a background process can be declined).
    app.activate(options: [.activateAllWindows])
    let deadline = Date().addingTimeInterval(0.15)
    while Date() < deadline {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
            mark("activated"); exit(0)
        }
        CFRunLoopRunInMode(.defaultMode, 0.005, false)
    }
    launch()
}

guard let target else { activate() }

// The swipe goes to the display under the pointer, so park it there if needed.
let screens = NSScreen.screens.compactMap { screen -> (String, CGRect)? in
    guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
          let uuid = CGDisplayCreateUUIDFromDisplayID(number)?.takeRetainedValue() else { return nil }
    return (CFUUIDCreateString(nil, uuid) as String, CGDisplayBounds(number))
}
let pointer = CGEvent(source: nil)?.location ?? .zero
var restore: CGPoint?
if let bounds = screens.first(where: { $0.0.caseInsensitiveCompare(target.place.display) == .orderedSame })?.1,
   !bounds.contains(pointer) {
    CGWarpMouseCursorPosition(CGPoint(x: bounds.midX, y: bounds.midY))
    restore = pointer
}

mark("lookup")
guard iss_init() else { activate() }
mark("init")
_ = iss_switch_to_index(UInt32(target.place.index))
// Wait only until the Space has actually changed (normally a few ms).
let deadline = Date().addingTimeInterval(0.4)
while Date() < deadline {
    let now = (CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] ?? []).contains {
        (($0["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? UInt64) == target.space
    }
    if now { break }
    CFRunLoopRunInMode(.defaultMode, 0.01, false)
}
mark("switched")
iss_destroy()
if let restore { CGWarpMouseCursorPosition(restore) }
activate()
