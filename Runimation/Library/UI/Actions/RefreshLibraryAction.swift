import Foundation

/// Clears remote entries and re-fetches from the first page.
///
/// Locally imported entries are preserved. No-op if not authenticated.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.refreshLibrary) private var refreshLibrary
/// refreshLibrary()
/// ```
///
struct RefreshLibraryAction {

    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { Task { await library.refresh() } }
    }

    @MainActor
    func callAsFunction() { body() }
}
