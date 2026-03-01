import Foundation
import RunKit

/// Swaps the active run transformer, recomputing all run variants
/// without stopping the current playback.
///
/// ```swift
/// @Environment(\.setTransformer) private var setTransformer
/// setTransformer(SpeedWeightedRun())
/// ```
///
public struct SetTransformerAction {

    private let body: @MainActor (RunTransformer) -> Void

    init(_ body: @escaping @MainActor (RunTransformer) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.setTransformer($0) }
    }

    @MainActor
    public func callAsFunction(_ transformer: RunTransformer) { body(transformer) }
}
