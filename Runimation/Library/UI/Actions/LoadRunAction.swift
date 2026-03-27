import Foundation
import RunKit

/// Fetches the `Run` for a given `RunRecord` from the library cache,
/// loading from the source's origin on first access.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.loadRun) private var loadRun
/// let run = try await loadRun(record)
/// ```
///
struct LoadRunAction {

    private let body: @MainActor (RunRecord) async throws -> Run

    init(_ body: @escaping @MainActor (RunRecord) async throws -> Run) {
        self.body = body
    }

    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { record in try await library.loadRun(for: record) }
    }

    @MainActor
    func callAsFunction(_ record: RunRecord) async throws -> Run {
        try await body(record)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No run library is available in the current environment." }
    }
}
