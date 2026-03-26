import Foundation

/// Fetches the next page of remote entries and appends them to the library.
///
/// No-op if already loading, at end of list, or not authenticated.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.loadNextPage) private var loadNextPage
/// loadNextPage()
/// ```
///
struct LoadNextPageAction {

    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { Task { await library.loadNextPage() } }
    }

    @MainActor
    func callAsFunction() { body() }
}
