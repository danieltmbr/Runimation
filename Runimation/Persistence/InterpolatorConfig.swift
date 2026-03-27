import Foundation
import RunKit

/// Codable wrapper for the finite set of `RunInterpolator` conformers.
///
/// All current interpolators are stateless, so only the kind discriminator is stored.
/// Unknown kinds fall back to `.linear` on decode.
///
struct InterpolatorConfig: Codable {

    enum Kind: String, Codable {
        case linear
        case smoothStep
        case catmullRom
    }

    let kind: Kind

    // MARK: - Init

    init(_ interpolator: any RunInterpolator) {
        switch interpolator {
        case is LinearRunInterpolator:      kind = .linear
        case is SmoothStepRunInterpolator:  kind = .smoothStep
        case is CatmullRomRunInterpolator:  kind = .catmullRom
        default:                            kind = .linear
        }
    }

    // MARK: - Resolve

    func resolve() -> any RunInterpolator {
        switch kind {
        case .linear:      return LinearRunInterpolator()
        case .smoothStep:  return SmoothStepRunInterpolator()
        case .catmullRom:  return CatmullRomRunInterpolator()
        }
    }

    // MARK: - Helpers

    static func encode(_ interpolator: any RunInterpolator) throws -> Data {
        try JSONEncoder().encode(InterpolatorConfig(interpolator))
    }

    static func decode(from data: Data) -> (any RunInterpolator)? {
        (try? JSONDecoder().decode(InterpolatorConfig.self, from: data))?.resolve()
    }
}
