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
    var deleteEntry: DeleteEntryAction = DeleteEntryAction()

    @Entry
    var fetchRun: FetchRunAction = FetchRunAction()

    @Entry
    var playEntry: PlayEntryAction = PlayEntryAction()

    @Entry
    var connectLibrary: ConnectAction = ConnectAction()

    @Entry
    var disconnectLibrary: DisconnectAction = DisconnectAction()
}

// MARK: - View Extension

extension View {

    /// Injects a `RunLibrary` and all its associated actions into the
    /// SwiftUI environment, making them available to any descendant view
    /// via `@LibraryState` and `@Environment(\.action)`.
    ///
    /// The `player` parameter is required to create `PlayEntryAction`,
    /// which coordinates fetching a track from the library and starting playback.
    ///
    /// Apply once near the root of the library's view hierarchy:
    /// ```swift
    /// RunLibraryView()
    ///     .library(library, player: player)
    /// ```
    ///
    @MainActor
    func library(_ library: RunLibrary, player: RunPlayer) -> some View {
        environment(library)
            .environment(\.refreshLibrary, RefreshLibraryAction(library: library))
            .environment(\.loadNextPage, LoadNextPageAction(library: library))
            .environment(\.importFile, ImportFileAction(library: library))
            .environment(\.deleteEntry, DeleteEntryAction(library: library))
            .environment(\.fetchRun, FetchRunAction(library: library))
            .environment(\.playEntry, PlayEntryAction(library: library, player: player))
            .environment(\.connectLibrary, ConnectAction(library: library))
            .environment(\.disconnectLibrary, DisconnectAction(library: library))
    }
}
