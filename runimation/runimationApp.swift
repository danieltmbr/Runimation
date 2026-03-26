import StravaKit
import SwiftUI

@main
struct RunimationApp: App {

    @State private var stravaClient: StravaClient
    
    @State private var library: RunLibrary

    init() {
        let client = StravaClient()
        _stravaClient = State(initialValue: client)
        _library = State(initialValue: RunLibrary(stravaClient: client))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stravaClient)
                .environment(library)
#if os(macOS)
                .toolbarBackgroundVisibility(
                    .hidden, for: .windowToolbar
                )
                .onOpenURL { stravaClient.handleCallbackURL($0) }
#endif
        }
#if os(macOS)
        .handlesExternalEvents(matching: Set(arrayLiteral: "runimation"))
#endif
    }
}
