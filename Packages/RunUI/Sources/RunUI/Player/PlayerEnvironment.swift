import SwiftUI
import RunKit

// MARK: - Environment Keys

extension EnvironmentValues {
    
    @Entry
    public var togglePlay: TogglePlayAction = TogglePlayAction()
    
    @Entry
    public var stop: StopAction = StopAction()
    
    @Entry
    public var seek: SeekAction = SeekAction()
    
    @Entry
    public var playRun: PlayRunAction = PlayRunAction()

    @Entry
    public var setTransformers: SetTransformerAction = SetTransformerAction()

    @Entry
    public var setInterpolator: SetInterpolatorAction = SetInterpolatorAction()

    @Entry
    public var setDuration: SetDurationAction = SetDurationAction()
}

// MARK: - View Extension

extension View {

    /// Injects a `RunPlayer` and all its associated actions into
    /// the SwiftUI environment, making them available to any descendant
    /// view via `@Player` and `@Environment(\.action)`.
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
            .environment(\.playRun, PlayRunAction(player: player))
            .environment(\.setTransformers, SetTransformerAction(player: player))
            .environment(\.setInterpolator, SetInterpolatorAction(player: player))
            .environment(\.setDuration, SetDurationAction(player: player))
    }
}
