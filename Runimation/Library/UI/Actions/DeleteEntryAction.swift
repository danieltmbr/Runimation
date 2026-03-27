import Foundation

/// Removes the run identified by a `RunEntry` from the library.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.deleteEntry) private var deleteEntry
/// deleteEntry(entry)
/// ```
///
struct DeleteEntryAction {

    private let body: @MainActor (RunEntry) -> Void

    init(_ body: @escaping @MainActor (RunEntry) -> Void) {
        self.body = body
    }

    init() {
        self.init { _ in }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { entry in
            guard let record = library.record(for: entry.id) else { return }
            library.delete(record)
        }
    }

    @MainActor
    func callAsFunction(_ entry: RunEntry) {
        body(entry)
    }
}
