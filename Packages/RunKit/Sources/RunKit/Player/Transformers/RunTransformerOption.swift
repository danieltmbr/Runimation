import Foundation

/// Pairs a display label and description with a `RunTransformer` implementation,
/// making transformer strategies selectable and chainable in the UI.
///
/// Each instance carries a unique `id` so the same transformer type can appear
/// more than once in the applied chain without conflicting identity.
///
public struct RunTransformerOption: Identifiable, Sendable {

    public let id: UUID

    public let label: String

    public let description: String

    public let transformer: any RunTransformer

    public init(
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
    public func with(_ transformer: any RunTransformer) -> Self {
        Self(id: id, label: label, description: description, transformer: transformer)
    }
}

// MARK: - Factory Methods

extension RunTransformerOption {

    /// Gaussian smoothing transformer that reduces noise in the run signal.
    ///
    public static func gaussian(configuration: GuassianRun.Configuration = .init()) -> Self {
        Self(
            label: "Gaussian",
            description: "Smooths run metrics using a time-based Gaussian kernel, reducing noise from GPS anomalies and brief stops while preserving meaningful signal changes.",
            transformer: GuassianRun(configuration: configuration)
        )
    }

    /// Speed-weighted transformer that fades direction amplitude at low speeds.
    ///
    public static func speedWeighted(configuration: SpeedWeightedRun.Configuration = .init()) -> Self {
        Self(
            label: "Speed Weighted",
            description: "Fades direction amplitude toward zero when the runner is moving slowly or stopped, and clips speed outliers at the 98th percentile to prevent GPS spikes.",
            transformer: SpeedWeightedRun(configuration: configuration)
        )
    }

    /// Wave-sampling transformer that reduces run data to a sparse set of synthetic segments.
    ///
    public static func waveSampling(targetCount: Int = 15, rank: Int = 5) -> Self {
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
    public static var catalog: [Self] { [.gaussian(), .speedWeighted(), .waveSampling()] }
}
