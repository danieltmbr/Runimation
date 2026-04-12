import Foundation

/// Codable representation of the finite set of `RunInterpolator` conformers.
///
/// All current interpolators are stateless, so only the case discriminator
/// is needed. Unknown cases fall back to `.linear` on decode.
///
/// `Codable` is implemented explicitly as `nonisolated` to prevent Swift 6
/// from treating the conformance as `@MainActor`-isolated.
///
public enum InterpolatorConfig: Sendable {

    case linear
    case smoothStep
    case catmullRom

    // MARK: - Init

    public init(_ interpolator: any RunInterpolator) {
        switch interpolator {
        case is LinearRunInterpolator:     self = .linear
        case is SmoothStepRunInterpolator: self = .smoothStep
        case is CatmullRomRunInterpolator: self = .catmullRom
        default:                           self = .linear
        }
    }

    // MARK: - Resolve

    public func resolve() -> any RunInterpolator {
        switch self {
        case .linear:     return LinearRunInterpolator()
        case .smoothStep: return SmoothStepRunInterpolator()
        case .catmullRom: return CatmullRomRunInterpolator()
        }
    }
}

// MARK: - Codable

extension InterpolatorConfig: Codable {

    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "smoothStep": self = .smoothStep
        case "catmullRom": self = .catmullRom
        default:           self = .linear
        }
    }

    public nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .linear:     try container.encode("linear")
        case .smoothStep: try container.encode("smoothStep")
        case .catmullRom: try container.encode("catmullRom")
        }
    }
}
