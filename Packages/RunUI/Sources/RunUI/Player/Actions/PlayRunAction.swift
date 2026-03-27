import Foundation
import RunKit
import CoreKit

/// Loads a run into the player, stopping any current playback.
///
/// Supports both a parsed `Run` and a raw `GPX.Track`:
/// ```swift
/// @Environment(\.playRun) private var playRun
/// playRun(run)
/// playRun(gpxTrack)
/// ```
///
public struct PlayRunAction {

    private let playRun: @MainActor (Run) -> Void

    private let playTrack: @MainActor (GPX.Track) -> Void

    init(
        run: @escaping @MainActor (Run) -> Void = { _ in },
        track: @escaping @MainActor (GPX.Track) -> Void = { _ in }
    ) {
        playRun = run
        playTrack = track
    }

    @MainActor
    init(player: RunPlayer) {
        self.init(
            run: { run in Task { try? await player.setRun(run) } },
            track: { track in Task { try? await player.setRun(track) } }
        )
    }

    @MainActor
    public func callAsFunction(_ run: Run) { playRun(run) }

    @MainActor
    public func callAsFunction(_ track: GPX.Track) { playTrack(track) }
}
