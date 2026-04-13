import SwiftUI

public struct Gradients: Visualisation, Equatable, Sendable, Codable {
    
    public init() {}

    // MARK: - Option

    public var label: String { "Gradients" }

    public var description: String {
        "Creates a color gradient based on pace, elevation and heart rate."
    }

    // MARK: - FormAdjustable

    public func form(for binding: Binding<Gradients>) -> some View {
        EmptyView()
    }

    // MARK: - Visualisation

    public func canvas(state: VisualiserState, binding: Binding<Gradients>) -> some View {
        GradientsView(state: state)
    }
}
