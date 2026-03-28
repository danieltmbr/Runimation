import Foundation
import RunKit
import CoreKit

/// Loads a run into the player, stopping any current playback.
///
/// Resolves when the player has finished processing and is ready to play.
/// Throws `CancellationError` if preempted by a subsequent call.
///
/// Supports both a parsed `Run` and a raw `GPX.Track`:
/// ```swift
/// @Environment(\.playRun) private var playRun
/// try? await playRun(run)
/// try? await playRun(gpxTrack)
/// ```
///
public struct PlayRunAction {

    private let playRun: @MainActor (Run) async throws -> Void

    private let playTrack: @MainActor (GPX.Track) async throws -> Void

    init(
        run: @escaping @MainActor (Run) async throws -> Void = { _ in },
        track: @escaping @MainActor (GPX.Track) async throws -> Void = { _ in }
    ) {
        playRun = run
        playTrack = track
    }

    @MainActor
    init(player: RunPlayer) {
        self.init(
            run: {
                try await player.setRun($0);
                player.play()
            },
            track: {
                try await player.setRun($0);
                player.play()
            }
        )
    }

    @MainActor
    public func callAsFunction(_ run: Run) async throws { try await playRun(run) }

    @MainActor
    public func callAsFunction(_ track: GPX.Track) async throws { try await playTrack(track) }
}
