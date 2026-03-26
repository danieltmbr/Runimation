import AuthenticationServices
import SwiftUI

/// A reusable button that initiates the data source connection flow.
///
/// Resolves the `ASPresentationAnchor` internally on iOS so callers
/// don't need to manage platform differences.
///
/// Requires `.library(_:player:)` in the view hierarchy.
///
struct ConnectButton: View {

    @Environment(\.connectLibrary)
    private var connect

    var body: some View {
        Button("Connect to Strava") {
            connect(from: presentationAnchor)
        }
    }

    private var presentationAnchor: ASPresentationAnchor? {
        #if os(macOS)
        nil
        #else
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        #endif
    }
}
