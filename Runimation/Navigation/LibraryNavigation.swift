import CoreUI
import RunKit
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    var library: LibraryNavigation {
        get { scope(LibraryNavigation.self) }
        set { }  // no-op; required for ReferenceWritableKeyPath composition
    }
}

// MARK: - Scope

/// Navigation scope for library and stats UI state.
///
/// Public properties are entry points that other modules may trigger.
/// Internal properties control the library's own UI journey.
///
@MainActor
@Observable
final class LibraryNavigation {

    var showLibrary = false

    var showFilePicker = false

    var statsPath: [RunItem] = []

    var columnVisibility: NavigationSplitViewVisibility = .automatic
}
