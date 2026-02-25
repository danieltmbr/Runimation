import SwiftUI

struct RunPlayerControlsView: View {

    @PlayerState(\.runs)
    private var runs
    
    @PlayerState(\.progress)
    private var progress
    
    @PlayerState(\.duration)
    private var duration

    var body: some View {
        VStack(spacing: 12) {
            DurationPicker()
                .pickerStyle(.segmented)

            HStack(spacing: 16) {
                PlayToggle()
                    .buttonStyle(.bordered)

                ProgressSlider()

                StopButton()
                    .buttonStyle(.bordered)
            }

            Text(timeLabel)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var timeLabel: String {
        guard let run = runs?.run(for: .metrics) else { return "0:00 / 0:00" }
        let targetDuration = duration(for: run.duration)
        let elapsed = progress * targetDuration
        return "\(Self.formatTime(elapsed)) / \(Self.formatTime(targetDuration))"
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
