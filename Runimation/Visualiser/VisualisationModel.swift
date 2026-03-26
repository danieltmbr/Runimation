import Visualiser
import Observation

/// Shared observable model holding the active `Visualisation`.
///
/// Injected into the environment so both the main window (visualiser canvas)
/// and the auxiliary Customisation Panel window can read and write the same state.
///
@MainActor
@Observable
final class VisualisationModel {
    var current: any Visualisation = Warp()
}
