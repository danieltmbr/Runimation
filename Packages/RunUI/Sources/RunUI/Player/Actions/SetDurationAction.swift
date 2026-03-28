import Foundation
import RunKit

/// Sets the playback duration preset, recomputing all run variants
/// without stopping the current playback.
///
/// Resolves when the player has finished reprocessing with the new duration.
/// Throws `CancellationError` if preempted by a subsequent processing call.
///
/// ```swift
/// @Environment(\.setDuration) private var setDuration
/// try? await setDuration(.thirtySeconds)
/// ```
///
public struct SetDurationAction {

    private let body: @MainActor (RunPlayer.Duration) async throws -> Void

    init(_ body: @escaping @MainActor (RunPlayer.Duration) async throws -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { try await player.setDuration($0) }
    }

    @MainActor
    public func callAsFunction(_ duration: RunPlayer.Duration) async throws { try await body(duration) }
}
