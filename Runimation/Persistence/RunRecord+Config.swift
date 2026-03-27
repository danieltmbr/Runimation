import CoreKit
import RunKit
import Visualiser

/// Config save/load helpers for `RunRecord`.
///
/// Each method encodes or decodes via the discriminated wrapper types in
/// `Persistence/`, keeping all serialisation logic in one place.
///
extension RunRecord {

    // MARK: - Save

    func saveConfig(
        visualisation: any Visualisation,
        transformers: [any RunTransformer],
        interpolator: any RunInterpolator,
        duration: RunPlayer.Duration
    ) {
        visualisationData = try? VisualisationConfig.encode(visualisation)
        transformersData = try? TransformerConfig.encode(transformers)
        interpolatorData = try? InterpolatorConfig.encode(interpolator)
        durationData = try? DurationConfig.encode(duration)
    }

    // MARK: - Load

    func loadVisualisationConfig() -> (any Visualisation)? {
        visualisationData.flatMap(VisualisationConfig.decode(from:))
    }

    func loadTransformersConfig() -> [any RunTransformer] {
        transformersData.map(TransformerConfig.decode(from:)) ?? []
    }

    func loadInterpolatorConfig() -> (any RunInterpolator)? {
        interpolatorData.flatMap(InterpolatorConfig.decode(from:))
    }

    func loadDurationConfig() -> RunPlayer.Duration? {
        durationData.flatMap(DurationConfig.decode(from:))
    }

    // MARK: - Helpers

    var hasConfig: Bool {
        visualisationData != nil
    }
}
