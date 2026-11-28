// Maximise the focused window on whatever screen it's on, leaving the top
// strip free for SketchyBar (32pt is what the bar visibly covers).
import AppKit
import ApplicationServices

let barHeight: CGFloat = 32

guard AXIsProcessTrusted() else {
    print("Needs Accessibility permission"); exit(1)
}
guard let app = NSWorkspace.shared.frontmostApplication else { exit(1) }
let axApp = AXUIElementCreateApplication(app.processIdentifier)
var ref: CFTypeRef?
guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &ref) == .success else {
    print("No focused window"); exit(1)
}
let window = ref as! AXUIElement

func point(_ attribute: String) -> CGPoint? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(window, attribute as CFString, &value) == .success else { return nil }
    var p = CGPoint.zero
    AXValueGetValue(value as! AXValue, .cgPoint, &p)
    return p
}
func size() -> CGSize? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &value) == .success else { return nil }
    var s = CGSize.zero
    AXValueGetValue(value as! AXValue, .cgSize, &s)
    return s
}
guard let origin = point(kAXPositionAttribute), let current = size(),
      let primary = NSScreen.screens.first else { exit(1) }

// AX uses top-left coordinates from the primary screen; NSScreen uses bottom-left.
let flip = { (r: CGRect) in CGRect(x: r.minX, y: primary.frame.maxY - r.maxY, width: r.width, height: r.height) }
let center = CGPoint(x: origin.x + current.width / 2, y: origin.y + current.height / 2)
let screen = NSScreen.screens.first { flip($0.frame).contains(center) } ?? NSScreen.main ?? primary

let frame = flip(screen.frame)
let visible = flip(screen.visibleFrame)
let top = max(visible.minY, frame.minY + barHeight)
var target = CGRect(x: visible.minX, y: top, width: visible.width, height: visible.maxY - top)

func set(_ attribute: String, _ value: AXValue) {
    AXUIElementSetAttributeValue(window, attribute as CFString, value)
}
var p = target.origin, s = target.size
// Position, size, then position again: some apps clamp size against the old spot.
set(kAXPositionAttribute, AXValueCreate(.cgPoint, &p)!)
set(kAXSizeAttribute, AXValueCreate(.cgSize, &s)!)
set(kAXPositionAttribute, AXValueCreate(.cgPoint, &p)!)
