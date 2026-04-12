import CoreUI
import RunKit
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    public var importer: ImportNavigation {
        get { scope(ImportNavigation.self) }
        set { }  // no-op; required for ReferenceWritableKeyPath composition
    }
}

// MARK: - Scope

/// Navigation scope for the import feature.
///
/// `importedItem` is the public entry point: set it after a `.runi` file is opened
/// to trigger the save-to-library confirmation alert.
///
@MainActor
@Observable
public final class ImportNavigation {

    /// Set after a `.runi` file is opened — triggers the save-to-library confirmation alert.
    public var importedItem: RunItem?

    public init() {}
}
