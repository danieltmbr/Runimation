import StravaKit
import SwiftUI

@main
struct RunimationApp: App {

    @State private var stravaClient = StravaClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stravaClient)
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
