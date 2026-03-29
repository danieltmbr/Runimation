import RunKit
import RunUI
import SwiftUI

/// Tracks the currently playing `RunRecord` as persistent `@Observable` state.
///
/// Holds only library-facing responsibilities: resolving a `RunRecord` from
/// a run ID and marking it as played. Player observation is handled externally
/// by `NowPlayingModifier`, which calls `resolve(runID:)` whenever the player's
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

    private let findRecord: @MainActor (UUID) -> RunRecord?
    
    private let markAsPlaying: @MainActor (RunRecord) -> Void

    // MARK: - Init

    init(
        findRecord: @escaping @MainActor (UUID) -> RunRecord?,
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
    func resolve(runID: UUID) {
        let newRecord = findRecord(runID) ?? .sedentary
        guard newRecord.entryID != record.entryID else { return }
        record = newRecord
        if !newRecord.isSedentary {
            markAsPlaying(newRecord)
        }
    }
}

// MARK: - ViewModifier

/// Bridges `RunPlayer` observation to `NowPlayingModel`.
///
/// Applied once as part of `.library(_:)`. Reads the player from the
/// environment (requires `.player(_:)` to have been applied upstream)
/// and calls `model.sync(runID:)` via `.onChange` whenever the player's
/// run ID changes. Also injects the model into the environment so
/// `@NowPlaying` wrappers can read it.
///
private struct NowPlayingModifier: ViewModifier {

    @Environment(RunPlayer.self)
    private var player

    @State
    private var model: NowPlayingModel

    init(library: RunLibrary) {
        _model = State(initialValue: NowPlayingModel(
            findRecord: library.record(for:),
            markAsPlaying: library.markAsPlaying
        ))
    }

    func body(content: Content) -> some View {
        let model = model
        content
            .environment(model)
            .onChange(of: player.run.id, initial: true) { _, id in
                model.resolve(runID: id)
            }
            .onChange(of: player.duration) { oldValue, newValue in
                model.record.playDuration = newValue
            }
    }
}

// MARK: - View Extension

extension View {
    func nowPlaying(library: RunLibrary) -> some View {
        modifier(NowPlayingModifier(library: library))
    }
}
