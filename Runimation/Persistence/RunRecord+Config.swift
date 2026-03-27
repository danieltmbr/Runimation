import RunKit
import Visualiser

/// Convenience accessors for resolving typed config values from a `RunRecord`.
///
extension RunRecord {

    func loadVisualisationConfig() -> (any Visualisation)? {
        visualisationConfig?.resolve()
    }

    func loadTransformersConfig() -> [any RunTransformer] {
        transformersConfig?.map { $0.resolve() } ?? []
    }

    func loadInterpolatorConfig() -> (any RunInterpolator)? {
        interpolatorConfig?.resolve()
    }

    func loadDurationConfig() -> RunPlayer.Duration? {
        durationConfig?.resolve()
    }
}
