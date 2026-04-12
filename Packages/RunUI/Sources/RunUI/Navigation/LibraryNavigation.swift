import CoreUI
import RunKit
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    public var library: LibraryNavigation {
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
public final class LibraryNavigation {

    public var showLibrary = false

    public var showFilePicker = false

    public var statsPath: [RunItem] = []

    public var columnVisibility: NavigationSplitViewVisibility = .automatic

    public init() {}
}
