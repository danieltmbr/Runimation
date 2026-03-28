import Foundation

/// Looks up the `RunRecord` matching a given entry UUID.
///
/// Returns `nil` when no record exists for the given ID (e.g. before
/// any run has been loaded into the player).
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.findRecord) private var findRecord
/// let record = findRecord(someUUID)
/// ```
///
struct FindRecordAction {

    private let body: @MainActor (UUID) -> RunRecord?

    init(_ body: @escaping @MainActor (UUID) -> RunRecord? = { _ in nil }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { library.record(for: $0) }
    }

    @MainActor
    func callAsFunction(_ id: UUID) -> RunRecord? { body(id) }
}
