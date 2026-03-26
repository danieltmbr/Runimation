import Foundation

/// Disconnects from the data source and removes remote entries from the library.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.disconnectLibrary) private var disconnect
/// disconnect()
/// ```
///
struct DisconnectAction {

    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { library.disconnect() }
    }

    @MainActor
    func callAsFunction() { body() }
}
