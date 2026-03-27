import Foundation
import RunKit

/// Codable mapping for `RunPlayer.Duration`.
///
/// `Duration` contains a closure and cannot conform to `Codable` directly.
/// This enum maps the four known static presets by label.
/// Unknown values fall back to `.thirtySeconds`.
///
enum DurationConfig: Codable {

    case fifteenSeconds
    case thirtySeconds
    case oneMinute
    case realTime

    // MARK: - Init

    init(_ duration: RunPlayer.Duration) {
        switch duration.label {
        case RunPlayer.Duration.fifteenSeconds.label: self = .fifteenSeconds
        case RunPlayer.Duration.oneMinute.label:      self = .oneMinute
        case RunPlayer.Duration.realTime.label:       self = .realTime
        default:                                      self = .thirtySeconds
        }
    }

    // MARK: - Resolve

    func resolve() -> RunPlayer.Duration {
        switch self {
        case .fifteenSeconds: return .fifteenSeconds
        case .thirtySeconds:  return .thirtySeconds
        case .oneMinute:      return .oneMinute
        case .realTime:       return .realTime
        }
    }
}
