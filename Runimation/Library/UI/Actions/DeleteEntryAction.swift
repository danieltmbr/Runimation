import Foundation

/// Removes a `LibraryEntry` from the library.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.deleteEntry) private var deleteEntry
/// deleteEntry(entry)
/// ```
///
struct DeleteEntryAction {

    private let body: @MainActor (LibraryEntry) -> Void

    init(_ body: @escaping @MainActor (LibraryEntry) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { entry in library.delete(entry) }
    }

    @MainActor
    func callAsFunction(_ entry: LibraryEntry) { body(entry) }
}
