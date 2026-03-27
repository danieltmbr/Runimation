import RunKit
import SwiftUI
import Visualiser

/// A button that loads a `RunRecord` into the player, assembling the full
/// play flow from focused environment actions.
///
/// On tap:
/// 1. Saves the outgoing run's config.
/// 2. Loads the run from the library.
/// 3. Sets it on the player (awaited, so config is applied after).
/// 4. Restores the incoming run's saved config, or inherits the most
///    recently played run's config if none has been saved yet.
/// 5. Marks the record as playing.
///
/// Usage:
/// ```swift
/// PlayRunButton(record, onPlayed: { showLibrary = false }) { record in
///     RunEntryRow(record: record) { ... }
/// }
/// ```
///
struct PlayRunButton<Content: View>: View {

    @Environment(RunLibrary.self)
    private var library

    @Environment(RunPlayer.self)
    private var player

    @Environment(VisualisationModel.self)
    private var visualisationModel

    @Environment(\.loadRun)
    private var loadRun

    let record: RunRecord

    let onPlayed: @MainActor () -> Void

    @ViewBuilder
    let content: (RunRecord) -> Content

    init(
        _ record: RunRecord,
        onPlayed: @escaping @MainActor () -> Void = {},
        @ViewBuilder content: @escaping (RunRecord) -> Content
    ) {
        self.record = record
        self.onPlayed = onPlayed
        self.content = content
    }

    var body: some View {
        Button(action: play) {
            content(record)
        }
    }

    // MARK: - Private

    private func play() {
        Task { @MainActor in
            // 1. Save outgoing run's config before switching
            library.saveCurrentConfig(
                visualisation: visualisationModel.current,
                transformers: player.transformers,
                interpolator: player.interpolator,
                duration: player.duration
            )

            // 2. Load the run from the library
            guard let run = try? await loadRun(record) else { return }

            // 3. Start playback — config must be applied AFTER setRun to avoid
            //    didSet tasks cancelling the in-flight processing task.
            try? await player.setRun(run)

            // 4. Restore per-run config, falling back to last-used, then defaults
            restoreConfig(for: record)

            // 5. Mark as playing and update timestamp
            library.markAsPlaying(record)

            onPlayed()
        }
    }

    private func restoreConfig(for record: RunRecord) {
        if record.hasConfig {
            if let vis = record.loadVisualisationConfig() { visualisationModel.current = vis }
            let transformers = record.loadTransformersConfig()
            if !transformers.isEmpty { player.transformers = transformers }
            if let interpolator = record.loadInterpolatorConfig() { player.interpolator = interpolator }
            if let duration = record.loadDurationConfig() { player.duration = duration }
        } else if let last = library.lastUsedConfig() {
            visualisationModel.current = last.visualisation
            player.transformers = last.transformers
            player.interpolator = last.interpolator
            player.duration = last.duration
        }
    }
}
