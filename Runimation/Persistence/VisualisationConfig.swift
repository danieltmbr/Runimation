import Foundation
import Visualiser

/// Codable representation of the finite set of `Visualisation` conformers.
///
/// Using an enum with associated values avoids double JSON encoding:
/// the entire config is one `Codable` value that SwiftData serializes directly.
/// Unknown cases degrade gracefully to `nil` on decode.
///
enum VisualisationConfig: Codable {

    case warp(Warp)
    case runPath(RunPath)

    // MARK: - Init

    init(_ visualisation: any Visualisation) throws {
        switch visualisation {
        case let v as Warp:    self = .warp(v)
        case is RunPath:       self = .runPath(RunPath())
        default:
            throw EncodingError.invalidValue(
                visualisation,
                .init(codingPath: [], debugDescription: "Unknown Visualisation type: \(type(of: visualisation))")
            )
        }
    }

    // MARK: - Resolve

    func resolve() -> any Visualisation {
        switch self {
        case .warp(let v):    return v
        case .runPath:        return RunPath()
        }
    }
}
