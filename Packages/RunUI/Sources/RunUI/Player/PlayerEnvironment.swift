import SwiftUI
import RunKit

// MARK: - Environment Keys

extension EnvironmentValues {
    
    @Entry
    var togglePlay: TogglePlayAction = TogglePlayAction()
    
    @Entry
    var stop: StopAction = StopAction()
    
    @Entry
    var seek: SeekAction = SeekAction()
    
    @Entry
    var loadRun: LoadRunAction = LoadRunAction()
    
    @Entry
    var setTransformer: SetTransformerAction = SetTransformerAction()

    @Entry
    var setInterpolator: SetInterpolatorAction = SetInterpolatorAction()
}

// MARK: - View Extension

extension View {

    /// Injects a `RunPlayer` and all its associated actions into
    /// the SwiftUI environment, making them available to any descendant
    /// view via `@PlayerState` and `@Environment(\.action)`.
    ///
    /// Apply once near the root of the player's view hierarchy:
    /// ```swift
    /// RunPlayerView()
    ///     .player(player)
    /// ```
    ///
    @MainActor
    public func player(_ player: RunPlayer) -> some View {
        environment(player)
            .environment(\.togglePlay, TogglePlayAction(player: player))
            .environment(\.stop, StopAction(player: player))
            .environment(\.seek, SeekAction(player: player))
            .environment(\.loadRun, LoadRunAction(player: player))
            .environment(\.setTransformer, SetTransformerAction(player: player))
            .environment(\.setInterpolator, SetInterpolatorAction(player: player))
    }
}
