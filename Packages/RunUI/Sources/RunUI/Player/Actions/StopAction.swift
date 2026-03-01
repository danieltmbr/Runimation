import Foundation
import RunKit

/// Stops playback and resets progress to zero.
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.stop) private var stop
/// stop()
/// ```
///
public struct StopAction {

    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.stop() }
    }

    @MainActor
    public func callAsFunction() { body() }
}
