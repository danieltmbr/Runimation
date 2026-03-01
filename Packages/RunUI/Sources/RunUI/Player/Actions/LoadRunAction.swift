import Foundation
import RunKit

/// Loads a run into the player, stopping any current playback.
///
/// Supports both a parsed `Run` and a raw `GPX.Track`:
/// ```swift
/// @Environment(\.loadRun) private var loadRun
/// loadRun(run)
/// loadRun(gpxTrack)
/// ```
///
public struct LoadRunAction {

    private let loadRun: @MainActor (Run) -> Void

    private let loadTrack: @MainActor (GPX.Track) -> Void

    init(
        run: @escaping @MainActor (Run) -> Void = { _ in },
        track: @escaping @MainActor (GPX.Track) -> Void = { _ in }
    ) {
        loadRun = run
        loadTrack = track
    }

    @MainActor
    init(player: RunPlayer) {
        self.init(
            run: { run in Task { try? await player.setRun(run) } },
            track: { track in Task { try? await player.setRun(track) } }
        )
    }

    @MainActor
    public func callAsFunction(_ run: Run) { loadRun(run) }

    @MainActor
    public func callAsFunction(_ track: GPX.Track) { loadTrack(track) }
}
