import RunKit
import RunUI
import SwiftUI

/// Tracks the currently playing `RunRecord` as persistent `@Observable` state.
///
/// Holds only library-facing responsibilities: resolving a `RunRecord` from
/// a run ID and marking it as played. Player observation is handled externally
/// by `.nowPlaying(_:)`, which calls `resolve(runID:)` whenever the player's
/// run changes. Views access this model through the `@NowPlaying` property
/// wrapper rather than directly.
///
@MainActor
@Observable
final class NowPlayingModel {

    // MARK: - State

    /// The currently playing record. `.sedentary` when nothing is selected.
    private(set) var record: RunRecord = .sedentary

    // MARK: - Dependencies

    private let findRecord: @MainActor (RunEntry) -> RunRecord?
    
    private let markAsPlaying: @MainActor (RunRecord) -> Void

    // MARK: - Init

    init(
        findRecord: @escaping @MainActor (RunEntry) -> RunRecord?,
        markAsPlaying: @escaping @MainActor (RunRecord) -> Void
    ) {
        self.findRecord = findRecord
        self.markAsPlaying = markAsPlaying
    }

    // MARK: - Sync

    /// Called by `NowPlayingModifier` whenever `player.run.id` changes.
    ///
    /// Resolves the new record from the library and marks it as playing.
    /// Guards against redundant updates when the ID hasn't actually changed.
    ///
    func resolve(run: RunEntry) {
        let newRecord = findRecord(run) ?? .sedentary
        guard newRecord.entry != record.entry else { return }
        record = newRecord
        if !newRecord.isSedentary {
            markAsPlaying(newRecord)
        }
    }
}

// MARK: - ViewModifier

/// Bridges `RunPlayer` observation to a `NowPlayingModel`.
///
/// Reads the player from the environment (requires `.player(_:)` upstream)
/// and calls `model.resolve(runID:)` via `.onChange` whenever the player's
/// run ID changes. Also injects the model into the environment so
/// `@NowPlaying` wrappers can read it.
///
private struct NowPlayingModifier: ViewModifier {

    @Environment(RunPlayer.self)
    private var player

    let model: NowPlayingModel

    func body(content: Content) -> some View {
        content
            .environment(model)
            .onChange(of: player.run.id, initial: true) { _, id in
                model.resolve(run: RunEntry(id: id))
            }
            .onChange(of: player.duration) { _, newValue in
                model.record.playDuration = newValue
            }
    }
}

// MARK: - View Extension

extension View {

    /// Injects a `NowPlayingModel` into the environment and bridges it to the
    /// player in the environment. Requires `.player(_:)` applied upstream.
    func nowPlaying(_ model: NowPlayingModel) -> some View {
        modifier(NowPlayingModifier(model: model))
    }
}
