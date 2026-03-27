import Foundation
import RunKit

/// Codable mapping for `RunPlayer.Duration`.
///
/// `Duration` contains a closure and cannot conform to `Codable` directly.
/// This wrapper maps the four known static presets by their stable label string.
/// Unknown labels fall back to `.thirtySeconds`.
///
struct DurationConfig: Codable {

    enum Kind: String, Codable {
        case fifteenSeconds
        case thirtySeconds
        case oneMinute
        case realTime
    }

    let kind: Kind

    // MARK: - Init

    init(_ duration: RunPlayer.Duration) {
        switch duration.label {
        case RunPlayer.Duration.fifteenSeconds.label: kind = .fifteenSeconds
        case RunPlayer.Duration.oneMinute.label:      kind = .oneMinute
        case RunPlayer.Duration.realTime.label:       kind = .realTime
        default:                                      kind = .thirtySeconds
        }
    }

    // MARK: - Resolve

    func resolve() -> RunPlayer.Duration {
        switch kind {
        case .fifteenSeconds: return .fifteenSeconds
        case .thirtySeconds:  return .thirtySeconds
        case .oneMinute:      return .oneMinute
        case .realTime:       return .realTime
        }
    }

    // MARK: - Helpers

    static func encode(_ duration: RunPlayer.Duration) throws -> Data {
        try JSONEncoder().encode(DurationConfig(duration))
    }

    static func decode(from data: Data) -> RunPlayer.Duration? {
        (try? JSONDecoder().decode(DurationConfig.self, from: data))?.resolve()
    }
}
