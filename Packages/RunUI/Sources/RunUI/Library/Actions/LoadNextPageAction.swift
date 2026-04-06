import RunKit

/// Fetches the next page of remote entries and appends them to the library.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.loadNextPage) private var loadNextPage
/// loadNextPage()
/// ```
///
public struct LoadNextPageAction {

    private let body: @MainActor () -> Void

    public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { Task { await library.fetchNextPage() } }
    }

    @MainActor
    public func callAsFunction() { body() }
}
