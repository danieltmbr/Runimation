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

    private let body: @MainActor (RunRecord) -> Void

    init(_ body: @escaping @MainActor (RunRecord) -> Void) {
        self.body = body
    }

    init() {
        self.init { _ in }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { record in library.delete(record) }
    }

    @MainActor
    func callAsFunction(_ record: RunRecord) {
        body(record)
    }
}
