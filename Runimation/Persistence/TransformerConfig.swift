import Foundation
import RunKit

/// Codable wrapper that encodes/decodes a heterogeneous `[any RunTransformer]` array
/// using a type discriminator string.
///
/// Each known concrete transformer maps to a `Kind` case. Unknown kinds are silently
/// dropped on decode, so adding new transformer types in future versions won't crash
/// when reading older persisted data.
///
/// `NormalisedRun` is intentionally excluded — it is always applied internally by
/// `RunPlayer` and is never user-configurable.
///
struct TransformerConfig: Codable {

    enum Kind: String, Codable {
        case gaussian
        case speedWeighted
        case waveSampling
    }

    let kind: Kind
    let payload: Data

    // MARK: - Init

    init(_ transformer: any RunTransformer) throws {
        let encoder = JSONEncoder()
        switch transformer {
        case let t as GuassianRun:
            kind = .gaussian
            payload = try encoder.encode(t)
        case let t as SpeedWeightedRun:
            kind = .speedWeighted
            payload = try encoder.encode(t)
        case let t as WaveSamplingTransformer:
            kind = .waveSampling
            payload = try encoder.encode(t)
        default:
            throw EncodingError.invalidValue(
                transformer,
                .init(codingPath: [], debugDescription: "Unknown RunTransformer type: \(type(of: transformer))")
            )
        }
    }

    // MARK: - Resolve

    func resolve() throws -> any RunTransformer {
        let decoder = JSONDecoder()
        switch kind {
        case .gaussian:     return try decoder.decode(GuassianRun.self, from: payload)
        case .speedWeighted: return try decoder.decode(SpeedWeightedRun.self, from: payload)
        case .waveSampling: return try decoder.decode(WaveSamplingTransformer.self, from: payload)
        }
    }

    // MARK: - Array Helpers

    /// Encodes an array of transformers to JSON data.
    static func encode(_ transformers: [any RunTransformer]) throws -> Data {
        let configs = try transformers.map { try TransformerConfig($0) }
        return try JSONEncoder().encode(configs)
    }

    /// Decodes an array of transformers from JSON data. Unknown kinds are silently skipped.
    static func decode(from data: Data) -> [any RunTransformer] {
        guard let configs = try? JSONDecoder().decode([TransformerConfig].self, from: data) else { return [] }
        return configs.compactMap { try? $0.resolve() }
    }
}
