import Foundation
import RunKit
import VisualiserUI

/// Decodes the app-specific config types from the opaque blobs in a `RunItem`.
///
/// These helpers live in `RuniTransfer` because the concrete config types
/// (`VisualisationConfig`, `TransformerConfig`, etc.) are serialisation concerns
/// owned by this package — `RunKit` treats them as opaque `Data?`.
///
public extension RunItem {

    func loadVisualisationConfig() -> (any Visualisation)? {
        guard let data = config?.visualisationConfigData,
              let decoded = try? JSONDecoder().decode(VisualisationConfig.self, from: data)
        else { return nil }
        return decoded.resolve()
    }

    func loadTransformersConfig() -> [any RunTransformer] {
        guard let data = config?.transformersConfigData,
              let configs = try? JSONDecoder().decode([TransformerConfig].self, from: data)
        else { return [] }
        return configs.map { $0.resolve() }
    }

    func loadInterpolatorConfig() -> (any RunInterpolator)? {
        guard let data = config?.interpolatorConfigData,
              let decoded = try? JSONDecoder().decode(InterpolatorConfig.self, from: data)
        else { return nil }
        return decoded.resolve()
    }

    func loadDurationConfig() -> TimeInterval? {
        config?.playDuration
    }
}
