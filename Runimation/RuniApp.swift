import CoreKit
import RunKit
import RunUI
import StravaKit
import SwiftData
import SwiftUI

@main
struct RuniApp: App {

    private let modelContainer: ModelContainer

    private let library: RunLibrary

    private let stravaTracker: StravaTracker

    init() {
        let container = try! ModelContainer(for: RunRecord.self)
        modelContainer = container

        let client = StravaClient()
        let tracker = StravaTracker(client: client)
        stravaTracker = tracker

        let storage = SwiftDataRunStorage(context: container.mainContext)
        library = RunLibrary(trackers: [tracker], storage: storage)

        seedBundledRunIfNeeded(context: container.mainContext, library: library)
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
                stravaTracker.handleCallbackURL(url)
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
                .library(library, modelContext: modelContainer.mainContext)
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

// MARK: - Seed

/// Seeds the bundled sample run on first launch in DEBUG builds.
///
private func seedBundledRunIfNeeded(context: ModelContext, library: RunLibrary) {
    #if DEBUG
    let name = "run-01"
    let all = (try? context.fetch(FetchDescriptor<RunRecord>())) ?? []
    let alreadyExists = all.contains {
        if case .bundled(let n) = $0.source { return n == name }
        return false
    }
    guard !alreadyExists else { return }
    let gpxParser = GPX.Parser()
    guard let track: GPX.Track = gpxParser.parse(fileNamed: name) else { return }
    library.importTrack(
        name: track.name.isEmpty ? name : track.name,
        date: track.date ?? Date(),
        points: track.points,
        source: .bundled(name: name)
    )
    #endif
}
