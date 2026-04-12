import CoreKit
import Foundation
import RunKit
import VisualiserUI

/// Imports a run file into the library and returns the resulting `RunItem`.
///
/// Use `@discardableResult` to fire-and-forget in list drop and file picker flows,
/// or capture the return value in `onOpenURL` to immediately play the imported run.
///
/// Use the static factories to build specific or composite importers:
/// ```swift
/// // All supported formats, routed by file extension:
/// ImportAction.allSupported(library: library)
///
/// // GPX only:
/// ImportAction.gpxImport(library: library)
///
/// // .runi document only:
/// ImportAction.runiImport(library: library)
/// ```
///
public struct ImportAction {

    private let body: @MainActor (URL) async throws -> RunItem

    public init(_ body: @escaping @MainActor (URL) async throws -> RunItem) {
        self.body = body
    }

    public init() {
        self.init { _ in throw UnboundError() }
    }

    // MARK: - Static Factories

    /// Parses a GPX file and imports all tracks into the library.
    /// Returns the first imported item.
    @MainActor
    public static func gpxImport(library: RunLibrary) -> ImportAction {
        let parser = GPX.Parser()
        return ImportAction { url in
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            guard let tracks = try? parser.parse(contentsOf: url) as [GPX.Track],
                  !tracks.isEmpty else { throw ImportError.noTracksFound }
            var firstItem: RunItem?
            for track in tracks {
                let item = library.importTrack(
                    name: track.name,
                    date: track.date ?? Date(),
                    points: track.points,
                    source: .file(url: url)
                )
                if firstItem == nil { firstItem = item }
            }
            guard let item = firstItem else { throw ImportError.noTracksFound }
            return item
        }
    }

    /// Reads a `.runi` document and imports it into the library, restoring its config.
    @MainActor
    public static func runiImport(library: RunLibrary) -> ImportAction {
        ImportAction { url in
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

    /// Routes to the appropriate importer based on the URL's file extension.
    @MainActor
    public static func allSupported(library: RunLibrary) -> ImportAction {
        let gpx = gpxImport(library: library)
        let runi = runiImport(library: library)
        return ImportAction { url in
            switch url.pathExtension.lowercased() {
            case "gpx":  return try await gpx(url)
            case "runi": return try await runi(url)
            default: throw ImportError.unsupportedFormat(url.pathExtension)
            }
        }
    }

    // MARK: - Call

    @discardableResult
    @MainActor
    public func callAsFunction(_ url: URL) async throws -> RunItem {
        try await body(url)
    }

    // MARK: - Errors

    public enum ImportError: LocalizedError {
        case noTracksFound
        case unsupportedFormat(String)

        public var errorDescription: String? {
            switch self {
            case .noTracksFound:
                return "No run tracks were found in the file."
            case .unsupportedFormat(let ext):
                return "Files with extension '.\(ext)' are not supported."
            }
        }
    }

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No import action is available in the current environment." }
    }
}
