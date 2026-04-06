import RunKit
import RunUI
import SwiftUI
import Visualiser

/// A property wrapper + `DynamicProperty` that reflects the currently
/// playing `RunRecord` and provides bindings for its configuration.
///
/// Declare it in any view with `@NowPlaying var nowPlaying`. The underlying
/// `NowPlayingModel` (an `@Observable` class injected by `.library(_:)`)
/// holds `record` as persistent state and updates it whenever the player's
/// run ID changes via `NowPlayingModifier` — outside the SwiftUI render pass,
/// so there are no state-mutation warnings.
///
/// Bindings for config properties (`visualisation`, `transformers`,
/// `interpolator`, `duration`) write back to the `RunRecord` immediately
/// (auto-persisted by SwiftData) and push the change to the `RunPlayer`
/// so the pipeline reprocesses without any manual sync.
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @NowPlaying var nowPlaying
///
///     var body: some View {
///         if nowPlaying.isSedentary { ... }
///         VisualisationAdjustmentForm(visualisation: nowPlaying.visualisation)
///     }
/// }
/// ```
///
@propertyWrapper
@dynamicMemberLookup
struct NowPlaying: DynamicProperty {

    // MARK: - Model

    @Environment(NowPlayingModel.self)
    private var model

    // MARK: - Player Actions

    @Environment(\.loadEntry)
    private var loadEntry

    @Environment(\.playRun)
    private var playRun

    @Environment(\.setTransformers)
    private var setTransformers

    @Environment(\.setInterpolator)
    private var setInterpolator

    @Environment(\.setDuration)
    private var setDuration

    // MARK: - Public

    var wrappedValue: NowPlaying { self }

    // MARK: - Computed

    /// The currently playing record. Returns `RunRecord.sedentary` when
    /// the player holds a sedentary run (nothing selected yet).
    var record: RunRecord { model.record }

    /// True when the player is in the idle, pre-selection state.
    var isSedentary: Bool { model.record.isSedentary }

    // MARK: - Dynamic Member Lookup

    /// Forwards read-only keypaths directly to the current record.
    subscript<T>(dynamicMember keyPath: KeyPath<RunRecord, T>) -> T {
        model.record[keyPath: keyPath]
    }

    // MARK: - Config Bindings

    /// Two-way binding for the active visualisation.
    ///
    /// Writes update `RunRecord.visualisationConfig` (persisted by SwiftData).
    /// The visualiser reads this binding directly, so changes are live.
    ///
    var visualisation: Binding<any Visualisation> {
        let record = model.record
        return Binding(
            get: { record.loadVisualisationConfig() ?? Warp() },
            set: { newValue in
                record.visualisationConfigData = (try? VisualisationConfig(newValue)).flatMap { try? JSONEncoder().encode($0) }
            }
        )
    }

    /// Two-way binding for the signal processing transformer chain.
    ///
    /// Writes update `RunRecord.transformersConfig` (persisted by SwiftData)
    /// and push to the player so the pipeline reprocesses.
    ///
    var transformers: Binding<[any RunTransformer]> {
        let record = model.record
        let setTransformers = self.setTransformers
        return Binding(
            get: { record.loadTransformersConfig() },
            set: { newValue in
                record.transformersConfigData = (try? TransformerConfig.from(newValue)).flatMap { try? JSONEncoder().encode($0) }
                Task { try? await setTransformers(newValue) }
            }
        )
    }

    /// Two-way binding for the interpolation strategy.
    ///
    /// Writes update `RunRecord.interpolatorConfig` (persisted by SwiftData)
    /// and push to the player so the pipeline reprocesses.
    ///
    var interpolator: Binding<any RunInterpolator> {
        let record = model.record
        let setInterpolator = self.setInterpolator
        return Binding(
            get: { record.loadInterpolatorConfig() ?? LinearRunInterpolator() },
            set: { newValue in
                record.interpolatorConfigData = try? JSONEncoder().encode(InterpolatorConfig(newValue))
                Task { try? await setInterpolator(newValue) }
            }
        )
    }

    /// Two-way binding for the playback duration in seconds.
    ///
    /// Writes update `RunRecord.playDuration` (persisted by SwiftData)
    /// and push to the player so the pipeline reprocesses.
    ///
    var duration: Binding<TimeInterval> {
        let record = model.record
        let setDuration = self.setDuration
        return Binding(
            get: { record.loadDurationConfig() ?? 30 },
            set: { newValue in Task { try? await setDuration(newValue) } }
        )
    }

    // MARK: - Playback

    /// Loads a run record into the player and starts playback.
    ///
    /// - Loads the `Run` from the library (uses cache if available).
    /// - Applies the record's saved config before `setRun` so a single
    ///   processing pass uses the correct settings. If the record has no
    ///   saved config, the outgoing record's config is carried forward.
    /// - `markAsPlaying` fires automatically via `NowPlayingModifier.onChange`
    ///   when the player's run ID changes to match the new record's entryID.
    ///
    func play(_ record: RunRecord) async {
        let previousVisualisation = model.record.loadVisualisationConfig() ?? Warp()
        guard let run = try? await loadEntry(record.entry) else { return }
        await applyConfig(from: record, inheritedVisualisation: previousVisualisation)
        try? await playRun(run)
    }

    // MARK: - Private

    private func applyConfig(from record: RunRecord, inheritedVisualisation: any Visualisation) async {
        if record.hasConfig {
            // Push saved config to the player so it reprocesses with the correct settings.
            try? await setTransformers(record.loadTransformersConfig())
            if let interp = record.loadInterpolatorConfig() { try? await setInterpolator(interp) }
            if let dur = record.loadDurationConfig() { try? await setDuration(dur) }
        } else {
            // No saved config: copy the outgoing record's config onto the new record
            // so settings carry forward. The player is already in the outgoing state,
            // so no player push is needed.
            let outgoing = model.record
            record.transformersConfigData = outgoing.transformersConfigData
            record.interpolatorConfigData = outgoing.interpolatorConfigData
            record.playDuration = outgoing.playDuration
            record.visualisationConfigData = (try? VisualisationConfig(inheritedVisualisation)).flatMap { try? JSONEncoder().encode($0) }
        }
    }
}
