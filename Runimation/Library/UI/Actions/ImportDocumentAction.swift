import Foundation
import RunKit
import SwiftData

/// Reads a `.runi` file from disk, decodes it, and inserts it into the run library.
///
/// Handles security-scoped resource access internally, so callers only need to
/// pass the URL as received from `onOpenURL` or a file picker.
///
/// Inject via `.library(_:modelContext:)` and access in views with:
/// ```swift
/// @Environment(\.importDocument) private var importDocument
/// let record = try importDocument(url)
/// ```
///
struct ImportDocumentAction {

    private let body: @MainActor (URL) throws -> RunRecord

    init(_ body: @escaping @MainActor (URL) throws -> RunRecord) {
        self.body = body
    }

    init() {
        self.init { _ in .sedentary }
    }

    @MainActor
    init(library: RunLibrary, modelContext: ModelContext) {
        self.init { url in
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(RuniDocument.self, from: data)

            let entry = library.importTrack(
                name: document.name,
                date: document.date ?? Date(),
                points: document.points,
                source: .document
            )

            // Look up the freshly inserted RunRecord to persist per-run config.
            guard let record = try? modelContext.fetch(FetchDescriptor.record(for: entry)).first
            else { return .sedentary }

            record.visualisationConfigData = (try? JSONEncoder().encode(document.visualisation))
            record.transformersConfigData = (try? JSONEncoder().encode(document.transformers))
            record.interpolatorConfigData = (try? JSONEncoder().encode(document.interpolator))
            record.playDuration = document.duration
            try? modelContext.save()

            return record
        }
    }

    @MainActor
    func callAsFunction(_ url: URL) throws -> RunRecord {
        try body(url)
    }
}
