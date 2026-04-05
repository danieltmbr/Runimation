import Foundation
import RunKit

/// Fetches the `Run` for a given `RunEntry` from the library cache,
/// resolving the entry to a `RunRecord` internally.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.loadEntry) private var loadEntry
/// let run = try await loadEntry(entry)
/// ```
///
struct LoadEntryAction {

    private let body: @MainActor (RunEntry) async throws -> Run

    init(_ body: @escaping @MainActor (RunEntry) async throws -> Run) {
        self.body = body
    }

    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { entry in
            guard let record = library.record(for: entry) else { throw ResolutionError() }
            return try await library.loadRun(for: record)
        }
    }

    @MainActor
    func callAsFunction(_ entry: RunEntry) async throws -> Run {
        try await body(entry)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No run library is available in the current environment." }
    }

    private struct ResolutionError: LocalizedError {
        var errorDescription: String? { "The run could not be found in the library." }
    }
}
