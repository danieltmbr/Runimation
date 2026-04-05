import RunKit
import SwiftUI

// MARK: - Environment Keys

extension EnvironmentValues {

    @Entry
    var refreshLibrary: RefreshLibraryAction = RefreshLibraryAction()

    @Entry
    var loadNextPage: LoadNextPageAction = LoadNextPageAction()

    @Entry
    var importFile: ImportFileAction = ImportFileAction()

    @Entry
    var loadRun: LoadRunAction = LoadRunAction()

    @Entry
    var loadEntry: LoadEntryAction = LoadEntryAction()

    @Entry
    var deleteRun: DeleteRunAction = DeleteRunAction()

    @Entry
    var connectLibrary: ConnectAction = ConnectAction()

    @Entry
    var disconnectLibrary: DisconnectAction = DisconnectAction()

    @Entry
    var importDocument: ImportDocumentAction = ImportDocumentAction()
}

// MARK: - View Extension

extension View {

    /// Injects a `RunLibrary` and all its associated actions into the
    /// SwiftUI environment, making them available to any descendant view
    /// via `@LibraryState` and `@Environment(\.action)`.
    ///
    /// Apply once near the root of the library's view hierarchy:
    /// ```swift
    /// PlayerWindow(...)
    ///     .library(library)
    /// ```
    ///
    @MainActor
    func library(_ library: RunLibrary) -> some View {
        environment(library)
            .environment(\.refreshLibrary, RefreshLibraryAction(library: library))
            .environment(\.loadNextPage, LoadNextPageAction(library: library))
            .environment(\.importFile, ImportFileAction(library: library))
            .environment(\.loadRun, LoadRunAction(library: library))
            .environment(\.loadEntry, LoadEntryAction(library: library))
            .environment(\.deleteRun, DeleteRunAction(library: library))
            .environment(\.connectLibrary, ConnectAction(library: library))
            .environment(\.disconnectLibrary, DisconnectAction(library: library))
            .environment(\.importDocument, ImportDocumentAction(library: library))
    }
}
