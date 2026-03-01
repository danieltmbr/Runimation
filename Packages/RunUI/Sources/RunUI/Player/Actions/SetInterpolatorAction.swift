import Foundation
import RunKit

/// Swaps the active run interpolator, recomputing all run variants
/// without stopping the current playback.
///
public struct SetInterpolatorAction {

    private let body: @MainActor (RunInterpolatorOption) -> Void

    init(_ body: @escaping @MainActor (RunInterpolatorOption) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.setInterpolator($0) }
    }

    @MainActor
    public func callAsFunction(_ option: RunInterpolatorOption) { body(option) }
}
