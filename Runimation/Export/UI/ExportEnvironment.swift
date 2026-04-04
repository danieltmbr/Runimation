import RunKit
import SwiftUI

// MARK: - Environment Keys

extension EnvironmentValues {

    @Entry
    var exportRuni: ExportRuniAction = ExportRuniAction()

    @Entry
    var exportVideo: ExportVideoAction = ExportVideoAction()
}

// MARK: - View Extension

extension View {

    /// Injects export actions into the environment, making them available to
    /// any descendant view via `@Environment(\.exportRuni)` and `@Environment(\.exportVideo)`.
    ///
    /// Apply once near the root, after `.player(_:)`:
    /// ```swift
    /// ContentView()
    ///     .player(player)
    ///     .export(player: player)
    /// ```
    ///
    @MainActor
    func export(player: RunPlayer) -> some View {
        environment(\.exportVideo, ExportVideoAction(player: player))
    }
}
