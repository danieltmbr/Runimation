import RunKit
import RunUI
import StravaKit
import SwiftData
import SwiftUI

@main
struct RuniApp: App {
    
    private let modelContainer: ModelContainer
    
    private let library: RunLibrary
    
    init() {
        let container = try! ModelContainer(for: RunRecord.self)
        modelContainer = container
        let client = StravaClient()
        library = RunLibrary(
            modelContext: container.mainContext,
            stravaClient: client
        )
    }
    
    var body: some Scene {
#if os(macOS)
        // Main persistent player window. Handles the Strava OAuth callback scheme
        // (runimation://) — .runi file URLs are routed to the runi-viewer group below.
        WindowGroup {
            RuniWindow(
                library: library,
                modelContainer: modelContainer,
                autoRestore: true
            )
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .windowToolbarFullScreenVisibility(.onHover)
            .onOpenURL { url in
                guard url.scheme == "runimation" else { return }
                library.handleCallbackURL(url)
            }
        }
        .handlesExternalEvents(matching: ["runimation"])
        
        // Viewer window opened for .runi files — each file gets its own independent
        // player with no auto-restore from the library.
        WindowGroup(id: "runi-viewer") {
            RuniWindow(
                library: library,
                modelContainer: modelContainer,
                autoRestore: false
            )
        }
        .handlesExternalEvents(matching: ["runi"])
        
        // Floating customisation panel that tracks whichever player window is focused.
        Window("Customisation", id: "customisation") {
            CustomisationWindow()
                .library(library)
                .modelContainer(modelContainer)
        }
        .windowLevel(.floating)
        .defaultSize(width: 280, height: 500)
        .defaultPosition(.trailing)
#else
        WindowGroup {
            RuniWindow(
                library: library,
                modelContainer: modelContainer,
                autoRestore: true
            )
        }
#endif
    }
}
