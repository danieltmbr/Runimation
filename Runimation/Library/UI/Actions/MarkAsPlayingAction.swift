import Foundation

/// Marks a `RunRecord` as the most recently played entry,
/// updating `lastPlayedAt` for state restoration on next launch.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.markAsPlaying) private var markAsPlaying
/// markAsPlaying(record)
/// ```
///
struct MarkAsPlayingAction {

    private let body: @MainActor (RunRecord) -> Void

    init(_ body: @escaping @MainActor (RunRecord) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { library.markAsPlaying($0) }
    }

    @MainActor
    func callAsFunction(_ record: RunRecord) { body(record) }
}
