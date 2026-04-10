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

    func name(for id: RunID) -> String? {
        record(for: id)?.name
    }

    func trackData(for id: RunID) -> Data? {
        record(for: id)?.trackData
    }

    func origin(for id: RunID) -> RunOrigin? {
        record(for: id)?.source
    }

    func config(for id: RunID) -> RunConfig? {
        record(for: id)?.config
    }

    func lastPlayedID() -> RunID? {
        var descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate<RunRecord> { $0.lastPlayedAt != nil },
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.itemID
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
    ) -> RunID {
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
        return record.item.id
    }

    func storeTrackData(_ data: Data, for id: RunID) {
        guard let record = record(for: id) else { return }
        record.trackData = data
        try? context.save()
    }

    func updateDistance(_ distance: Double, for id: RunID) {
        guard let record = record(for: id) else { return }
        record.distance = distance
        try? context.save()
    }

    func storeConfig(_ config: RunConfig, for id: RunID) {
        guard let record = record(for: id) else { return }
        record.visualisationConfigData = config.visualisationConfigData
        record.transformersConfigData = config.transformersConfigData
        record.interpolatorConfigData = config.interpolatorConfigData
        record.playDuration = config.playDuration
        try? context.save()
    }

    func markAsPlayed(id: RunID) {
        guard let record = record(for: id) else { return }
        record.lastPlayedAt = Date()
        try? context.save()
    }

    func delete(id: RunID) {
        guard let record = record(for: id) else { return }
        context.delete(record)
        try? context.save()
    }

    func ids(fromTracker trackerID: String) -> [RunID] {
        let all = (try? context.fetch(FetchDescriptor<RunRecord>())) ?? []
        return all.compactMap { record in
            guard case .tracker(let source) = record.source,
                  source.tracker == trackerID
            else { return nil }
            return record.item.id
        }
    }

    // MARK: - Private

    private func record(for id: RunID) -> RunRecord? {
        try? context.fetch(FetchDescriptor.record(forID: id)).first
    }
}
