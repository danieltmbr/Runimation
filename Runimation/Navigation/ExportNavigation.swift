import CoreUI
import RunKit
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    var export: ExportNavigation {
        get { scope(ExportNavigation.self) }
        set { }  // no-op; required for ReferenceWritableKeyPath composition
    }
}

// MARK: - Scope

/// Navigation scope for the export feature.
///
/// `exportingRun` is the public entry point: set it to trigger the export sheet.
/// Internal properties will control the export journey steps once packaged.
///
@MainActor
@Observable
final class ExportNavigation {

    /// Set to trigger the export sheet for a specific run.
    ///
    var exportingRun: RunItem?
}
