import AuthenticationServices
import RunKit
import RunUI
import SwiftData
import SwiftUI
import Visualiser
#if os(iOS)
import UIKit
#endif

/// Per-window root view.
///
/// Owns the `NavigationModel` (player + now-playing + navigation state) and
/// sets up the full environment chain for its subtree. Platform-specific
/// layout lives in `content`: `NavigationSplitView` on Mac/iPad,
/// `NavigationStack` + sheets on iPhone.
///
/// Two instances exist on macOS: the main persistent window (`autoRestore: true`)
/// and the runi-viewer window (`autoRestore: false`). On iOS there is only one.
///
struct RuniWindow: View {

    let library: RunLibrary

    let modelContainer: ModelContainer

    @State
    private var navigationModel: NavigationModel

    #if os(iOS)
    @State
    private var presentationAnchor: ASPresentationAnchor? = nil
    #endif

    init(
        library: RunLibrary,
        modelContainer: ModelContainer,
        autoRestore: Bool
    ) {
        let context = modelContainer.mainContext
        let navigationModel = NavigationModel(
            findRecord: { entry in
                try? context.fetch(FetchDescriptor.record(for: entry)).first
            },
            markAsPlaying: { record in library.markAsPlaying(record.entry) },
            autoRestore: autoRestore
        )
        self.library = library
        self.modelContainer = modelContainer
        self._navigationModel = State(initialValue: navigationModel)
    }

    // MARK: - Body

    var body: some View {
        RuniView()
            .nowPlaying(navigationModel.nowPlaying)
            .library(library, modelContext: modelContainer.mainContext)
            .player(navigationModel.player)
            .export(library: library, modelContext: modelContainer.mainContext)
            .environment(navigationModel)
            .modelContainer(modelContainer)
            .focusedValue(\.navigationModel, navigationModel)
            #if os(iOS)
            .background(WindowAnchorReader { anchor in presentationAnchor = anchor })
            .environment(\.presentationAnchor, presentationAnchor)
            #endif
    }
}

// MARK: - iOS Window Reader

#if os(iOS)
/// Captures the `UIWindow` containing this view and reports it via `onCapture`.
///
/// Used to inject the presentation anchor for `ASWebAuthenticationSession`
/// into the SwiftUI environment without UIKit dependencies in leaf views.
///
private struct WindowAnchorReader: UIViewRepresentable {

    let onCapture: @MainActor (UIWindow) -> Void

    func makeUIView(context: Context) -> UIView { UIView() }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let window = uiView.window else { return }
        Task { @MainActor in onCapture(window) }
    }
}
#endif
