import SwiftUI
import CoreKit
import CoreUI

/// User-configurable parameters for the domain warp animation.
///
/// Conforms to `FormAdjustable` so the inspector can render its controls
/// via `AdjustableForm(value: $warp)` without knowing the concrete type.
///
/// See: [Domain Warping – Inigo Quilez](https://iquilezles.org/articles/warp/)
///
public struct Warp: Option, FormAdjustable, Sendable {

    /// Shader H parameter offset — controls global smoothness (0–1).
    public var smoothness: Double

    /// fBM octave count — controls detail level (1–12).
    public var details: Double

    public var label: String { "Domain Warp" }

    public var description: String {
        """
        Domain-warped fractional Brownian motion driven by run metrics.
        
        Check out [Domain Warping – Inigo Quilez](iquilezles.org/articles/warp) for more.
        """
    }

    public init(
        smoothness: Double = 0.8,
        details: Double = 5.0
    ) {
        self.smoothness = smoothness
        self.details = details
    }

    @MainActor
    public func form(for binding: Binding<Warp>) -> AnyView {
        AnyView(WarpForm(value: binding))
    }
}

// MARK: - Form View

/// Configuration sliders for `Warp` shown via `AdjustableForm`.
///
private struct WarpForm: View {

    @Binding var value: Warp

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Smoothing")
                    .font(.caption)
                Slider(value: $value.smoothness, in: 0...1)
            }
            VStack(alignment: .leading) {
                Text("Details")
                    .font(.caption)
                Slider(value: $value.details, in: 1...12, step: 1)
            }
        }
        .padding()
    }
}
