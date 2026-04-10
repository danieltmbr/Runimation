import RunKit
import SwiftData
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

    var statsPath: [RunItem] = []

    var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// Set after a `.runi` file is opened — triggers the save-to-library confirmation alert.
    ///
    var importedItem: RunItem?

    /// Set to trigger the export sheet for a specific run.
    ///
    var exportingRun: RunItem?

    // MARK: - iOS-only Sheet State

    var showLibrary = false

    var showNowPlaying = false

    var showCustomisation = false

    var showFilePicker = false

    // MARK: - Init

    init(
        context: ModelContext,
        markAsPlaying: @escaping @MainActor (RunID) -> Void,
        autoRestore: Bool
    ) {
        self.player = RunPlayer(transformers: [GuassianRun()])
        self.autoRestore = autoRestore
        self.nowPlaying = NowPlayingModel(
            context: context,
            markAsPlaying: markAsPlaying
        )
    }
}
