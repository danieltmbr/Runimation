import Foundation
import RunKit

/// Replaces the active transformer chain, recomputing all run variants
/// without stopping the current playback.
///
/// Resolves when the player has finished reprocessing with the new chain.
/// Throws `CancellationError` if preempted by a subsequent processing call.
///
/// ```swift
/// @Environment(\.setTransformers) private var setTransformers
/// try? await setTransformers([GuassianRun(), SpeedWeightedRun()])
/// ```
///
public struct SetTransformerAction {

    private let body: @MainActor ([any RunTransformer]) async throws -> Void

    init(_ body: @escaping @MainActor ([any RunTransformer]) async throws -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { try await player.setTransformers($0) }
    }

    @MainActor
    public func callAsFunction(_ transformers: [any RunTransformer]) async throws { try await body(transformers) }
}
