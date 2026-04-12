import CoreUI
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    public var player: PlayerNavigation {
        get { scope(PlayerNavigation.self) }
        set { }  // no-op; required for ReferenceWritableKeyPath composition
    }
}

// MARK: - Scope

/// Navigation scope for player-related UI state.
///
/// Public properties are entry points that other modules may trigger.
/// Internal properties control the player's own UI journey.
///
@MainActor
@Observable
public final class PlayerNavigation {

    public var showNowPlaying = false

    public var showCustomisation = false

    public init() {}
}
