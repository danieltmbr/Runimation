import AuthenticationServices
import RunKit
import SwiftUI

// MARK: - Environment Keys

extension EnvironmentValues {

    @Entry
    public var presentationAnchor: ASPresentationAnchor? = nil

    @Entry
    public var refreshLibrary: RefreshLibraryAction = RefreshLibraryAction()

    @Entry
    public var loadNextPage: LoadNextPageAction = LoadNextPageAction()

    @Entry
    public var loadRun: LoadRunAction = LoadRunAction()

    @Entry
    public var hasLocalTrack: HasLocalTrackAction = HasLocalTrackAction()

    @Entry
    public var deleteRun: DeleteRunAction = DeleteRunAction()

    @Entry
    public var connect: ConnectAction = ConnectAction()

    @Entry
    public var disconnect: DisconnectAction = DisconnectAction()
}

// MARK: - View Extension

extension View {

    /// Injects a `RunLibrary` and its core actions into the SwiftUI environment,
    /// making them available to any descendant view via `@LibraryState` and
    /// `@Environment(\.action)`.
    ///
    /// Apply once near the root of the library's view hierarchy. App targets
    /// can layer additional app-specific actions on top:
    /// ```swift
    /// someView
    ///     .library(library)
    ///     .environment(\.importFile, ImportFileAction(library: library))
    /// ```
    ///
    @MainActor
    public func library(_ library: RunLibrary) -> some View {
        environment(library)
            .environment(\.refreshLibrary, RefreshLibraryAction(library: library))
            .environment(\.loadNextPage, LoadNextPageAction(library: library))
            .environment(\.loadRun, LoadRunAction(library: library))
            .environment(\.hasLocalTrack, HasLocalTrackAction(library: library))
            .environment(\.deleteRun, DeleteRunAction(library: library))
            .environment(\.connect, ConnectAction(library: library))
            .environment(\.disconnect, DisconnectAction(library: library))
    }
}
