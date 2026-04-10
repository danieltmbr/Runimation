import RunKit

/// Returns `true` if the run's track data is already stored locally,
/// meaning playback will not require a network call.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.hasLocalTrack) private var hasLocalTrack
/// let isCached = hasLocalTrack(item.id)
/// ```
///
public struct HasLocalTrackAction {

    private let body: (RunID) -> Bool

    public init(_ body: @escaping (RunID) -> Bool) {
        self.body = body
    }

    public init() {
        self.init { _ in false }
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { id in library.hasPersistedTrack(for: id) }
    }

    public func callAsFunction(_ id: RunID) -> Bool { body(id) }

    public func callAsFunction(_ item: RunItem) -> Bool { body(item.id) }
}
