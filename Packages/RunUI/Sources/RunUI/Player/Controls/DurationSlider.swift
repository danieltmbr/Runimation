import RunKit
import SwiftUI

/// A slider for adjusting the animation playback duration.
///
/// Maps between slider position [0, 1] and playback seconds using
/// `PlaybackDurationMapping`: linear from 5 s to 60 s, then exponential
/// up to the run's actual recorded duration.
///
/// Shows labeled tick marks at the standard presets (15 s, 30 s, 60 s)
/// and a "Real" tick at position 1.0 (the run's actual duration). The
/// current selected value is displayed above the slider track.
///
/// Updating `player.duration` is immediate (for live playback feedback);
/// the run is only reprocessed when the user finishes dragging.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct DurationSlider: View {

    @Player(\.duration)
    private var duration

    @Player(\.run.metrics)
    private var run

    @Environment(\.setDuration)
    private var setDuration

    public init() {}

    public var body: some View {
        let mapping = PlaybackDurationMapping(runDuration: run.duration)
        let allTicks = mapping.tickPositions + [1.0]
        let positionBinding = Binding<Double>(
            get: { mapping.position(for: duration) },
            set: { position in duration = mapping.seconds(at: position) }
        )
        VStack(alignment: .leading, spacing: 4) {
            Text(duration.formatted(.runDuration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Slider(value: positionBinding, in: 0.0...1.0) {
                EmptyView()
            } currentValueLabel: {
                Text(duration.formatted(.runDuration))
            } ticks: {
                SliderTickContentForEach(allTicks, id: \.self) { position in
                    SliderTick(Self.tickLabel(position: position, mapping: mapping), position)
                }
            } onEditingChanged: { isEditing in
                if !isEditing {
                    Task { try? await setDuration(duration) }
                }
            }
        }
    }

    // MARK: - Private

    private static func tickLabel(position: Double, mapping: PlaybackDurationMapping) -> String {
        if position >= 1.0 { return "Real Time" }
        let seconds = mapping.seconds(at: position)
        if seconds < 60 { return "\(Int(seconds.rounded()))s" }
        let m = Int(seconds / 60)
        let s = Int(seconds.truncatingRemainder(dividingBy: 60))
        return s > 0 ? "\(m)m \(s)s" : "\(m)m"
    }
}
