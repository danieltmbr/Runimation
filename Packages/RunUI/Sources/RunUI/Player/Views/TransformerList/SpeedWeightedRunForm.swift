import SwiftUI
import RunKit

// MARK: - FormAdjustable Conformance

extension SpeedWeightedRun: FormAdjustable {
    @MainActor
    public func form(for binding: Binding<SpeedWeightedRun>) -> AnyView {
        AnyView(SpeedWeightedRunForm(value: binding))
    }
}

// MARK: - Form View

/// Configuration form rows for `SpeedWeightedRun`.
/// Provides a slider for the speed threshold (m/s) below which
/// direction amplitude fades toward zero.
///
struct SpeedWeightedRunForm: View {

    @Binding var value: SpeedWeightedRun

    var body: some View {
        LabeledContent("Threshold: \(value.configuration.threshold, format: .number.precision(.fractionLength(1))) m/s") {
            Slider(value: thresholdBinding, in: 0...5, step: 0.1)
        }
    }

    // MARK: - Private

    private var thresholdBinding: Binding<Double> {
        Binding(
            get: { value.configuration.threshold },
            set: { value = SpeedWeightedRun(configuration: .init(threshold: $0)) }
        )
    }
}
