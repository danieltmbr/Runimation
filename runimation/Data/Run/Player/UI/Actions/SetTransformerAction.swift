import Foundation

/// Swaps the active run transformer, recomputing all run variants
/// without stopping the current playback.
///
/// ```swift
/// @Environment(\.setTransformer) private var setTransformer
/// setTransformer(SpeedWeightedRun())
/// ```
///
struct SetTransformerAction {

    private let body: (RunTransformer) -> Void

    init(_ body: @escaping (RunTransformer) -> Void = { _ in }) {
        self.body = body
    }

    init(player: RunPlayer) {
        self.init { player.setTransformer($0) }
    }

    func callAsFunction(_ transformer: RunTransformer) { body(transformer) }
}
