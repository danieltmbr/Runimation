import RunKit
import SwiftUI
import Visualiser

/// A property wrapper + `DynamicProperty` that reflects the currently
/// playing `RunRecord` and provides bindings for its configuration.
///
/// Declare it in any view with `@NowPlaying var nowPlaying`. SwiftUI
/// automatically re-renders the view whenever `RunPlayer.run` or
/// `RunLibrary.entries` change, keeping `record` and all derived
/// properties in sync.
///
/// `NowPlaying` resolves the active record by matching the player's
/// `run.id` against the library's entries. It returns `RunRecord.sedentary`
/// when nothing real is loaded, so `record` is always non-optional.
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

    @Environment(RunPlayer.self)
    private var player

    @Environment(RunLibrary.self)
    private var library

    /// Required by `@propertyWrapper`. Returns `self` so the declared
    /// variable exposes the full `NowPlaying` interface.
    ///
    var wrappedValue: NowPlaying { self }

    // MARK: - Current Record

    /// The currently playing record. Returns `RunRecord.sedentary` when
    /// the player holds a sedentary run (nothing selected yet).
    ///
    var record: RunRecord {
        library.record(for: player.run.id) ?? .sedentary
    }

    /// True when the player is in the idle, pre-selection state.
    ///
    var isSedentary: Bool { record.isSedentary }

    // MARK: - Dynamic Member Lookup

    /// Forwards read-only keypaths directly to the current record.
    ///
    subscript<T>(dynamicMember keyPath: KeyPath<RunRecord, T>) -> T {
        record[keyPath: keyPath]
    }

    // MARK: - Config Bindings

    /// Two-way binding for the active visualisation.
    ///
    /// Writes update `RunRecord.visualisationConfig` (persisted by SwiftData).
    /// The visualiser reads this binding directly, so changes are live.
    ///
    var visualisation: Binding<any Visualisation> {
        let record = self.record
        return Binding(
            get: { record.loadVisualisationConfig() ?? Warp() },
            set: { newValue in
                record.visualisationConfig = try? VisualisationConfig(newValue)
            }
        )
    }

    /// Two-way binding for the signal processing transformer chain.
    ///
    /// Writes update `RunRecord.transformersConfig` (persisted by SwiftData)
    /// and push to `RunPlayer.setTransformers(_:)` so the pipeline reprocesses.
    ///
    var transformers: Binding<[any RunTransformer]> {
        let record = self.record
        let player = self.player
        return Binding(
            get: { record.loadTransformersConfig() },
            set: { newValue in
                record.transformersConfig = try? TransformerConfig.from(newValue)
                player.setTransformers(newValue)
            }
        )
    }

    /// Two-way binding for the interpolation strategy.
    ///
    /// Writes update `RunRecord.interpolatorConfig` (persisted by SwiftData)
    /// and push to `RunPlayer.setInterpolator(_:)` so the pipeline reprocesses.
    ///
    var interpolator: Binding<any RunInterpolator> {
        let record = self.record
        let player = self.player
        return Binding(
            get: { record.loadInterpolatorConfig() ?? LinearRunInterpolator() },
            set: { newValue in
                record.interpolatorConfig = InterpolatorConfig(newValue)
                player.setInterpolator(newValue)
            }
        )
    }

    /// Two-way binding for the playback duration preset.
    ///
    /// Writes update `RunRecord.durationConfig` (persisted by SwiftData)
    /// and set `RunPlayer.duration` directly so the pipeline reprocesses.
    ///
    var duration: Binding<RunPlayer.Duration> {
        let record = self.record
        let player = self.player
        return Binding(
            get: { record.loadDurationConfig() ?? .thirtySeconds },
            set: { newValue in
                record.durationConfig = DurationConfig(newValue)
                player.duration = newValue
            }
        )
    }

    // MARK: - Playback

    /// Loads a run record into the player and starts playback.
    ///
    /// - Loads the `Run` from the library (uses cache if available).
    /// - Sets it on the player; `run.id` matches `record.entryID` so
    ///   `NowPlaying` immediately resolves to the new record.
    /// - Pushes the record's saved config to the player. If the record
    ///   has no saved config, the current in-memory config is carried
    ///   forward and persisted on the new record.
    /// - Marks the record as playing (updates `lastPlayedAt`).
    ///
    func play(_ record: RunRecord) async {
        // Capture outgoing visualisation before setRun changes self.record.
        let previousVisualisation = self.record.loadVisualisationConfig() ?? Warp()
        guard let run = try? await library.loadRun(for: record) else { return }
        try? await player.setRun(run)
        applyConfig(from: record, inheritedVisualisation: previousVisualisation)
        library.markAsPlaying(record)
    }

    // MARK: - Private

    private func applyConfig(from record: RunRecord, inheritedVisualisation: any Visualisation) {
        if record.hasConfig {
            // Push saved config to player
            player.setTransformers(record.loadTransformersConfig())
            if let interp = record.loadInterpolatorConfig() { player.setInterpolator(interp) }
            if let dur = record.loadDurationConfig() { player.duration = dur }
        } else {
            // No saved config: persist the current in-memory values so this
            // run inherits the settings from whatever was playing before.
            record.transformersConfig = try? TransformerConfig.from(player.transformers)
            record.interpolatorConfig = InterpolatorConfig(player.interpolator)
            record.durationConfig = DurationConfig(player.duration)
            record.visualisationConfig = try? VisualisationConfig(inheritedVisualisation)
        }
    }
}
