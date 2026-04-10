import Foundation
import RunKit
import SwiftData

/// A persistent record of a run in the library.
///
/// Stores display metadata (always populated), raw GPS track data
/// (serialized on first load), and per-run configuration for the
/// visualisation and signal processing pipeline.
///
@Model
final class RunRecord {

    // MARK: - Identity

    /// Raw UUID stored for database-level uniqueness enforcement.
    /// Exposed only as `RunID` via `item.id` — never use this field directly.
    ///
    @Attribute(.unique)
    fileprivate var itemUUID: UUID

    /// The type-safe run identifier derived from the stored UUID.
    var itemID: RunID { RunID(itemUUID) }

    /// A sendable snapshot of this record's metadata.
    /// Optional detail fields (`run`, `config`) are not populated here;
    /// use `RunLibrary.load(_:with:)` for those.
    ///
    var item: RunItem {
        RunItem(
            id: itemID,
            name: name,
            date: date,
            distance: distance,
            duration: duration,
            source: source
        )
    }

    /// Opaque config blobs bundled as a `RunConfig` value.
    ///
    var config: RunConfig {
        RunConfig(
            visualisationConfigData: visualisationConfigData,
            transformersConfigData: transformersConfigData,
            interpolatorConfigData: interpolatorConfigData,
            playDuration: playDuration
        )
    }

    // MARK: - Display Metadata

    var name: String

    var date: Date

    var distance: Double

    var duration: TimeInterval

    // MARK: - Source

    /// Origin of the track data — used to re-fetch if `trackData` is absent.
    ///
    var source: RunOrigin

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
    //
    // Stored as raw JSON `Data` rather than composite SwiftData attributes
    // because the config types are enums with associated values, which
    // SwiftData cannot decode as composite attributes. Manual JSON coding
    // also means schema changes degrade gracefully (bad data → nil).

    var visualisationConfigData: Data?
    var transformersConfigData: Data?
    var interpolatorConfigData: Data?
    var playDuration: TimeInterval?

    // MARK: - Init

    init(
        itemUUID: UUID = UUID(),
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunOrigin,
        createdAt: Date = Date(),
        lastPlayedAt: Date? = nil,
        trackData: Data? = nil
    ) {
        self.itemUUID = itemUUID
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.source = source
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.trackData = trackData
    }

    // MARK: - Sentinel

    /// An in-memory sentinel representing the idle state (no run selected).
    ///
    /// Never inserted into a `ModelContext`. Its `itemUUID` matches `Run.sedentaryID`
    /// so that `NowPlaying` returns this record when the player holds a sedentary run.
    ///
    static let sedentary: RunRecord = {
        let record = RunRecord(
            name: "",
            date: .distantPast,
            distance: 0,
            duration: 0,
            source: .bundled(name: "sedentary")
        )
        record.itemUUID = Run.sedentaryID.value
        return record
    }()

    // MARK: - Helpers

    /// True when this record is the sedentary sentinel (no real run selected).
    ///
    var isSedentary: Bool { itemUUID == Run.sedentaryID.value }

    /// True when this record has a saved visualisation config.
    ///
    var hasConfig: Bool { visualisationConfigData != nil }
}

extension FetchDescriptor<RunRecord> {

    static func record(for run: RunItem) -> FetchDescriptor<RunRecord> {
        record(forID: run.id)
    }

    static func record(forID id: RunID) -> FetchDescriptor<RunRecord> {
        let uuid = id.value
        return FetchDescriptor<RunRecord>(
            predicate: #Predicate<RunRecord> { $0.itemUUID == uuid }
        )
    }
}

