import Foundation

/// Disconnects from the data source, optionally removing remote entries.
///
/// Pass `keepRuns: true` to sign out while preserving Strava runs in the
/// library, or `keepRuns: false` to sign out and delete them.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.disconnectLibrary) private var disconnect
/// disconnect(keepRuns: true)
/// ```
///
struct DisconnectAction {

    private let body: @MainActor (Bool) -> Void

    init(_ body: @escaping @MainActor (Bool) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { library.disconnect(keepRuns: $0) }
    }

    @MainActor
    func callAsFunction(keepRuns: Bool) { body(keepRuns) }
}
