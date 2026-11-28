import AppKit
import Foundation
import SQLite3

struct Limits: Decodable {
    struct Window: Decodable {
        let kind: String
        let usedPercent: Double?
        let resetsAt: String?
        let windowDurationMins: Double?

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
    var previousRows = [String: String]()
    var previousImage: String?
    var previousActivity: String?
    var activity: Activity?
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

    static func span(_ minutes: Int) -> String {
        if minutes >= 1440 { return "\(minutes / 1440)d \(minutes % 1440 / 60)h" }
        if minutes >= 60 { return "\(minutes / 60)h\(String(format: "%02d", minutes % 60))m" }
        return "\(max(minutes, 0))m"
    }

    func changes(at now: Date) -> [String] {
        let window = limits?.windows.first { $0.kind == "session" }
        let remaining = window?.remaining
        let minutes = window?.minutesUntilReset(at: now)
        let stale = parseDate(limits?.checkedAt).map { now.timeIntervalSince($0) > 900 } ?? true
        let label = remaining.map { "\($0)%" } ?? "—"
        // Top edge: time left before the session resets (the even pace).
        // Bottom edge: usage left. Bottom shorter than top means ahead of pace.
        var fill = 0
        if let minutes, let duration = window?.windowDurationMins, duration > 0 {
            fill = Int((Double(max(0, minutes)) / duration * 100).rounded())
            fill = max(0, min(100, fill))
        }
        let usage = max(0, min(100, remaining ?? 0))
        var changes = [String]()
        // Size each half to its text: 25pt for the logo side, 5pt inside, and
        // ~7pt per character at 12pt.
        let labelWidth = label.count * 7 - 1
        let width = 30 + labelWidth
        if label != previousLabel {
            changes += ["label=\(label)", "label.width=\(labelWidth)", "width=\(width)"]
            previousLabel = label
        }
        if stale != previousStale {
            changes.append("label.color=\(stale ? "0xffa9b1d6" : color)")
            previousStale = stale
        }
        let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/sketchybar/icons")
        let path = directory.appendingPathComponent("session-pill-v4-\(name)-\(fill)-\(usage)-\(width)-\(color).png").path
        if path != previousImage {
            if !FileManager.default.fileExists(atPath: path) {
                run(pluginDir + "/session_limits.sh", [name, String(fill), String(usage), color, path, String(width)], wait: true)
            }
            if FileManager.default.fileExists(atPath: path) {
                changes.append("background.image=\(path)")
                previousImage = path
            }
        }
        var command = changes.isEmpty ? [] : ["--set", "session_limits.\(name)"] + changes
        // Popup rows: a bar of what's left with a tick at even pace, like T3.
        for (kind, short) in [("session", "5h"), ("weekly", "7d")] {
            let window = limits?.windows.first { $0.kind == kind }
            guard let left = window?.remaining else { continue }
            let minutes = window?.minutesUntilReset(at: now)
            var pace = "-"
            if let minutes, let duration = window?.windowDurationMins, duration > 0 {
                pace = String(max(0, min(100, Int((Double(max(0, minutes)) / duration * 100).rounded()))))
            }
            let reset = minutes.map { Meter.span($0) } ?? ""
            let key = "\(left)|\(pace)|\(reset)"
            guard previousRows[kind] != key else { continue }
            let file = directory.appendingPathComponent("session-bar-\(name)-\(kind).png").path
            run(pluginDir + "/session_bar.sh", [file, short, String(left), pace, reset, color], wait: true)
            // Same path each time, so toggle the image to make SketchyBar reload it.
            command += ["--set", "session_limits.\(name).\(kind)", "label.background.image=",
                        "--set", "session_limits.\(name).\(kind)", "label.background.image=\(file)"]
            previousRows[kind] = key
        }
        let activityLabel = activity?.label ?? ""
        if activityLabel != previousActivity {
            let title = name == "claude" ? "Claude" : "Codex"
            let text = activityLabel.isEmpty ? title : "\(title) · \(activityLabel)"
            command += ["--set", "session_limits.\(name).title", "label=\(text)"]
            previousActivity = activityLabel
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

@Sendable func watch(_ url: URL, _ events: DispatchSource.FileSystemEvent, onChange: @escaping () -> Void) -> DispatchSourceFileSystemObject? {
    let descriptor = open(url.path, O_EVTONLY)
    guard descriptor >= 0 else { return nil }
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: events, queue: queue)
    source.setEventHandler(handler: onChange)
    source.setCancelHandler { close(descriptor) }
    source.resume()
    return source
}

struct Activity {
    var running = 0
    var queued = 0
    var waiting = 0

    var label: String {
        var parts = [String]()
        if running > 0 { parts.append("\(running) running") }
        if queued > 0 { parts.append("\(queued) queued") }
        if waiting > 0 { parts.append("\(waiting) waiting") }
        return parts.isEmpty ? "idle" : parts.joined(separator: " · ")
    }
}

let stateDirectory = cache.deletingLastPathComponent().appendingPathComponent("userdata")
let database = stateDirectory.appendingPathComponent("statev2.sqlite")

// Only query the small, indexed set of unfinished runs. Open read-only so a
// display widget cannot alter T3 state.
func readActivity() -> [String: Activity]? {
    var connection: OpaquePointer?
    let result = sqlite3_open_v2(database.path, &connection, SQLITE_OPEN_READONLY, nil)
    defer { sqlite3_close(connection) }
    guard result == SQLITE_OK else { return nil }
    let sql = """
        SELECT provider, status, COUNT(DISTINCT thread_id)
        FROM orchestration_v2_projection_runs
        WHERE status IN ('running', 'waiting', 'preparing', 'queued', 'starting')
          AND completed_at IS NULL AND provider IN ('claudeAgent', 'codex')
        GROUP BY provider, status
        """
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
    defer { sqlite3_finalize(statement) }
    var counts = ["claude": Activity(), "codex": Activity()]
    var step = sqlite3_step(statement)
    while step == SQLITE_ROW {
        let provider = String(cString: sqlite3_column_text(statement, 0))
        let status = String(cString: sqlite3_column_text(statement, 1))
        let count = Int(sqlite3_column_int(statement, 2))
        let key = provider == "claudeAgent" ? "claude" : "codex"
        switch status {
        case "running": counts[key]?.running += count
        case "waiting": counts[key]?.waiting += count
        default: counts[key]?.queued += count
        }
        step = sqlite3_step(statement)
    }
    return step == SQLITE_DONE ? counts : nil
}

let meters = [Meter("claude", "claudeAgent.json", "0xffff9e64"), Meter("codex", "codex.json", "0xff7dcfff")]
var pending: DispatchWorkItem?
var activityPending = false
var databaseWatchers = [URL: DispatchSourceFileSystemObject]()
var databaseInodes = [URL: NSNumber]()

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

func refreshActivity() {
    let counts = readActivity()
    for meter in meters {
        meter.activity = counts?[meter.name]
    }
    updateLabels()
}

func scheduleActivity() {
    guard !activityPending else { return }
    activityPending = true
    queue.asyncAfter(deadline: .now() + .milliseconds(800)) {
        activityPending = false
        refreshActivity()
    }
}

func attachDatabaseWatchers() {
    for url in [database, URL(fileURLWithPath: database.path + "-wal")] {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let inode = attributes?[.systemFileNumber] as? NSNumber
        guard databaseInodes[url] != inode else { continue }
        databaseWatchers.removeValue(forKey: url)?.cancel()
        databaseInodes[url] = inode
        if inode != nil {
            databaseWatchers[url] = watch(url, [.write, .extend, .rename, .delete], onChange: scheduleActivity)
        }
        scheduleActivity()
    }
}

try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
let directoryWatcher = watch(cache, [.write, .rename, .delete], onChange: scheduleRefresh)
meters.forEach { $0.refresh(force: true) }
let stateWatcher = watch(stateDirectory, [.write], onChange: attachDatabaseWatchers)
attachDatabaseWatchers()
refreshActivity()

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
    attachDatabaseWatchers()
    scheduleActivity()
    scheduleMinute()
}
RunLoop.main.run()
