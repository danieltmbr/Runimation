import Foundation
import RunKit
import Visualiser

/// Renders a run's animation to an `.mp4` file, fully independent of the player.
///
/// Resolves the entry to its `RunRecord`, loads track data if not yet present,
/// reconstructs the transformer + interpolator pipeline from stored config, and
/// renders via `VideoRenderer`. Safe to call for any run, including Strava runs
/// that have never been played.
///
/// Inject via `.export(library:)` and access in views with:
/// ```swift
/// @Environment(\.exportVideo) private var exportVideo
/// let url = try await exportVideo(entry, config: config) { progress in ... }
/// ```
///
struct ExportVideoAction {

    typealias ProgressHandler = @Sendable (Double) -> Void

    private let body: @MainActor (RunEntry, VideoExportConfig, @escaping ProgressHandler) async throws -> URL

    init(_ body: @escaping @MainActor (RunEntry, VideoExportConfig, @escaping ProgressHandler) async throws -> URL) {
        self.body = body
    }

    init() {
        self.init { _, _, _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { entry, config, onProgress in
            guard let record = library.record(for: entry) else { throw ResolutionError() }
            let rawRun = try await library.loadRun(for: record)

            let transformers = record.loadTransformersConfig()
            let interpolator = record.loadInterpolatorConfig() ?? LinearRunInterpolator()
            let duration = record.loadDurationConfig() ?? 30
            let visualisation = record.loadVisualisationConfig() ?? Warp()
            let timing = RunPlayer.Timing(duration: duration, fps: 30)

            let processed = transformers.reduce(rawRun) { $0.transform(by: $1) }
            let normalised = processed
                .transform(by: .normalised)
                .interpolate(by: interpolator, with: timing)

            return try await Task.detached(priority: .userInitiated) {
                try await VideoRenderer().render(
                    segments: normalised.segments,
                    path: normalised.coordinates,
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
        _ entry: RunEntry,
        config: VideoExportConfig,
        onProgress: @escaping ProgressHandler
    ) async throws -> URL {
        try await body(entry, config, onProgress)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No export action is available in the current environment." }
    }

    private struct ResolutionError: LocalizedError {
        var errorDescription: String? { "The run could not be found in the library." }
    }
}
