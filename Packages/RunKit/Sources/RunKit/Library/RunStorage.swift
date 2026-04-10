import Foundation

/// Write interface for the run persistence layer.
///
/// `RunLibrary` uses this protocol for all mutations — insert, update,
/// delete, and metadata writes. Read access for list display is handled
/// separately by the app layer via `@Query` on the underlying model, so
/// views update automatically without any manual array management.
///
/// The concrete implementation (`SwiftDataRunStorage`) lives in the app
/// target alongside `RunRecord`, keeping the SwiftData dependency out of
/// the package layer.
///
@MainActor
public protocol RunStorage: AnyObject {

    // MARK: - Queries

    /// Returns true if a run from the given tracker activity already exists.
    ///
    func exists(source: ActivitySource) -> Bool

    /// Returns the display name of the given run, if it exists.
    ///
    func name(for id: RunID) -> String?

    /// Returns the raw track point data for the given run, if stored.
    ///
    func trackData(for id: RunID) -> Data?

    /// Returns the origin (provenance) of the given run, if it exists.
    ///
    func origin(for id: RunID) -> RunOrigin?

    /// Returns the persisted config blobs for the given run, if it exists.
    ///
    func config(for id: RunID) -> RunConfig?

    /// Returns the ID of the most recently played run, if any.
    ///
    func lastPlayedID() -> RunID?

    // MARK: - Mutations

    /// Insert a new run record and return its assigned ID.
    @discardableResult
    func insert(
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunOrigin,
        trackData: Data?
    ) -> RunID

    /// Persist fetched GPS track data for an existing record.
    ///
    func storeTrackData(_ data: Data, for id: RunID)

    /// Update the distance stored for a run (e.g. after parsing track data).
    ///
    func updateDistance(_ distance: Double, for id: RunID)

    /// Persist config blobs for an existing record (e.g. after importing a `.runi` document).
    ///
    func storeConfig(_ config: RunConfig, for id: RunID)

    /// Mark the given run as the most recently played.
    func markAsPlayed(id: RunID)

    /// Delete the run with the given ID.
    func delete(id: RunID)

    /// Returns all run IDs that originated from the given tracker.
    func ids(fromTracker trackerID: String) -> [RunID]
}
