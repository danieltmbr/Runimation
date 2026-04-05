import SwiftUI

// MARK: - FocusedValue Key

private struct NavigationModelKey: FocusedValueKey {
    typealias Value = NavigationModel
}

// MARK: - FocusedValues Extension

/// Makes the focused window's `NavigationModel` available across scenes.
///
/// Set by `RuniWindow` via `.focusedSceneValue(\.navigationModel, navigationModel)`.
/// Read by `CustomisationWindow` via `@FocusedValue(\.navigationModel)` to track
/// whichever player window is currently focused.
///
extension FocusedValues {
    var navigationModel: NavigationModel? {
        get { self[NavigationModelKey.self] }
        set { self[NavigationModelKey.self] = newValue }
    }
}
