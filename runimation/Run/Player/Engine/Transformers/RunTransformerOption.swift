import Foundation

/// Pairs a display label and description with a `RunTransformer` implementation,
/// making transformer strategies selectable and chainable in the UI.
///
/// Each instance carries a unique `id` so the same transformer type can appear
/// more than once in the applied chain without conflicting identity.
///
struct RunTransformerOption: Identifiable {

    let id: UUID

    let label: String

    let description: String

    let transformer: any RunTransformer

    init(
        id: UUID = UUID(),
        label: String,
        description: String,
        transformer: any RunTransformer
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.transformer = transformer
    }

    /// Returns a copy of this option with a new transformer, preserving id, label, and description.
    ///
    func with(_ transformer: any RunTransformer) -> Self {
        Self(id: id, label: label, description: description, transformer: transformer)
    }
}

// MARK: - Factory Methods

extension RunTransformerOption {

    /// Gaussian smoothing transformer that reduces noise in the run signal.
    ///
    static func gaussian(configuration: GuassianRun.Configuration = .init()) -> Self {
        Self(
            label: "Gaussian",
            description: "Smooths run metrics using a time-based Gaussian kernel, reducing noise from GPS anomalies and brief stops while preserving meaningful signal changes.",
            transformer: GuassianRun(configuration: configuration)
        )
    }

    /// Speed-weighted transformer that fades direction amplitude at low speeds.
    ///
    static func speedWeighted(configuration: SpeedWeightedRun.Configuration = .init()) -> Self {
        Self(
            label: "Speed Weighted",
            description: "Fades direction amplitude toward zero when the runner is moving slowly or stopped, and clips speed outliers at the 98th percentile to prevent GPS spikes.",
            transformer: SpeedWeightedRun(configuration: configuration)
        )
    }

    /// Wave-sampling transformer that reduces run data to a sparse set of synthetic segments.
    ///
    static func waveSampling(targetCount: Int = 15, rank: Int = 5) -> Self {
        Self(
            label: "Wave Sampling",
            description: "Reduces the run to a fixed number of synthetic segments by alternating between peak and valley values across windows, producing a wave-like dataset that makes interpolation differences clearly visible.",
            transformer: WaveSamplingTransformer(targetCount: targetCount, rank: rank)
        )
    }

    /// All built-in transformer options, in display order.
    ///
    /// Each call returns fresh instances with new UUIDs — suitable for adding
    /// to the applied chain without identity conflicts.
    ///
    static var catalog: [Self] { [.gaussian(), .speedWeighted(), .waveSampling()] }
}
