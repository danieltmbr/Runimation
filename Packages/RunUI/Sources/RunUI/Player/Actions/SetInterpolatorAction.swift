import Foundation
import RunKit

/// Swaps the active run interpolator, recomputing all run variants
/// without stopping the current playback.
///
/// Resolves when the player has finished reprocessing with the new interpolator.
/// Throws `CancellationError` if preempted by a subsequent processing call.
///
public struct SetInterpolatorAction {

    private let body: @MainActor (any RunInterpolator) async throws -> Void

    init(_ body: @escaping @MainActor (any RunInterpolator) async throws -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { try await player.setInterpolator($0) }
    }

    @MainActor
    public func callAsFunction(_ interpolator: any RunInterpolator) async throws { try await body(interpolator) }
}
