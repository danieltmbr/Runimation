import SwiftUI

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
struct InterpolationPicker: View {

    @PlayerState(\.interpolatorOption)
    private var option

    var body: some View {
        Picker("Interpolation", selection: $option) {
            ForEach(RunInterpolatorOption.all) { opt in
                Text(opt.label).tag(opt)
            }
        }
    }
}
