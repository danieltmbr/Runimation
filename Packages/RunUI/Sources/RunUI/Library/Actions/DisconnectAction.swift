import RunKit

/// Disconnects a specific tracker by its `TrackerID`, optionally removing its stored runs.
///
/// Resolves the tracker from the library, then calls `library.disconnect(_:keepRuns:)`.
/// The `keepRuns` parameter is supplied by the caller — typically a confirmation
/// dialog inside `ConnectToggle`.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.disconnect) private var disconnect
/// disconnect(trackerID, keepRuns: true)
/// ```
///
public struct DisconnectAction {

    private let body: @MainActor (TrackerID, Bool) -> Void

    public init(_ body: @escaping @MainActor (TrackerID, Bool) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { trackerID, keepRuns in
            guard let tracker = library.trackers.first(where: { $0.id == trackerID.id })
            else { return }
            library.disconnect(tracker, keepRuns: keepRuns)
        }
    }

    @MainActor
    public func callAsFunction(_ trackerID: TrackerID, keepRuns: Bool) { body(trackerID, keepRuns) }
}
