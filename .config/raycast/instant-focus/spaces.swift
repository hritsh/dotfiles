// Shared by instant-focus and instant-follow: find the Space an app's most recent
// window is on and jump there with InstantSpaceSwitcher's synthetic dock swipe.
import AppKit

@_silgen_name("CGSMainConnectionID") func CGSMainConnectionID() -> Int32
@_silgen_name("CGSCopyManagedDisplaySpaces") func CGSCopyManagedDisplaySpaces(_ cid: Int32) -> CFArray
@_silgen_name("CGSCopySpacesForWindows") func CGSCopySpacesForWindows(_ cid: Int32, _ mask: Int32, _ windows: CFArray) -> CFArray?

struct Place { let space: UInt64; let display: String; let index: Int; let current: Bool }

enum Where {
    case visible          // a window is on a Space that's showing (or no windows at all)
    case elsewhere(Place) // most recent window is on a hidden Space
}

func currentSpaces(_ cid: Int32) -> Set<UInt64> {
    Set((CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] ?? []).compactMap {
        ($0["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? UInt64
    })
}

func locate(_ pid: pid_t, _ cid: Int32) -> Where {
    var places = [UInt64: Place]()
    for display in CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] ?? [] {
        let uuid = display["Display Identifier"] as? String ?? ""
        let current = (display["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? UInt64
        let spaces = (display["Spaces"] as? [[String: Any]] ?? []).filter { ($0["type"] as? Int) == 0 }
        for (i, space) in spaces.enumerated() {
            guard let id = space["ManagedSpaceID"] as? UInt64 else { continue }
            places[id] = Place(space: id, display: uuid, index: i, current: id == current)
        }
    }
    // Normal windows, front to back (most recently used first).
    let windows = (CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? [])
        .filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }
        .filter {
            let b = $0[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
            return (b["Width"] ?? 0) > 60 && (b["Height"] ?? 0) > 60
        }
        .compactMap { $0[kCGWindowNumber as String] as? UInt32 }
    var target: Place?
    for window in windows {
        let found = (CGSCopySpacesForWindows(cid, 7, [window] as CFArray) as? [UInt64] ?? []).compactMap { places[$0] }
        if found.contains(where: { $0.current }) { return .visible }
        if target == nil { target = found.first }
    }
    return target.map { .elsewhere($0) } ?? .visible
}

/// Jump to `place` without the slide. Returns once the Space is showing (or 0.4s).
@discardableResult
func jump(to place: Place, _ cid: Int32) -> Bool {
    // The swipe goes to the display under the pointer, so park it there if needed.
    var bounds: CGRect?
    for screen in NSScreen.screens {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let uuid = CGDisplayCreateUUIDFromDisplayID(number)?.takeRetainedValue(),
              (CFUUIDCreateString(nil, uuid) as String).caseInsensitiveCompare(place.display) == .orderedSame else { continue }
        bounds = CGDisplayBounds(number)
    }
    let pointer = CGEvent(source: nil)?.location ?? .zero
    var restore: CGPoint?
    if let bounds, !bounds.contains(pointer) {
        CGWarpMouseCursorPosition(CGPoint(x: bounds.midX, y: bounds.midY))
        restore = pointer
    }
    defer { if let restore { CGWarpMouseCursorPosition(restore) } }

    guard iss_init() else { return false }
    defer { iss_destroy() }
    _ = iss_switch_to_index(UInt32(place.index))
    let deadline = Date().addingTimeInterval(0.4)
    while Date() < deadline {
        if currentSpaces(cid).contains(place.space) { return true }
        CFRunLoopRunInMode(.defaultMode, 0.01, false)
    }
    return false
}
