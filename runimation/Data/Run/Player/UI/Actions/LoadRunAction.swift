import Foundation

/// Loads a run into the player, stopping any current playback.
///
/// Supports both a parsed `Run` and a raw `GPX.Track`:
/// ```swift
/// @Environment(\.loadRun) private var loadRun
/// loadRun(run)
/// loadRun(gpxTrack)
/// ```
///
struct LoadRunAction {

    private let loadRun: (Run) -> Void
    private let loadTrack: (GPX.Track) -> Void

    init(
        run: @escaping (Run) -> Void = { _ in },
        track: @escaping (GPX.Track) -> Void = { _ in }
    ) {
        loadRun = run
        loadTrack = track
    }

    init(player: RunPlayer) {
        self.init(
            run: { player.setRun($0) },
            track: { player.setRun($0) }
        )
    }

    func callAsFunction(_ run: Run) { loadRun(run) }

    func callAsFunction(_ track: GPX.Track) { loadTrack(track) }
}
