import Foundation
import RunKit
import SwiftData

/// Builds and returns a `RuniDocument` for a given `RunEntry`.
///
/// Resolves the entry to its persisted `RunRecord` and loads track data
/// from the original source if it hasn't been fetched yet. Safe to call
/// for tracker runs that have never been played.
///
/// Inject via `.export(library:modelContext:)` and access in views with:
/// ```swift
/// @Environment(\.exportRuni) private var exportRuni
/// let doc = try await exportRuni(entry)
/// ```
///
struct ExportRuniAction {

    private let body: @MainActor (RunEntry) async throws -> RuniDocument

    init(_ body: @escaping @MainActor (RunEntry) async throws -> RuniDocument) {
        self.body = body
    }

    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary, modelContext: ModelContext) {
        self.init { entry in
            _ = try await library.loadRun(for: entry)
            guard let record = try? modelContext.fetch(FetchDescriptor.record(for: entry)).first
            else { throw ResolutionError() }
            guard let doc = RuniDocument.from(record) else { throw ExportError() }
            return doc
        }
    }

    @MainActor
    func callAsFunction(_ entry: RunEntry) async throws -> RuniDocument {
        try await body(entry)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No export action is available in the current environment." }
    }

    private struct ResolutionError: LocalizedError {
        var errorDescription: String? { "The run could not be found in the library." }
    }

    private struct ExportError: LocalizedError {
        var errorDescription: String? { "The run data could not be exported." }
    }
}
