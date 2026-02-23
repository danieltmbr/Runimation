import SwiftUI

struct RunStatsOverlay: View {
    let engine: PlaybackEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow("Pace", value: paceMinKm, unit: "min/km")
            statRow("Elevation", value: elevationMeters, unit: "m")
            statRow("Heart Rate", value: heartRateBpm, unit: "bpm")
        }
        .font(.caption)
        .monospacedDigit()
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
    }

    private func statRow(_ label: String, value: String, unit: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
                .frame(minWidth: 36, alignment: .trailing)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    private var paceMinKm: String {
        // Denormalize: speed 0..1 maps to 0..maxSpeed (m/s), convert to min/km
        let ms = Double(engine.currentSpeed) * engine.runData.maxSpeed
        guard ms > 0.3 else { return "--:--" } // below ~0.3 m/s treat as stationary
        let paceSeconds = 1000.0 / ms // seconds per km
        let mins = Int(paceSeconds) / 60
        let secs = Int(paceSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var elevationMeters: String {
        let range = engine.runData.maxElevation - engine.runData.minElevation
        let ele = engine.runData.minElevation + Double(engine.currentElevation) * range
        return String(format: "%.0f", ele)
    }

    private var heartRateBpm: String {
        let range = engine.runData.maxHeartRate - engine.runData.minHeartRate
        let hr = engine.runData.minHeartRate + Double(engine.currentHeartRate) * range
        return String(format: "%.0f", hr)
    }
}
