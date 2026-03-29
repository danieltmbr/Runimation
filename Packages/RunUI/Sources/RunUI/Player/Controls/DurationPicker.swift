import RunKit
import SwiftUI

/// A compact duration control that shows the current playback duration and
/// opens a `DurationSlider` popover when tapped.
///
/// Displays a timer icon alongside the formatted duration (e.g. "0:30").
/// Tapping reveals a full `DurationSlider` — a non-linear slider with tick
/// marks at the standard presets — as a popover anchored to this view.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct DurationPicker: View {

    @PlayerState(\.duration)
    private var duration

    @State
    private var isPresented = false

    public init() {}

    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label(duration.formatted(.runDuration), systemImage: "timer")
        }
        .popover(isPresented: $isPresented) {
            DurationSlider()
                .padding()
                .frame(minWidth: 240, maxWidth: .infinity)
                .presentationCompactAdaptation(.popover)
        }
    }
}
