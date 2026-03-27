import Foundation
import Visualiser

/// Codable wrapper for the finite set of `Visualisation` conformers.
///
/// Stores a kind discriminator and the JSON-encoded concrete type. Unknown kinds
/// return `nil` on decode so future visualisation types degrade gracefully to the
/// app default rather than crashing.
///
struct VisualisationConfig: Codable {

    enum Kind: String, Codable {
        case warp
        case runPath
    }

    let kind: Kind
    
    let payload: Data

    // MARK: - Init

    init(_ visualisation: any Visualisation) throws {
        let encoder = JSONEncoder()
        switch visualisation {
        case let v as Warp:
            kind = .warp
            payload = try encoder.encode(v)
        case is RunPath:
            kind = .runPath
            payload = try encoder.encode(RunPath())
        default:
            throw EncodingError.invalidValue(
                visualisation,
                .init(codingPath: [], debugDescription: "Unknown Visualisation type: \(type(of: visualisation))")
            )
        }
    }

    // MARK: - Resolve

    func resolve() -> (any Visualisation)? {
        let decoder = JSONDecoder()
        switch kind {
        case .warp:    return try? decoder.decode(Warp.self, from: payload)
        case .runPath: return RunPath()
        }
    }

    // MARK: - Helpers

    static func encode(_ visualisation: any Visualisation) throws -> Data {
        try JSONEncoder().encode(try VisualisationConfig(visualisation))
    }

    static func decode(from data: Data) -> (any Visualisation)? {
        (try? JSONDecoder().decode(VisualisationConfig.self, from: data))?.resolve()
    }
}
