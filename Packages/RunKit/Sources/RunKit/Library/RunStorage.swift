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
    func name(for id: UUID) -> String?

    /// Returns the raw track point data for the given run, if stored.
    ///
    func trackData(for id: UUID) -> Data?

    /// Returns the origin (provenance) of the given run, if it exists.
    ///
    func origin(for id: UUID) -> RunOrigin?

    /// Returns the ID of the most recently played run, if any.
    ///
    func lastPlayedID() -> UUID?

    // MARK: - Mutations

    /// Insert a new run record and return its assigned UUID.
    @discardableResult
    func insert(
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunOrigin,
        trackData: Data?
    ) -> UUID

    /// Persist fetched GPS track data for an existing record.
    ///
    func storeTrackData(_ data: Data, for id: UUID)

    /// Update the distance stored for a run (e.g. after parsing track data).
    ///
    func updateDistance(_ distance: Double, for id: UUID)

    /// Mark the given run as the most recently played.
    func markAsPlayed(id: UUID)

    /// Delete the run with the given ID.
    func delete(id: UUID)

    /// Returns all run IDs that originated from the given tracker.
    func ids(fromTracker trackerID: String) -> [UUID]
}
