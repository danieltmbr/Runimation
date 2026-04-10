import Foundation

/// A value-type snapshot of a persisted run, safe to pass across
/// actor boundaries and use in `NavigationStack` paths.
///
/// Always-available fields (id, name, date, distance, duration, source)
/// are populated from the persistence layer. Optional detail fields
/// (`run`, `config`) are loaded on demand via `RunLibrary.load(_:with:)`.
///
/// Use `RunItem.Property` to declare which details you need:
/// ```swift
/// let loaded = try await library.load(item, with: [.run, .config])
/// loaded.run    // Run is now populated
/// loaded.config // RunConfig is now populated
/// ```
///
public struct RunItem: Hashable, Sendable, Identifiable, Codable {

    // MARK: - Always-available metadata

    public let id: RunID
    
    public let name: String
    
    public let date: Date
    
    public let distance: Double
    
    public let duration: TimeInterval
    
    public let source: RunOrigin

    // MARK: - Lazily loaded details

    /// Parsed run data. `nil` until loaded via `.load(_:with: [.run])`.
    public let run: Run?

    /// Persisted config blobs. `nil` until loaded via `.load(_:with: [.config])`.
    public let config: RunConfig?

    // MARK: - Properties

    /// Declares which optional detail fields to populate when loading.
    public enum Property: Hashable {
        case run
        case config
    }

    // MARK: - Init

    public init(
        id: RunID,
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: RunOrigin,
        run: Run? = nil,
        config: RunConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.source = source
        self.run = run
        self.config = config
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: RunItem, rhs: RunItem) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Codable

    /// Encodes only the stable identity fields — details are never serialised
    /// into navigation paths or documents.
    ///
    enum CodingKeys: String, CodingKey {
        case id, name, date, distance, duration, source
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(RunID.self,       forKey: .id)
        name     = try c.decode(String.self,      forKey: .name)
        date     = try c.decode(Date.self,        forKey: .date)
        distance = try c.decode(Double.self,      forKey: .distance)
        duration = try c.decode(TimeInterval.self, forKey: .duration)
        source   = try c.decode(RunOrigin.self,   forKey: .source)
        run      = nil
        config   = nil
    }

    // MARK: - Internal copy-and-update helpers

    func adding(run: Run) -> RunItem {
        RunItem(id: id, name: name, date: date, distance: distance,
                duration: duration, source: source, run: run, config: config)
    }

    func adding(config newConfig: RunConfig) -> RunItem {
        RunItem(id: id, name: name, date: date, distance: distance,
                duration: duration, source: source, run: run, config: newConfig)
    }
}
