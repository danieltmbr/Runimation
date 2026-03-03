import SwiftUI
import CoreUI
import RunKit

// MARK: - FormAdjustable Conformance

extension WaveSamplingTransformer: FormAdjustable {
    @MainActor
    public func form(for binding: Binding<WaveSamplingTransformer>) -> AnyView {
        AnyView(WaveSamplingTransformerForm(value: binding))
    }
}

// MARK: - Form View

/// Configuration form rows for `WaveSamplingTransformer`.
/// Provides sliders for `targetCount` and `rank`.
///
struct WaveSamplingTransformerForm: View {

    @Binding var value: WaveSamplingTransformer

    var body: some View {
        LabeledContent("Target Count: \(value.targetCount)") {
            Slider(value: targetCountBinding, in: 5...100, step: 1)
        }
        LabeledContent("Rank: \(value.rank)") {
            Slider(value: rankBinding, in: 1...10, step: 1)
        }
    }

    // MARK: - Private

    private var targetCountBinding: Binding<Double> {
        Binding(
            get: { Double(value.targetCount) },
            set: { value = WaveSamplingTransformer(targetCount: Int($0), rank: value.rank) }
        )
    }

    private var rankBinding: Binding<Double> {
        Binding(
            get: { Double(value.rank) },
            set: { value = WaveSamplingTransformer(targetCount: value.targetCount, rank: Int($0)) }
        )
    }
}
