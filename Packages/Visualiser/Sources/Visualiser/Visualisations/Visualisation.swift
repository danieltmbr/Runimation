import SwiftUI
import CoreKit
import CoreUI

/// Identifies a GPU canvas visualisation and its user-configurable parameters.
///
/// Each conforming type is fully isolated — it holds only its own configuration
/// and produces its own canvas view and inspector form. Runtime dispatch between
/// visualisation types is localised to `VisualiserCanvas`.
///
/// To add a new visualisation:
/// 1. Create a struct conforming to `Visualisation`.
/// 2. Add the type to `VisualisationPicker.catalog`.
///
public protocol Visualisation: Option, FormAdjustable, Sendable {
    associatedtype Canvas: View
    @MainActor
    func canvas(state: VisualiserState, binding: Binding<Self>) -> Canvas
}
