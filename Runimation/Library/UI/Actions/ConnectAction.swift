import AuthenticationServices
import Foundation

/// Initiates the data source connection flow (currently Strava OAuth).
///
/// On iOS, pass a presentation anchor for the authentication session.
/// On macOS, the anchor is ignored — the system browser is used instead.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.connectLibrary) private var connect
/// connect(from: anchor)   // iOS
/// connect()               // macOS
/// ```
///
struct ConnectAction {

    private let body: @MainActor (ASPresentationAnchor?) -> Void

    init(_ body: @escaping @MainActor (ASPresentationAnchor?) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { anchor in
            Task { try? await library.connect(from: anchor) }
        }
    }

    @MainActor
    func callAsFunction(from anchor: ASPresentationAnchor? = nil) {
        body(anchor)
    }
}
