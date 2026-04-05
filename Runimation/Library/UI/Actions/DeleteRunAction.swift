import Foundation

/// Removes a `RunRecord` from the library.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.deleteRun) private var deleteRun
/// deleteRun(record)
/// ```
///
struct DeleteRunAction {

    private let body: @MainActor (RunEntry) -> Void

    init(_ body: @escaping @MainActor (RunEntry) -> Void) {
        self.body = body
    }

    init() {
        self.init { _ in }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { entry in library.delete(entry) }
    }
    
    @MainActor
    func callAsFunction(_ record: RunRecord) {
        body(record.entry)
    }
    
    @MainActor
    func callAsFunction(_ entry: RunEntry) {
        body(entry)
    }
}
