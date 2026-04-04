import SwiftUI
import RunKit
import RunUI

struct RunSummaryGrid: View {

    let run: Run

    var body: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                cell("Distance",   value: run.distance.formatted(.distance))
                cell("Duration",   value: run.duration.formatted(.runDuration))
            }
            GridRow {
                cell("Avg Pace",   value: avgSpeed.formatted(.pace))
                cell("Best Pace",  value: run.spectrum.speed.upperBound.formatted(.pace))
            }
            GridRow {
                cell("Avg HR",     value: avgHeartRate.formatted(.heartRate))
                cell("Elev. Gain", value: elevationGain.formatted(.elevation))
            }
        }
    }

    private func cell(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed stats

    private var avgSpeed: Double {
        guard run.duration > 0 else { return 0 }
        return run.distance / run.duration
    }

    private var avgHeartRate: Double {
        let values = run.segments.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var elevationGain: Double {
        let segs = run.segments
        return zip(segs, segs.dropFirst()).reduce(0) { total, pair in
            let delta = pair.1.elevation - pair.0.elevation
            return delta > 0 ? total + delta : total
        }
    }
}
