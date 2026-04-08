import RunKit
import SwiftUI

/// Per-window observable model owning the `RunPlayer`, the `NowPlayingModel` bridge,
/// and all navigation state.
///
/// One instance is created per `PlayerWindow`. Views access it through
/// `@NavigationState` keypaths or via `@Environment(NavigationModel.self)`.
///
@MainActor
@Observable
final class NavigationModel: Equatable {

    static func == (lhs: NavigationModel, rhs: NavigationModel) -> Bool { lhs === rhs }


    // MARK: - Per-window Player

    let player: RunPlayer

    let nowPlaying: NowPlayingModel

    // MARK: - Window Config

    let autoRestore: Bool

    // MARK: - Navigation State

    var statsPath: [RunEntry] = []

    var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// Set after a `.runi` file open — triggers the save-to-library confirmation alert.
    ///
    var importedRecord: RunRecord?

    /// Set to trigger the export sheet for a specific run.
    ///
    var exportingRun: RunEntry?

    // MARK: - iOS-only Sheet State

    var showLibrary = false

    var showNowPlaying = false

    var showCustomisation = false

    var showFilePicker = false

    // MARK: - Init

    init(
        findRecord: @escaping @MainActor (RunEntry) -> RunRecord?,
        markAsPlaying: @escaping @MainActor (RunRecord) -> Void,
        autoRestore: Bool
    ) {
        self.player = RunPlayer(transformers: [GuassianRun()])
        self.autoRestore = autoRestore
        self.nowPlaying = NowPlayingModel(
            findRecord: findRecord,
            markAsPlaying: markAsPlaying
        )
    }
}
