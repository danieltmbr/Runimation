import Foundation
import RunKit

/// Codable representation of the finite set of `RunInterpolator` conformers.
///
/// All current interpolators are stateless, so only the case discriminator
/// is needed. Unknown cases fall back to `.linear` on decode.
///
enum InterpolatorConfig: Codable {

    case linear
    case smoothStep
    case catmullRom

    // MARK: - Init

    init(_ interpolator: any RunInterpolator) {
        switch interpolator {
        case is LinearRunInterpolator:      self = .linear
        case is SmoothStepRunInterpolator:  self = .smoothStep
        case is CatmullRomRunInterpolator:  self = .catmullRom
        default:                            self = .linear
        }
    }

    // MARK: - Resolve

    func resolve() -> any RunInterpolator {
        switch self {
        case .linear:      return LinearRunInterpolator()
        case .smoothStep:  return SmoothStepRunInterpolator()
        case .catmullRom:  return CatmullRomRunInterpolator()
        }
    }
}
