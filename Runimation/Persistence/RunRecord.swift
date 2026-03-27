import Foundation
import SwiftData

/// Identifies the origin of a run's track data.
///
/// Stored as a Codable property on `RunRecord` so `RunLibrary` knows
/// how to re-fetch the track if `trackData` is not yet populated.
///
enum RunSource: Hashable, Codable, Sendable {
    /// A run fetched from the Strava API, identified by its activity ID.
    case strava(id: Int)
    /// A run imported from a local GPX file.
    case gpx(url: URL)
    /// The bundled sample run, identified by its resource name.
    case bundled(name: String)
}

/// A persistent record of a run in the library.
///
/// Stores display metadata (always populated), raw GPS track data
/// (serialized on first load), and per-run configuration blobs for the
/// visualisation and signal processing pipeline.
///
/// `RunLibrary` is the sole owner of `RunRecord` instances — views
/// consume them read-only via `@LibraryState(\.entries)`.
///
@Model
final class RunRecord {

    // MARK: - Identity

    /// Stable UUID used for in-memory caching and `RunEntry` navigation.
    ///
    @Attribute(.unique)
    var entryID: UUID

    // MARK: - Display Metadata

    var name: String
    
    var date: Date
    
    var distance: Double
    
    var duration: TimeInterval

    // MARK: - Source

    /// Origin of the track data — used to re-fetch if `trackData` is absent.
    ///
    var source: RunSource

    // MARK: - Timestamps

    var createdAt: Date
    
    var lastPlayedAt: Date?

    // MARK: - Track Data

    /// Serialized `[GPX.Point]` as JSON. Stored externally so the main table
    /// row stays small; populated on first load and persisted for offline use.
    ///
    @Attribute(.externalStorage)
    var trackData: Data?

    // MARK: - Per-Run Configuration

    /// Serialized `VisualisationConfig` — which visualisation is active and its settings.
    ///
    var visualisationData: Data?

    /// Serialized `[TransformerConfig]` — the signal processing transformer chain.
    ///
    var transformersData: Data?

    /// Serialized `InterpolatorConfig` — the interpolation strategy.
    ///
    var interpolatorData: Data?

    /// Serialized `DurationConfig` — the playback duration preset.
    /// 
    var durationData: Data?

    // MARK: - Init

    init(
        entryID: UUID = UUID(),
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunSource,
        createdAt: Date = Date(),
        lastPlayedAt: Date? = nil,
        trackData: Data? = nil,
        visualisationData: Data? = nil,
        transformersData: Data? = nil,
        interpolatorData: Data? = nil,
        durationData: Data? = nil
    ) {
        self.entryID = entryID
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.source = source
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.trackData = trackData
        self.visualisationData = visualisationData
        self.transformersData = transformersData
        self.interpolatorData = interpolatorData
        self.durationData = durationData
    }
}
