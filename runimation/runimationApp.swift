import RunKit
import RunUI
import StravaKit
import SwiftUI

@main
struct RunimationApp: App {

    @State private var player = RunPlayer(transformers: [GuassianRun()])

    @State private var stravaClient: StravaClient

    @State private var library: RunLibrary

    @State private var visualisationModel = VisualisationModel()

    init() {
        let client = StravaClient()
        _stravaClient = State(initialValue: client)
        _library = State(initialValue: RunLibrary(stravaClient: client))
    }

    var body: some Scene {
#if os(macOS)
        WindowGroup {
            ContentView()
                .environment(stravaClient)
                .environment(library)
                .environment(visualisationModel)
                .player(player)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .onOpenURL { stravaClient.handleCallbackURL($0) }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "runimation"))

        Window("Customisation", id: "customisation") {
            CustomisationPanel()
                .environment(visualisationModel)
                .player(player)
        }
        .defaultSize(width: 320, height: 500)
        .defaultPosition(.trailing)
#else
        WindowGroup {
            ContentView()
                .environment(stravaClient)
                .environment(library)
                .environment(visualisationModel)
                .player(player)
        }
#endif
    }
}
