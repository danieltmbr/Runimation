import Foundation
import RunKit
import VisualiserUI

/// Convenience accessors for resolving typed config values from a `RunRecord`.
///
extension RunRecord {

    func loadVisualisationConfig() -> (any Visualisation)? {
        guard let data = visualisationConfigData,
              let config = try? JSONDecoder().decode(VisualisationConfig.self, from: data)
        else { return nil }
        return config.resolve()
    }

    func loadTransformersConfig() -> [any RunTransformer] {
        guard let data = transformersConfigData,
              let configs = try? JSONDecoder().decode([TransformerConfig].self, from: data)
        else { return [] }
        return configs.map { $0.resolve() }
    }

    func loadInterpolatorConfig() -> (any RunInterpolator)? {
        guard let data = interpolatorConfigData,
              let config = try? JSONDecoder().decode(InterpolatorConfig.self, from: data)
        else { return nil }
        return config.resolve()
    }

    func loadDurationConfig() -> TimeInterval? {
        playDuration
    }
}
