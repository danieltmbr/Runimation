import RunKit
import SwiftData
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
    /// Both actions are fully independent of the player — they resolve the run,
    /// load track data if missing, and reconstruct the processing pipeline from
    /// the record's stored config.
    ///
    /// Apply once near the root, after `.library(_:modelContext:)`:
    /// ```swift
    /// RuniWindow(...)
    ///     .library(library, modelContext: modelContainer.mainContext)
    ///     .export(library: library, modelContext: modelContainer.mainContext)
    /// ```
    ///
    @MainActor
    func export(library: RunLibrary, modelContext: ModelContext) -> some View {
        environment(\.exportRuni, ExportRuniAction(library: library, modelContext: modelContext))
            .environment(\.exportVideo, ExportVideoAction(library: library, modelContext: modelContext))
    }
}
