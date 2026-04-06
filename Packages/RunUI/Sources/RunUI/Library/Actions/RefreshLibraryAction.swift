import RunKit

/// Resets pagination on all connected trackers and re-fetches from the first page.
///
/// Locally imported entries are preserved. No-op if no trackers are connected.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.refreshLibrary) private var refreshLibrary
/// refreshLibrary()
/// ```
///
public struct RefreshLibraryAction {

    private let body: @MainActor () -> Void

    public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { Task { await library.refresh() } }
    }

    @MainActor
    public func callAsFunction() { body() }
}
