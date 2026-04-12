import SwiftUI

public struct Colors: Visualisation, Equatable, Sendable, Codable {
    
    public init() {}

    // MARK: - Option

    public var label: String { "Colors" }

    public var description: String {
        "Creates a color gradient based on pace, elevation and heart rate."
    }

    // MARK: - FormAdjustable

    public func form(for binding: Binding<Colors>) -> some View {
        EmptyView()
    }

    // MARK: - Visualisation

    public func canvas(state: VisualiserState, binding: Binding<Colors>) -> some View {
        ColorsView(state: state)
    }
}
