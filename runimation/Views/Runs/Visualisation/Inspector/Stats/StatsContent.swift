import SwiftUI

struct StatsContent: View {

    @PlayerState(\.segment.metrics)
    private var segment

    var body: some View {
        HStack(spacing: 0) {
            statCell(
                label: "PACE",
                value: pace(speed: segment.speed),
                unit: "min/km"
            )
            Divider().frame(height: 56)
            statCell(
                label: "ELEVATION",
                value: String(format: "%.0f", segment.elevation),
                unit: "m"
            )
            Divider().frame(height: 56)
            statCell(
                label: "HR",
                value: String(format: "%.0f", segment.heartRate),
                unit: "bpm"
            )
        }
        .padding(.vertical, 28)
        .padding(.horizontal)
    }

    private func statCell(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .kerning(0.5)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func pace(speed: Double) -> String {
        guard speed > 0.3 else { return "--:--" }
        let secsPerKm = 1000.0 / speed
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }
}
