import RunKit
import RunUI
import SwiftData
import SwiftUI

/// Tracks the currently playing `RunRecord` as persistent `@Observable` state.
///
/// Holds only library-facing responsibilities: resolving a `RunRecord` from
/// a run ID and marking it as played. Player observation is handled externally
/// by `.nowPlaying(_:)`, which calls `resolve(item:)` whenever the player's
/// `currentItem` changes. Views access this model through the `@NowPlaying`
/// property wrapper rather than directly.
///
@MainActor
@Observable
final class NowPlayingModel {

    // MARK: - State

    /// The currently playing record. `.sedentary` when nothing is selected.
    private(set) var record: RunRecord = .sedentary

    /// True while track data is being fetched from a remote source.
    private(set) var isLoadingRun: Bool = false

    /// Set when a run load fails. Cleared on the next load attempt or via `dismissError()`.
    private(set) var loadError: (any Error)? = nil

    // MARK: - Dependencies

    private let context: ModelContext

    private let markAsPlaying: @MainActor (RunID) -> Void

    // MARK: - Init

    init(
        context: ModelContext,
        markAsPlaying: @escaping @MainActor (RunID) -> Void
    ) {
        self.context = context
        self.markAsPlaying = markAsPlaying
    }

    // MARK: - Loading State

    func beginLoading() { isLoadingRun = true; loadError = nil }
    func finishLoading() { isLoadingRun = false }
    func failLoading(_ error: any Error) { isLoadingRun = false; loadError = error }
    func dismissError() { loadError = nil }

    // MARK: - Sync

    /// Called by `NowPlayingModifier` whenever `player.currentItem` changes.
    ///
    /// Resolves the new `RunRecord` by ID for config bindings, and marks
    /// the run as played. Guards against redundant updates.
    ///
    func resolve(run id: RunID) {
        let newRecord = (try? context.fetch(FetchDescriptor.record(forID: id)).first) ?? .sedentary
        guard newRecord.item.id != record.item.id else { return }
        record = newRecord
        if !newRecord.isSedentary {
            markAsPlaying(id)
        }
    }
}

// MARK: - ViewModifier

/// Bridges `RunPlayer` observation to a `NowPlayingModel`.
///
/// Reads the player from the environment (requires `.player(_:)` upstream)
/// and calls `model.resolve(item:)` via `.onChange` whenever the player's
/// `currentItem` changes. Also injects the model into the environment so
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
                model.resolve(run: id)
            }
            .onChange(of: player.duration) { _, newValue in
                model.record.playDuration = newValue
            }
            .overlay {
                if model.isLoadingRun {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert(
                "Couldn't Load Run",
                isPresented: Binding(get: { model.loadError != nil }, set: { _ in model.dismissError() })
            ) {
                Button("OK") { model.dismissError() }
            } message: {
                if let error = model.loadError {
                    Text(error.localizedDescription)
                }
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
