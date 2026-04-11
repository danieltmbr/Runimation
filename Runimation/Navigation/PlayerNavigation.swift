import CoreUI
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    var player: PlayerNavigation {
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
final class PlayerNavigation {

    var showNowPlaying = false

    var showCustomisation = false
}
