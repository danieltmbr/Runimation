import RunKit
import RunUI
import SwiftUI

// MARK: - App-Specific Environment Keys

extension EnvironmentValues {

    @Entry
    var importFile: ImportFileAction = ImportFileAction()

    @Entry
    var importDocument: ImportDocumentAction = ImportDocumentAction()
}

// MARK: - View Extension

extension View {

    /// Injects app-specific import actions alongside the core library environment.
    ///
    /// Call this after RunUI's `.library(_:)` to add GPX file import and
    /// `.runi` document import support:
    /// ```swift
    /// view
    ///     .library(library)
    ///     .importActions(library: library)
    /// ```
    ///
    @MainActor
    func importActions(library: RunLibrary) -> some View {
        environment(\.importFile, ImportFileAction(library: library))
            .environment(\.importDocument, ImportDocumentAction(library: library))
    }
}
