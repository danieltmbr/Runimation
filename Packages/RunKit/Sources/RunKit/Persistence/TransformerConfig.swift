import Foundation

/// Codable representation of the finite set of `RunTransformer` conformers.
///
/// Using an enum with associated values avoids double JSON encoding.
/// `NormalisedRun` is intentionally excluded — it is always applied internally
/// by `RunPlayer` and is never user-configurable.
/// Unknown cases are silently dropped on decode so future transformer types
/// degrade gracefully when reading older persisted data.
///
public enum TransformerConfig: Codable, Sendable {

    case gaussian(GuassianRun)
    case speedWeighted(SpeedWeightedRun)
    case waveSampling(WaveSamplingTransformer)

    // MARK: - Init

    public init(_ transformer: any RunTransformer) throws {
        switch transformer {
        case let t as GuassianRun:             self = .gaussian(t)
        case let t as SpeedWeightedRun:        self = .speedWeighted(t)
        case let t as WaveSamplingTransformer: self = .waveSampling(t)
        default:
            throw EncodingError.invalidValue(
                transformer,
                .init(codingPath: [], debugDescription: "Unknown RunTransformer type: \(type(of: transformer))")
            )
        }
    }

    // MARK: - Resolve

    public func resolve() -> any RunTransformer {
        switch self {
        case .gaussian(let t):      return t
        case .speedWeighted(let t): return t
        case .waveSampling(let t):  return t
        }
    }

    // MARK: - Array Helpers

    /// Encodes an array of transformers to `[TransformerConfig]`.
    public static func from(_ transformers: [any RunTransformer]) throws -> [TransformerConfig] {
        try transformers.map { try TransformerConfig($0) }
    }
}
