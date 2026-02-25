import Foundation

/// Stops playback and resets progress to zero.
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.stop) private var stop
/// stop()
/// ```
///
struct StopAction {

    private let body: () -> Void

    init(_ body: @escaping () -> Void = {}) {
        self.body = body
    }

    init(player: RunPlayer) {
        self.init { player.stop() }
    }

    func callAsFunction() { body() }
}
