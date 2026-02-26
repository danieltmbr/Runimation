import SwiftUI

struct RunPlayerStatsOverlay: View {

    @PlayerState(\.segments.metrics)
    private var segment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let segment {
                statRow(
                    "Pace",
                    value: pace(speed: segment.speed),
                    unit: "min/km"
                )
                statRow(
                    "Elevation",
                    value: String(format: "%.0f", segment.elevation),
                    unit: "m"
                )
                statRow(
                    "Heart Rate",
                    value: String(format: "%.0f", segment.heartRate),
                    unit: "bpm"
                )
            }
        }
        .font(.caption)
        .monospacedDigit()
        .padding(8)
        .padding(12)
    }

    private func statRow(_ label: String, value: String, unit: String) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium).frame(minWidth: 36, alignment: .trailing)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func pace(speed: Double) -> String {
        guard speed > 0.3 else { return "--:--" }
        let secsPerKm = 1000.0 / speed
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }
}
