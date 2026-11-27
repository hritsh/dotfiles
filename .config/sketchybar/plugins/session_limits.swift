import AppKit
import Foundation

struct Limits: Decodable {
    struct Window: Decodable {
        let kind: String
        let usedPercent: Double?
        let resetsAt: String?

        var remaining: Int? {
            usedPercent.map { Int(max(0, min(100, 100 - $0))) }
        }

        func minutesUntilReset(at now: Date) -> Int? {
            parseDate(resetsAt).map { Int(ceil($0.timeIntervalSince(now) / 60)) }
        }
    }
    let checkedAt: String?
    let windows: [Window]
}

struct Snapshot: Decodable {
    let usageLimits: Limits?
}

let arguments = CommandLine.arguments
guard arguments.count == 3, let barPID = Int32(arguments[2]) else { exit(1) }
let pluginDir = arguments[1]
let cache = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".t3/caches")
let queue = DispatchQueue.main
let owner = DispatchSource.makeProcessSource(identifier: barPID, eventMask: .exit, queue: queue)
owner.setEventHandler { exit(0) }
owner.resume()

let iso = ISO8601DateFormatter()
let isoFractional = ISO8601DateFormatter()
isoFractional.formatOptions.insert(.withFractionalSeconds)
func parseDate(_ value: String?) -> Date? {
    guard let value else { return nil }
    return isoFractional.date(from: value) ?? iso.date(from: value)
}

final class Meter {
    let name: String
    let url: URL
    let color: String
    var limits: Limits?
    var fingerprint: [FileAttributeKey: NSObject]?
    var watcher: DispatchSourceFileSystemObject?
    var previousLabel: String?
    var previousWeeklyLabel: String?
    var previousFill: Int?
    var previousStale: Bool?

    init(_ name: String, _ filename: String, _ color: String) {
        self.name = name
        self.url = cache.appendingPathComponent(filename)
        self.color = color
    }

    func refresh(force: Bool = false) {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let next = attributes.map { attrs in
            Dictionary(uniqueKeysWithValues: [FileAttributeKey.systemFileNumber, .modificationDate, .size].compactMap { key in
                (attrs[key] as? NSObject).map { (key, $0) }
            })
        }
        guard force || next != fingerprint else { return }
        if next?[.systemFileNumber] != fingerprint?[.systemFileNumber] || watcher == nil {
            watcher?.cancel()
            watcher = watch(url, [.write, .extend, .rename, .delete]) { scheduleRefresh() }
        }
        fingerprint = next
        if next == nil {
            limits = nil
        } else if let data = try? Data(contentsOf: url),
                  let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            limits = snapshot.usageLimits
        }
    }

    func changes(at now: Date) -> [String] {
        let window = limits?.windows.first { $0.kind == "session" }
        let remaining = window?.remaining
        let minutes = window?.minutesUntilReset(at: now)
        let stale = parseDate(limits?.checkedAt).map { now.timeIntervalSince($0) > 900 } ?? true
        var label = "—"
        if let remaining {
            if let minutes, minutes > 0 {
                let countdown = minutes >= 60 ? String(format: "%dh%02d", minutes / 60, minutes % 60) : "\(minutes)m"
                label = "\(remaining)% \(countdown)"
            } else {
                label = minutes == nil ? "\(remaining)%" : "\(remaining)% due"
            }
        }
        let fill = remaining ?? 0
        var changes = [String]()
        if label != previousLabel {
            changes.append("label=\(label)")
            previousLabel = label
        }
        if stale != previousStale {
            changes.append("label.color=\(stale ? "0xffa9b1d6" : color)")
            previousStale = stale
        }
        if fill != previousFill {
            let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/sketchybar/icons")
            let path = directory.appendingPathComponent("session-branded-fill-\(name)-\(fill)-\(color).png").path
            if !FileManager.default.fileExists(atPath: path) {
                run(pluginDir + "/session_limits.sh", [name, String(fill), color, path], wait: true)
            }
            if FileManager.default.fileExists(atPath: path) {
                changes.append("background.image=\(path)")
                previousFill = fill
            }
        }
        var command = changes.isEmpty ? [] : ["--set", "session_limits.\(name)"] + changes
        let weekly = limits?.windows.first { $0.kind == "weekly" }
        var weeklyLabel = "Unavailable"
        if let remaining = weekly?.remaining {
            weeklyLabel = "\(remaining)% left"
            if let minutes = weekly?.minutesUntilReset(at: now) {
                if minutes >= 1440 {
                    weeklyLabel += " · resets in \(minutes / 1440)d \(minutes % 1440 / 60)h"
                } else if minutes >= 60 {
                    weeklyLabel += " · resets in \(minutes / 60)h \(minutes % 60)m"
                } else if minutes > 0 {
                    weeklyLabel += " · resets in \(minutes)m"
                } else {
                    weeklyLabel += " · reset due"
                }
            }
        }
        if weeklyLabel != previousWeeklyLabel {
            command += ["--set", "session_limits.\(name).weekly", "label=\(weeklyLabel)"]
            previousWeeklyLabel = weeklyLabel
        }
        return command
    }
}

@Sendable func run(_ executable: String, _ arguments: [String], wait: Bool = false) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    if (try? process.run()) != nil && wait { process.waitUntilExit() }
}

func watch(_ url: URL, _ events: DispatchSource.FileSystemEvent, onChange: @escaping () -> Void) -> DispatchSourceFileSystemObject? {
    let descriptor = open(url.path, O_EVTONLY)
    guard descriptor >= 0 else { return nil }
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: events, queue: queue)
    source.setEventHandler(handler: onChange)
    source.setCancelHandler { close(descriptor) }
    source.resume()
    return source
}

let meters = [Meter("claude", "claudeAgent.json", "0xffff9e64"), Meter("codex", "codex.json", "0xff7dcfff")]
var pending: DispatchWorkItem?

@Sendable func updateLabels() {
    let now = Date()
    let changes = meters.flatMap { $0.changes(at: now) }
    if !changes.isEmpty { run("/opt/homebrew/bin/sketchybar", changes, wait: true) }
}

func scheduleRefresh() {
    pending?.cancel()
    let task = DispatchWorkItem {
        meters.forEach { $0.refresh() }
        updateLabels()
    }
    pending = task
    queue.asyncAfter(deadline: .now() + .milliseconds(150), execute: task)
}

try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
let directoryWatcher = watch(cache, [.write, .rename, .delete], onChange: scheduleRefresh)
meters.forEach { $0.refresh(force: true) }
updateLabels()

// The clock ticks on minute boundaries. It uses in-memory values only.
let timer = DispatchSource.makeTimerSource(queue: queue)
func scheduleMinute() {
    let interval = Date().timeIntervalSince1970
    timer.schedule(deadline: .now() + (60 - interval.truncatingRemainder(dividingBy: 60)), leeway: .milliseconds(500))
}
timer.setEventHandler {
    updateLabels()
    scheduleMinute()
}
scheduleMinute()
timer.resume()

let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
    scheduleRefresh()
    scheduleMinute()
}
RunLoop.main.run()
