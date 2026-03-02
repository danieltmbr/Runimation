import Foundation
import RunKit

/// Replaces the active transformer chain with a single transformer, recomputing
/// all run variants without stopping the current playback.
///
/// ```swift
/// @Environment(\.setTransformer) private var setTransformer
/// setTransformer(SpeedWeightedRun())
/// ```
///
public struct SetTransformerAction {

    private let body: @MainActor (any RunTransformer) -> Void

    init(_ body: @escaping @MainActor (any RunTransformer) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.transformers = [$0] }
    }

    @MainActor
    public func callAsFunction(_ transformer: any RunTransformer) { body(transformer) }
}
