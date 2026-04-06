import RunKit
import RunUI
import SwiftData
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

    /// Injects a `RunLibrary`, all core library actions (via RunUI's `.library(_:)`),
    /// and app-specific import actions into the SwiftUI environment.
    ///
    /// Also injects the `ModelContext` so import actions can write per-run
    /// configuration to the SwiftData store.
    ///
    /// Apply once near the root of the library's view hierarchy:
    /// ```swift
    /// RuniWindow(...)
    ///     .library(library, modelContext: modelContainer.mainContext)
    /// ```
    ///
    @MainActor
    func library(_ library: RunLibrary, modelContext: ModelContext) -> some View {
        self.library(library)
            .environment(\.importFile, ImportFileAction(library: library))
            .environment(\.importDocument, ImportDocumentAction(library: library, modelContext: modelContext))
    }
}
