import Foundation
import Visualiser

/// Codable representation of the finite set of `Visualisation` conformers.
///
/// Encodes as a single-key dictionary — `{"warp": {...}}` or `{"runPath": {...}}` —
/// so the case discriminator and associated value are stored together.
/// Unknown cases degrade gracefully to `nil` on decode.
///
/// `Codable` is implemented explicitly as `nonisolated` to prevent Swift 6
/// from treating the conformance as `@MainActor`-isolated.
///
enum VisualisationConfig {

    case warp(Warp)
    case runPath(RunPath)

    // MARK: - Init

    init(_ visualisation: any Visualisation) throws {
        switch visualisation {
        case let v as Warp: self = .warp(v)
        case is RunPath:    self = .runPath(RunPath())
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
        case .warp(let v): return v
        case .runPath:     return RunPath()
        }
    }
}

// MARK: - Codable

extension VisualisationConfig: Codable {

    private enum CodingKeys: String, CodingKey {
        case warp, runPath
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.warp) {
            self = .warp(try container.decode(Warp.self, forKey: .warp))
        } else if container.contains(.runPath) {
            self = .runPath(try container.decode(RunPath.self, forKey: .runPath))
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown VisualisationConfig case")
            )
        }
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .warp(let v):    try container.encode(v, forKey: .warp)
        case .runPath(let v): try container.encode(v, forKey: .runPath)
        }
    }
}
