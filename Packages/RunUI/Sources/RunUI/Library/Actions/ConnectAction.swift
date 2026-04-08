import AuthenticationServices
import RunKit

/// Connects a specific tracker by its `TrackerID`.
///
/// Resolves the tracker from the library, then calls `tracker.connect(from:)`,
/// forwarding the presentation anchor supplied by the caller — typically the
/// window that `ConnectToggle` is rendered in.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.connect) private var connect
/// connect(trackerID, from: anchor)
/// ```
///
public struct ConnectAction {

    private let body: @MainActor (TrackerID, ASPresentationAnchor?) -> Void

    public init(_ body: @escaping @MainActor (TrackerID, ASPresentationAnchor?) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { trackerID, anchor in
            guard let tracker = library.trackers.first(where: { $0.id == trackerID.id })
            else { return }
            Task { try? await library.connect(tracker, from: anchor) }
        }
    }

    @MainActor
    public func callAsFunction(_ trackerID: TrackerID, from anchor: ASPresentationAnchor?) {
        body(trackerID, anchor)
    }
}
