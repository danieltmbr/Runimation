import Foundation
import RunKit

/// Seeks the player to a normalised progress position in [0, 1].
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.seek) private var seek
/// seek(to: 0.5)
/// ```
///
public struct SeekAction {

    private let body: @MainActor (Double) -> Void

    init(_ body: @escaping @MainActor (Double) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { player.seek(to: $0) }
    }

    @MainActor
    public func callAsFunction(to progress: Double) { body(progress) }
}
