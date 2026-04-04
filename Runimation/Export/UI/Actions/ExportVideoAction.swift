import Foundation
import RunKit
import Visualiser

/// Renders the current run's visualisation to an `.mp4` file and returns its URL.
///
/// Snapshots the player's processed run data on the main actor, then dispatches the
/// render loop to a background task so the UI stays responsive.
///
/// Inject via `.export(player:)` and access in views with:
/// ```swift
/// @Environment(\.exportVideo) private var exportVideo
/// let url = try await exportVideo(record, config) { progress in ... }
/// ```
///
struct ExportVideoAction {

    typealias ProgressHandler = @Sendable (Double) -> Void

    private let body: @MainActor (RunRecord, VideoExportConfig, @escaping ProgressHandler) async throws -> URL

    init(_ body: @escaping @MainActor (RunRecord, VideoExportConfig, @escaping ProgressHandler) async throws -> URL) {
        self.body = body
    }

    init() {
        self.init { _, _, _ in throw UnboundError() }
    }

    @MainActor
    init(player: RunPlayer) {
        self.init { record, config, onProgress in
            // Snapshot player data on the main actor before dispatching to background.
            let segments = player.run.animation.segments
            let path = player.run.animation.coordinates
            let duration = player.duration
            let visualisation = record.loadVisualisationConfig() ?? Warp()

            return try await Task.detached(priority: .userInitiated) {
                try await VideoRenderer().render(
                    segments: segments,
                    path: path,
                    duration: duration,
                    config: config,
                    visualisation: visualisation,
                    onProgress: onProgress
                )
            }.value
        }
    }

    @MainActor
    func callAsFunction(
        _ record: RunRecord,
        config: VideoExportConfig,
        onProgress: @escaping ProgressHandler
    ) async throws -> URL {
        try await body(record, config, onProgress)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No export action is available in the current environment." }
    }
}
