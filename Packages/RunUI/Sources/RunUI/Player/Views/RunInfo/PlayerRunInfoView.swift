import SwiftUI

/// A player-coupled wrapper around `RunInfoView`.
///
/// Reads the current run from the player environment via `@Player`
/// and forwards it to `RunInfoView`. Use this in playback controls and
/// Now Playing sheets where the display should track the loaded run.
///
/// For static display (e.g. library rows), use `RunInfoView(run:)` directly.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct PlayerRunInfoView: View {

    @Player(\.run.metrics)
    private var run

    public init() {}

    public var body: some View {
        RunInfoView(run: run)
    }
}
