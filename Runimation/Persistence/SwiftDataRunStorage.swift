import Foundation
import RunKit
import SwiftData

/// A `RunStorage` implementation backed by SwiftData.
///
/// Wraps a `ModelContext` and stores/retrieves runs using `RunRecord`.
/// All operations are synchronous SwiftData calls; the `ModelContext` is
/// expected to belong to the main actor.
///
@MainActor
final class SwiftDataRunStorage: RunStorage {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Queries

    func exists(source: ActivitySource) -> Bool {
        let origin = RunOrigin.tracker(source)
        let all = (try? context.fetch(FetchDescriptor<RunRecord>())) ?? []
        return all.contains { $0.source == origin }
    }

    func name(for id: UUID) -> String? {
        record(for: id)?.name
    }

    func trackData(for id: UUID) -> Data? {
        record(for: id)?.trackData
    }

    func origin(for id: UUID) -> RunOrigin? {
        record(for: id)?.source
    }

    func lastPlayedID() -> UUID? {
        var descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate<RunRecord> { $0.lastPlayedAt != nil },
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.entry.id
    }

    // MARK: - Mutations

    @discardableResult
    func insert(
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunOrigin,
        trackData: Data?
    ) -> UUID {
        let record = RunRecord(
            name: name,
            date: date,
            distance: distance,
            duration: duration,
            source: source,
            trackData: trackData
        )
        context.insert(record)
        try? context.save()
        return record.entry.id
    }

    func storeTrackData(_ data: Data, for id: UUID) {
        guard let record = record(for: id) else { return }
        record.trackData = data
        try? context.save()
    }

    func updateDistance(_ distance: Double, for id: UUID) {
        guard let record = record(for: id) else { return }
        record.distance = distance
        try? context.save()
    }

    func markAsPlayed(id: UUID) {
        guard let record = record(for: id) else { return }
        record.lastPlayedAt = Date()
        try? context.save()
    }

    func delete(id: UUID) {
        guard let record = record(for: id) else { return }
        context.delete(record)
        try? context.save()
    }

    func ids(fromTracker trackerID: String) -> [UUID] {
        let all = (try? context.fetch(FetchDescriptor<RunRecord>())) ?? []
        return all.compactMap { record in
            guard case .tracker(let source) = record.source,
                  source.tracker == trackerID
            else { return nil }
            return record.entry.id
        }
    }

    // MARK: - Private

    private func record(for id: UUID) -> RunRecord? {
        let entry = RunEntry(id: id)
        return try? context.fetch(FetchDescriptor.record(for: entry)).first
    }
}
