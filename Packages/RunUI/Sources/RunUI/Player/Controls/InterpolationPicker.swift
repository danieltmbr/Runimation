import SwiftUI
import RunKit

/// A picker that reflects and controls the player's active interpolation strategy.
///
/// Reads the current selection via `@PlayerState` and writes back through
/// the same binding. Apply `.pickerStyle()` at the call-site to control
/// how it renders:
///
/// ```swift
/// InterpolationPicker()
///     .pickerStyle(.segmented)
/// ```
///
public struct InterpolationPicker: View {

    @PlayerState(\.interpolator)
    private var option

    public var body: some View {
        Picker("Interpolation", selection: $option) {
            ForEach(RunInterpolatorOption.all) { opt in
                Text(opt.label).tag(opt)
            }
        }
    }
}
