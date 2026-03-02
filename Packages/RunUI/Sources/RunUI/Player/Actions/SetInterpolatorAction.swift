import Foundation
import RunKit

/// Swaps the active run interpolator, recomputing all run variants
/// without stopping the current playback.
///
public struct SetInterpolatorAction {

    private let body: @MainActor (any RunInterpolator) -> Void

    init(_ body: @escaping @MainActor (any RunInterpolator) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.interpolator = $0 }
    }

    @MainActor
    public func callAsFunction(_ interpolator: any RunInterpolator) { body(interpolator) }
}
