import RunKit
import SwiftUI

// MARK: - Environment Keys

public extension EnvironmentValues {

    @Entry
    var exportRuni: ExportRuniAction = ExportRuniAction()

    @Entry
    var exportVideo: ExportVideoAction = ExportVideoAction()

    @Entry
    var importFile: ImportAction = ImportAction()
}

// MARK: - View Extension

public extension View {

    /// Injects all transfer actions (export + import) into the environment.
    ///
    /// Call once near the root, after `.library(_:)`:
    /// ```swift
    /// RuniWindow(...)
    ///     .library(library)
    ///     .transfer(library: library)
    /// ```
    ///
    @MainActor
    func transfer(library: RunLibrary) -> some View {
        environment(\.exportRuni, ExportRuniAction(library: library))
            .environment(\.exportVideo, ExportVideoAction(library: library))
            .environment(\.importFile, ImportAction.allSupported(library: library))
    }
}
