import Foundation

/// Builds a `RuniDocument` from the given `RunRecord`.
///
/// The action is synchronous — it reads already-persisted config data directly
/// from the record's stored properties. Returns `nil` when the record's track
/// data hasn't been loaded yet (the run has never been played).
///
/// Inject via `.export(player:)` and access in views with:
/// ```swift
/// @Environment(\.exportRuni) private var exportRuni
/// if let doc = exportRuni(record) { ... }
/// ```
///
struct ExportRuniAction {

    private let body: @MainActor (RunRecord) -> RuniDocument?

    init(_ body: @escaping @MainActor (RunRecord) -> RuniDocument?) {
        self.body = body
    }

    init() {
        self.init { RuniDocument.from($0) }
    }

    @MainActor
    func callAsFunction(_ record: RunRecord) -> RuniDocument? {
        body(record)
    }
}
