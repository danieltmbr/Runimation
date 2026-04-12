import CoreUI
import RunKit
import SwiftUI

// MARK: - NavigationModel Extension

extension NavigationModel {
    public var export: ExportNavigation {
        get { scope(ExportNavigation.self) }
        set { }  // no-op; required for ReferenceWritableKeyPath composition
    }
}

// MARK: - Scope

/// Navigation scope for the export feature.
///
/// `exportingRun` is the public entry point: set it to trigger the export sheet.
/// Internal properties control the export journey steps.
///
@MainActor
@Observable
public final class ExportNavigation {

    /// Set to trigger the export sheet for a specific run.
    public var exportingRun: RunItem?

    public init() {}
}
