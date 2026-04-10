import Foundation
import RunKit

/// Reads a `.runi` file from disk, decodes it, and inserts it into the run library.
///
/// Handles security-scoped resource access internally, so callers only need to
/// pass the URL as received from `onOpenURL` or a file picker.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.importDocument) private var importDocument
/// let item = try importDocument(url)
/// ```
///
struct ImportDocumentAction {

    private let body: @MainActor (URL) throws -> RunItem

    init(_ body: @escaping @MainActor (URL) throws -> RunItem) {
        self.body = body
    }

    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { url in
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(RuniDocument.self, from: data)

            let item = library.importTrack(
                name: document.name,
                date: document.date ?? Date(),
                points: document.points,
                source: .document
            )

            // Persist the config that was bundled in the document.
            let config = RunConfig(
                visualisationConfigData: try? JSONEncoder().encode(document.visualisation),
                transformersConfigData: try? JSONEncoder().encode(document.transformers),
                interpolatorConfigData: try? JSONEncoder().encode(document.interpolator),
                playDuration: document.duration
            )
            library.storeConfig(config, for: item)

            return item
        }
    }

    @MainActor
    func callAsFunction(_ url: URL) throws -> RunItem {
        try body(url)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No library is available in the current environment." }
    }
}
