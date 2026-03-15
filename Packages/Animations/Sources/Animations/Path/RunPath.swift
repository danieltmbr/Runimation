import SwiftUI

/// GPS path animation — no user-configurable parameters.
///
/// Renders the run's GPS coordinates as an SDF line with warp distortion
/// via `RunPathView`. The form is empty since there is nothing to configure.
///
public struct RunPath: Visualisation, Equatable, Sendable {

    public init() {}

    // MARK: - Option

    public var label: String { "Run Path" }

    public var description: String {
        "GPS run path rendered as an SDF line with warp distortion."
    }

    // MARK: - FormAdjustable

    public func form(for binding: Binding<RunPath>) -> some View {
        EmptyView()
    }

    // MARK: - Visualisation

    public func canvas(state: AnimationState, binding: Binding<RunPath>) -> some View {
        RunPathView(state: state)
    }
}
