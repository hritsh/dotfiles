// Forwards Spotify's playback notification to SketchyBar exactly once per change.
// SketchyBar's own notification events stack an extra observer on every --reload.
import Foundation

func trigger(_ info: [AnyHashable: Any]) {
    let state = (info["Player State"] as? String) ?? ""
    let name = (info["Name"] as? String) ?? ""
    let artist = (info["Artist"] as? String) ?? ""
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/sketchybar")
    p.arguments = ["--trigger", "spotify_change", "PLAYER_STATE=\(state)", "TRACK=\(name) - \(artist)"]
    try? p.run()
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main
) { note in trigger(note.userInfo ?? [:]) }
RunLoop.main.run()
