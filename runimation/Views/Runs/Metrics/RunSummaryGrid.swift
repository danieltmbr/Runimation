import SwiftUI
import RunKit
import RunUI

struct RunSummaryGrid: View {

    let run: Run

    var body: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                cell("Distance",  value: formattedDistance,  unit: "km")
                cell("Duration",  value: formattedDuration,  unit: "")
            }
            GridRow {
                cell("Avg Pace",  value: formattedAvgPace,   unit: "min/km")
                cell("Best Pace", value: formattedBestPace, unit: "min/km")
            }
            GridRow {
                cell("Avg HR",    value: formattedAvgHR,    unit: "bpm")
                cell("Elev. Gain", value: formattedElevGain, unit: "m")
            }
        }
    }

    private func cell(_ label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.monospacedDigit().weight(.semibold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed stats

    private var totalDistanceKm: Double { run.distance / 1000.0 }

    private var totalElevationGain: Double {
        let segs = run.segments
        return zip(segs, segs.dropFirst()).reduce(0) { total, pair in
            let delta = pair.1.elevation - pair.0.elevation
            return delta > 0 ? total + delta : total
        }
    }

    private var avgHeartRate: Double {
        let values = run.segments.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var formattedDistance: String { String(format: "%.2f", totalDistanceKm) }

    private var formattedDuration: String {
        let total = Int(run.duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedAvgPace: String {
        guard totalDistanceKm > 0 else { return "--:--" }
        let secsPerKm = run.duration / totalDistanceKm
        return secsPerKm.formatted(.pace)
        // return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }

    private var formattedElevGain: String { String(format: "%.0f", totalElevationGain) }

    private var formattedAvgHR: String { String(format: "%.0f", avgHeartRate) }

    private var formattedBestPace: String {
        let maxSpeed = run.spectrum.speed.upperBound
        guard maxSpeed > 0 else { return "--:--" }
        let secsPerKm = 1000.0 / maxSpeed
        return secsPerKm.formatted(.pace)
        // return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }
}
