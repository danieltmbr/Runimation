import SwiftUI
import RunKit

/// The data passed from `ProgressSlider` to its active style.
///
/// `progress` is a binding to the resolved display value — frozen at the drag
/// position while the user is interacting, tracking the player otherwise.
/// Writing to it signals that a drag is in progress. `seek` commits the final
/// position and clears the frozen state.
///
@MainActor
public struct ProgressSliderStyleConfiguration {

    /// Normalised playback position in `[0, 1]`, frozen during drag.
    /// Write to signal drag progress; call `seek` to commit.
    ///
    let progress: Binding<Double>

    /// Seeks to the given normalised position and unfreezes the display.
    ///
    let seek: @MainActor (Double) -> Void
}

// MARK: - Style Protocol

public protocol ProgressSliderStyle: Sendable {
    
    typealias Configuration = ProgressSliderStyleConfiguration
    
    associatedtype Body: View
    
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

// MARK: - Built-in Style Accessors

public extension ProgressSliderStyle where Self == SystemProgressSliderStyle {
    static var system: SystemProgressSliderStyle { .init() }
}

public extension ProgressSliderStyle where Self == MinimalProgressSliderStyle {
    static var minimal: MinimalProgressSliderStyle { .init() }
}
