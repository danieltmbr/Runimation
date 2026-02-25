import SwiftUI

struct RunPlayerControlsView: View {
    @Bindable var player: RunPlayer

    var body: some View {
        VStack(spacing: 12) {
            Picker("Duration", selection: $player.duration) {
                ForEach(RunPlayer.Duration.all) { d in
                    Text(d.label).tag(d)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                Button(action: {
                    player.isPlaying ? player.pause() : player.play()
                }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)

                Slider(
                    value: Binding(
                        get: { player.progress },
                        set: { player.seek(to: $0) }
                    ),
                    in: 0...1
                )

                Button("Stop") { player.stop() }
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
        guard let run = player.runs?.run(for: .metrics) else { return "0:00 / 0:00" }
        let targetDuration = player.duration(for: run.duration)
        let elapsed = player.progress * targetDuration
        return "\(Self.formatTime(elapsed)) / \(Self.formatTime(targetDuration))"
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
