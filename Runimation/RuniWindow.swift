import RunKit
import RunUI
import SwiftData
import SwiftUI
import Visualiser

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

    init(
        library: RunLibrary,
        modelContainer: ModelContainer,
        autoRestore: Bool
    ) {
        let navigationModel = NavigationModel(
            library: library, autoRestore: autoRestore
        )
        self.library = library
        self.modelContainer = modelContainer
        self._navigationModel = State(initialValue: navigationModel)
    }

    // MARK: - Body

    var body: some View {
        RuniView()
            .nowPlaying(navigationModel.nowPlaying)
            .library(library)
            .player(navigationModel.player)
            .export(library: library)
            .environment(navigationModel)
            .modelContainer(modelContainer)
            .focusedValue(\.navigationModel, navigationModel)
    }
}
