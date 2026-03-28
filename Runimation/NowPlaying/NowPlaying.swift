import RunKit
import RunUI
import SwiftUI
import Visualiser

/// A property wrapper + `DynamicProperty` that reflects the currently
/// playing `RunRecord` and provides bindings for its configuration.
///
/// Declare it in any view with `@NowPlaying var nowPlaying`. SwiftUI calls
/// `update()` before every render after the environment has been refreshed,
/// so `record` is always in sync with the player's current run. Any code
/// path that changes `player.run` (whether via `NowPlaying.play(_:)` or
/// calling `PlayRunAction` directly) automatically marks
/// the new record as playing.
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

    // MARK: - Player State

    @PlayerState(\.run)
    private var run

    // MARK: - Library Actions

    @Environment(\.findRecord)
    private var findRecord

    @Environment(\.loadRun)
    private var loadRun

    @Environment(\.markAsPlaying)
    private var markAsPlaying

    // MARK: - Player Actions

    @Environment(\.playRun)
    private var playRun

    @Environment(\.setTransformers)
    private var setTransformers

    @Environment(\.setInterpolator)
    private var setInterpolator

    @Environment(\.setDuration)
    private var setDuration

    // MARK: - Stored Record

    /// The currently playing record. Returns `RunRecord.sedentary` when
    /// the player holds a sedentary run (nothing selected yet).
    ///
    /// Updated in `update()` before every render when the player's run changes.
    ///
    @State
    private(set) var record: RunRecord = .sedentary

    var wrappedValue: NowPlaying { self }

    // MARK: - DynamicProperty

    mutating func update() {
        guard run.id != record.entryID else { return }
        let newRecord = findRecord(run.id) ?? .sedentary
        record = newRecord
        if !newRecord.isSedentary {
            markAsPlaying(newRecord)
        }
    }

    // MARK: - Computed

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
    /// and push to the player so the pipeline reprocesses.
    ///
    var transformers: Binding<[any RunTransformer]> {
        let record = self.record
        let setTransformers = self.setTransformers
        return Binding(
            get: { record.loadTransformersConfig() },
            set: { newValue in
                record.transformersConfig = try? TransformerConfig.from(newValue)
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
        let record = self.record
        let setInterpolator = self.setInterpolator
        return Binding(
            get: { record.loadInterpolatorConfig() ?? LinearRunInterpolator() },
            set: { newValue in
                record.interpolatorConfig = InterpolatorConfig(newValue)
                Task { try? await setInterpolator(newValue) }
            }
        )
    }

    /// Two-way binding for the playback duration preset.
    ///
    /// Writes update `RunRecord.durationConfig` (persisted by SwiftData)
    /// and push to the player so the pipeline reprocesses.
    ///
    var duration: Binding<RunPlayer.Duration> {
        let record = self.record
        let setDuration = self.setDuration
        return Binding(
            get: { record.loadDurationConfig() ?? .thirtySeconds },
            set: { newValue in
                record.durationConfig = DurationConfig(newValue)
                Task { try? await setDuration(newValue) }
            }
        )
    }

    // MARK: - Playback

    /// Loads a run record into the player and starts playback.
    ///
    /// - Loads the `Run` from the library (uses cache if available).
    /// - Sets it on the player and awaits completion; `run.id` matches
    ///   `record.entryID` so `NowPlaying.update()` resolves the new record.
    /// - Pushes the record's saved config to the player. If the record
    ///   has no saved config, the current in-memory config is carried
    ///   forward and persisted on the new record.
    /// - `markAsPlaying` fires automatically via `update()` when the
    ///   player's run ID changes to match the new record's entryID.
    ///
    func play(_ record: RunRecord) async {
        let previousVisualisation = self.record.loadVisualisationConfig() ?? Warp()
        guard let run = try? await loadRun(record) else { return }
        // Apply config before setRun so the single processing pass uses the correct settings.
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
            let outgoing = self.record
            record.transformersConfig = outgoing.transformersConfig
            record.interpolatorConfig = outgoing.interpolatorConfig
            record.durationConfig = outgoing.durationConfig
            record.visualisationConfig = try? VisualisationConfig(inheritedVisualisation)
        }
    }
}
