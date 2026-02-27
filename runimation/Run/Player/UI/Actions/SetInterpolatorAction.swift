import Foundation

/// Swaps the active run interpolator, recomputing all run variants
/// without stopping the current playback.
///
struct SetInterpolatorAction {

    private let body: (RunInterpolatorOption) -> Void

    init(_ body: @escaping (RunInterpolatorOption) -> Void = { _ in }) {
        self.body = body
    }

    init(player: RunPlayer) {
        self.init { player.setInterpolator($0) }
    }

    func callAsFunction(_ option: RunInterpolatorOption) { body(option) }
}
