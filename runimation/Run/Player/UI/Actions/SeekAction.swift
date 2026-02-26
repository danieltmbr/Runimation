import Foundation

/// Seeks the player to a normalised progress position in [0, 1].
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.seek) private var seek
/// seek(to: 0.5)
/// ```
///
struct SeekAction {

    private let body: (Double) -> Void

    init(_ body: @escaping (Double) -> Void = { _ in }) {
        self.body = body
    }

    init(player: RunPlayer) {
        self.init { player.seek(to: $0) }
    }

    func callAsFunction(to progress: Double) { body(progress) }
}
