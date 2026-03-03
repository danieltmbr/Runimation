import SwiftUI
import RunKit

// MARK: - FormAdjustable Conformance

extension GuassianRun: FormAdjustable {
    @MainActor
    public func form(for binding: Binding<GuassianRun>) -> AnyView {
        AnyView(GuassianRunForm(value: binding))
    }
}

// MARK: - Form View

/// Configuration form rows for `GuassianRun`.
/// Provides sliders for each Gaussian sigma value (in seconds).
///
struct GuassianRunForm: View {

    @Binding var value: GuassianRun

    var body: some View {
        LabeledContent("Speed: \(Int(value.configuration.speed))s") {
            Slider(value: speedBinding, in: 1...120, step: 1)
        }
        LabeledContent("Direction: \(Int(value.configuration.direction.x))s") {
            Slider(value: directionBinding, in: 1...120, step: 1)
        }
        LabeledContent("Heart Rate: \(Int(value.configuration.heartRate))s") {
            Slider(value: heartRateBinding, in: 1...120, step: 1)
        }
        LabeledContent("Elevation: \(Int(value.configuration.elevation))s") {
            Slider(value: elevationBinding, in: 1...120, step: 1)
        }
        LabeledContent("Elevation Rate: \(Int(value.configuration.elevationRate))s") {
            Slider(value: elevationRateBinding, in: 1...120, step: 1)
        }
    }

    // MARK: - Private

    private var speedBinding: Binding<Double> {
        Binding(
            get: { value.configuration.speed },
            set: {
                var config = value.configuration
                config.speed = $0
                value = GuassianRun(configuration: config)
            }
        )
    }

    private var directionBinding: Binding<Double> {
        Binding(
            get: { value.configuration.direction.x },
            set: {
                var config = value.configuration
                config.direction = CGPoint(x: $0, y: $0)
                value = GuassianRun(configuration: config)
            }
        )
    }

    private var heartRateBinding: Binding<Double> {
        Binding(
            get: { value.configuration.heartRate },
            set: {
                var config = value.configuration
                config.heartRate = $0
                value = GuassianRun(configuration: config)
            }
        )
    }

    private var elevationBinding: Binding<Double> {
        Binding(
            get: { value.configuration.elevation },
            set: {
                var config = value.configuration
                config.elevation = $0
                value = GuassianRun(configuration: config)
            }
        )
    }

    private var elevationRateBinding: Binding<Double> {
        Binding(
            get: { value.configuration.elevationRate },
            set: {
                var config = value.configuration
                config.elevationRate = $0
                value = GuassianRun(configuration: config)
            }
        )
    }
}
