import Foundation
import RunKit

/// Builds and returns a `RuniDocument` for a given `RunItem`.
///
/// Loads track data and config from the library if not already present.
/// Safe to call for tracker runs that have never been played.
///
/// Inject via `.export(library:)` and access in views with:
/// ```swift
/// @Environment(\.exportRuni) private var exportRuni
/// let doc = try await exportRuni(item)
/// ```
///
struct ExportRuniAction {

    private let body: @MainActor (RunItem) async throws -> RuniDocument

    init(_ body: @escaping @MainActor (RunItem) async throws -> RuniDocument) {
        self.body = body
    }

    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { item in
            let loaded = try await library.load(item, with: [.run, .config])
            let points = try library.rawPoints(for: loaded.id)
            return RuniDocument.from(loaded, points: points)
        }
    }

    @MainActor
    func callAsFunction(_ item: RunItem) async throws -> RuniDocument {
        try await body(item)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No export action is available in the current environment." }
    }

    private struct ExportError: LocalizedError {
        var errorDescription: String? { "The run data could not be exported." }
    }
}
