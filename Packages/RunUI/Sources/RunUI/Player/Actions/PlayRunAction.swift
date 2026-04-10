import Foundation
import RunKit
import CoreKit

/// Sets a `Run` on the player and starts playback.
///
/// Inject via `.player(_:)` and call in views with:
/// ```swift
/// @Environment(\.playRun) private var playRun
/// try? await playRun(run)
/// ```
///
public struct PlayRunAction {

    private let action: @MainActor (Run) async throws -> Void

    public init() {
        action = { _ in throw UnboundError() }
    }

    @MainActor
    public init(player: RunPlayer) {
        action = { run in
            try await player.setRun(run)
            player.play()
        }
    }

    @MainActor
    public func callAsFunction(_ run: Run) async throws {
        try await action(run)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No run player or library is available in the current environment." }
    }
}
