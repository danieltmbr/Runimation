#if os(macOS)
import RunKit
import RunUI
import SwiftData
import SwiftUI

/// A macOS scene that opens an independent window for each `.runi` file.
///
/// Shares the app's `RunLibrary` and `ModelContainer` with the main window so
/// imported runs are visible across the whole app. Each window gets its own
/// dedicated `RunPlayer` so playback is independent.
///
struct RuniViewerScene: Scene {

    let library: RunLibrary

    let modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup(id: "runi-viewer") {
            RuniViewerContent(library: library, modelContainer: modelContainer)
        }
        .handlesExternalEvents(matching: ["runi"])
    }
}

// MARK: - Content

/// The view inside each `.runi` viewer window.
///
/// `RunPlayer` is per-window state. `RunLibrary` and `ModelContainer` are passed
/// in from the app level. Modifier order mirrors the main window: `.library` is
/// applied first (inner), `.player` second (outer). In SwiftUI the last modifier
/// is the outer wrapper, so `.player` sets RunPlayer in the environment before
/// the `.library` modifier's `NowPlayingModifier` reads it.
///
private struct RuniViewerContent: View {

    let library: RunLibrary

    let modelContainer: ModelContainer

    @State private var player = RunPlayer(transformers: [GuassianRun()])

    var body: some View {
        ContentView(autoOpenLibrary: false)
            .library(library)
            .player(player)
            .export(player: player)
            .modelContainer(modelContainer)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .windowToolbarFullScreenVisibility(.onHover)
    }
}
#endif
