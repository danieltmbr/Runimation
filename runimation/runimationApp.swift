import RunKit
import RunUI
import StravaKit
import SwiftData
import SwiftUI

@main
struct RunimationApp: App {

    @State private var player = RunPlayer(transformers: [GuassianRun()])

    @State private var stravaClient: StravaClient

    @State private var library: RunLibrary

    private let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: RunRecord.self)
        modelContainer = container
        let client = StravaClient()
        _stravaClient = State(initialValue: client)
        _library = State(initialValue: RunLibrary(stravaClient: client, modelContext: container.mainContext))
    }

    var body: some Scene {
#if os(macOS)
        WindowGroup {
            ContentView()
                .environment(stravaClient)
                .environment(library)
                .player(player)
                .library(library)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .windowToolbarFullScreenVisibility(.onHover)
                .onOpenURL { stravaClient.handleCallbackURL($0) }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "runimation"))

        UtilityWindow("Customisation", id: "customisation") {
            VStack {
                CustomisationPanel()
                    .padding()
                    .player(player)
                    .library(library)

                Spacer()
            }
            .background(.thinMaterial)
            .containerBackground(.clear, for: .window)
        }
        .defaultSize(width: 240, height: 300)
        .defaultPosition(.trailing)
#else
        WindowGroup {
            ContentView()
                .environment(stravaClient)
                .environment(library)
                .player(player)
                .library(library)
        }
#endif
    }
}
