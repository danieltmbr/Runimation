import SwiftUI

struct PlaybackControlsView: View {
    @Bindable var engine: PlaybackEngine

    var body: some View {
        VStack(spacing: 12) {
            // Preset picker
            Picker("Duration", selection: $engine.preset) {
                ForEach(PlaybackPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            // Play/Pause + Progress
            HStack(spacing: 16) {
                Button(action: {
                    engine.isPlaying ? engine.pause() : engine.play()
                }) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)

                if engine.preset == .realTime {
                    Slider(
                        value: Binding(
                            get: { engine.progress },
                            set: { engine.seek(to: $0) }
                        ),
                        in: 0...1
                    )
                } else {
                    ProgressView(value: engine.progress)
                }

                Button("Reset") {
                    engine.reset()
                }
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
        let targetDuration = engine.preset.targetDuration(
            forRunDuration: engine.runData.totalDuration
        )
        let elapsed = engine.progress * targetDuration
        return "\(Self.formatTime(elapsed)) / \(Self.formatTime(targetDuration))"
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
