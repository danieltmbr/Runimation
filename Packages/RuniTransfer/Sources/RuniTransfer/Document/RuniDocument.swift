import CoreTransferable
import CoreKit
import Foundation
import RunKit
import UniformTypeIdentifiers
import VisualiserUI

/// A portable, shareable snapshot of a run and its complete visualisation config.
///
/// Encodes everything needed to reconstruct a Runimation visualisation — GPS track
/// points, signal-processing pipeline config, and playback duration — into a few kB
/// of JSON. Shared via `ShareLink` using the `.runi` content type; recipients open
/// the file in Runimation to replay the animation on-device without any download.
///
public struct RuniDocument: Codable, Sendable, Transferable {

    // MARK: - Track Metadata

    public let name: String

    public let date: Date?

    // MARK: - GPS Data

    /// Raw GPS track points — the source data for the animation pipeline.
    public let points: [GPX.Point]

    // MARK: - Config

    public let visualisation: VisualisationConfig

    public let transformers: [TransformerConfig]

    public let interpolator: InterpolatorConfig

    public let duration: TimeInterval

    // MARK: - Init

    public init(
        name: String,
        date: Date?,
        points: [GPX.Point],
        visualisation: VisualisationConfig,
        transformers: [TransformerConfig],
        interpolator: InterpolatorConfig,
        duration: TimeInterval
    ) {
        self.name = name
        self.date = date
        self.points = points
        self.visualisation = visualisation
        self.transformers = transformers
        self.interpolator = interpolator
        self.duration = duration
    }

    // MARK: - Factory

    /// Builds a `RuniDocument` from a loaded `RunItem` and its raw GPS points.
    ///
    /// Raw points must be fetched via `RunLibrary.rawPoints(for:)` after calling
    /// `library.load(item, with: [.run, .config])`.
    /// All config fields fall back to defaults when no saved config exists.
    ///
    public static func from(_ item: RunItem, points: [GPX.Point]) -> RuniDocument {
        let visualisation: VisualisationConfig = item.config?.visualisationConfigData
            .flatMap { try? JSONDecoder().decode(VisualisationConfig.self, from: $0) }
            ?? .warp(Warp())

        let transformers: [TransformerConfig] = item.config?.transformersConfigData
            .flatMap { try? JSONDecoder().decode([TransformerConfig].self, from: $0) }
            ?? []

        let interpolator: InterpolatorConfig = item.config?.interpolatorConfigData
            .flatMap { try? JSONDecoder().decode(InterpolatorConfig.self, from: $0) }
            ?? .linear

        return RuniDocument(
            name: item.name,
            date: item.date,
            points: points,
            visualisation: visualisation,
            transformers: transformers,
            interpolator: interpolator,
            duration: item.config?.playDuration ?? 30
        )
    }

    // MARK: - Transferable

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .runi) { doc in
            let safeName = doc.name
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "/", with: "-")
            let filename = safeName.isEmpty ? "Run" : safeName
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(filename).runi")
            try JSONEncoder().encode(doc).write(to: url)
            return SentTransferredFile(url)
        }
    }
}
