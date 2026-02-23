import Charts
import SwiftUI

struct RunMetricsView: View {
    let engine: PlaybackEngine

    private var runData: RunData { engine.runData }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryGrid
                    chartSection("Pace", unit: "min/km") { paceChart }
                    chartSection("Elevation", unit: "m") { elevationChart }
                    chartSection("Heart Rate", unit: "bpm") { heartRateChart }
                }
                .padding()
            }
            PlaybackControlsView(engine: engine)
        }
    }

    // MARK: - Summary

    private var summaryGrid: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                summaryCell("Distance", value: formattedDistance, unit: "km")
                summaryCell("Duration", value: formattedDuration, unit: "")
            }
            GridRow {
                summaryCell("Avg Pace", value: formattedAvgPace, unit: "min/km")
                summaryCell("Elev. Gain", value: formattedElevGain, unit: "m")
            }
            GridRow {
                summaryCell("Avg HR", value: formattedAvgHR, unit: "bpm")
                summaryCell("Max Speed", value: String(format: "%.1f", runData.maxSpeed * 3.6), unit: "km/h")
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func summaryCell(_ label: String, value: String, unit: String) -> some View {
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

    // MARK: - Charts

    @ViewBuilder
    private func chartSection<C: View>(
        _ title: String,
        unit: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title) (\(unit))")
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .frame(height: 150)
        }
    }

    private var playheadMinutes: Double {
        engine.progress * runData.totalDuration / 60.0
    }

    private var paceChart: some View {
        let segments = paceSegments

        // Pace domain from actual running samples (speed > 1.0 m/s).
        let runningSpeeds = runData.samples.filter { $0.speed > 1.0 }.map { $0.speed }
        let maxSpeed = runningSpeeds.max() ?? 3.0
        let minSpeed = runningSpeeds.min() ?? 1.5
        let fastestPace = 1000.0 / (maxSpeed * 60.0) // min/km, numerically smallest
        let slowestPace = 1000.0 / (minSpeed * 60.0) // min/km, numerically largest
        let margin = (slowestPace - fastestPace) * 0.05
        // Values are negated on the chart, so fast (small pace) → least-negative (top).
        let domainCeil  = -(fastestPace - margin)
        let domainFloor = -(slowestPace + margin)

        return Chart {
            // Use LineMark with per-segment series so the line breaks across pauses.
            // AreaMark can't break series, so pace is line-only.
            ForEach(Array(segments.enumerated()), id: \.offset) { segIdx, segment in
                ForEach(segment, id: \.self) { i in
                    let s = runData.samples[i]
                    // Negate pace so faster (lower min/km) plots higher on the chart.
                    let pace = -(1000.0 / (s.speed * 60.0))
                    LineMark(
                        x: .value("min", s.timeOffset / 60.0),
                        y: .value("min/km", pace),
                        series: .value("Seg", segIdx)
                    )
                    .foregroundStyle(.blue)
                }
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...(runData.totalDuration / 60.0))
        .chartYScale(domain: domainFloor...domainCeil)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                if let negPace = value.as(Double.self) {
                    // Values are negated, so flip back to get the real pace for display.
                    let total = Int(-negPace * 60)
                    AxisValueLabel {
                        Text(String(format: "%d:%02d", total / 60, total % 60))
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                AxisGridLine()
            }
        }
    }

    /// Samples grouped into continuous running segments.
    /// A new segment starts when there is a >60 s gap (pause/walk) or speed drops
    /// below 1.0 m/s (~16 min/km). This prevents LineMark from connecting across pauses.
    private var paceSegments: [[Int]] {
        let moving = sampledIndices.filter { runData.samples[$0].speed > 1.0 }
        var segments: [[Int]] = []
        var current: [Int] = []
        var prevTime: Double = -.infinity
        for idx in moving {
            let t = runData.samples[idx].timeOffset
            if t - prevTime > 60, !current.isEmpty {
                segments.append(current)
                current = []
            }
            current.append(idx)
            prevTime = t
        }
        if !current.isEmpty { segments.append(current) }
        return segments
    }

    private var elevationChart: some View {
        let domainFloor = runData.minElevation - 5
        let domainCeil  = runData.maxElevation + 5
        return Chart {
            ForEach(sampledIndices, id: \.self) { i in
                let s = runData.samples[i]
                AreaMark(
                    x: .value("min", s.timeOffset / 60.0),
                    yStart: .value("m", domainFloor),
                    yEnd: .value("m", s.elevation)
                )
                .foregroundStyle(.green.opacity(0.2))
                LineMark(
                    x: .value("min", s.timeOffset / 60.0),
                    y: .value("m", s.elevation)
                )
                .foregroundStyle(.green)
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...(runData.totalDuration / 60.0))
        .chartYScale(domain: domainFloor...domainCeil)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                if let v = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.0f", v))
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                AxisGridLine()
            }
        }
    }

    private var heartRateChart: some View {
        let hrIndices = sampledIndices.filter { runData.samples[$0].heartRate > 0 }
        let domainFloor = runData.minHeartRate - 10
        return Chart {
            ForEach(hrIndices, id: \.self) { i in
                let s = runData.samples[i]
                // yStart = domain floor so the fill uses the full chart height,
                // not y=0 which would push all the data into a thin top sliver.
                AreaMark(
                    x: .value("min", s.timeOffset / 60.0),
                    yStart: .value("bpm", domainFloor),
                    yEnd: .value("bpm", s.heartRate)
                )
                .foregroundStyle(.red.opacity(0.2))
                LineMark(
                    x: .value("min", s.timeOffset / 60.0),
                    y: .value("bpm", s.heartRate)
                )
                .foregroundStyle(.red)
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...(runData.totalDuration / 60.0))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxisLabel("minutes", alignment: .trailing)
        .chartYScale(domain: (runData.minHeartRate - 10)...(runData.maxHeartRate + 10))
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                if let v = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.0f", v))
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                AxisGridLine()
            }
        }
    }

    // MARK: - Data helpers

    /// Downsampled index list — at most 500 points per chart for performance.
    private var sampledIndices: [Int] {
        let step = max(1, runData.samples.count / 500)
        return Array(Swift.stride(from: 0, to: runData.samples.count, by: step))
    }

    // MARK: - Computed stats

    private var totalDistanceKm: Double {
        let s = runData.samples
        var dist = 0.0
        for i in 1..<s.count {
            dist += s[i - 1].speed * (s[i].timeOffset - s[i - 1].timeOffset)
        }
        return dist / 1000.0
    }

    private var totalElevationGain: Double {
        let s = runData.samples
        var gain = 0.0
        for i in 1..<s.count {
            let delta = s[i].elevation - s[i - 1].elevation
            if delta > 0 { gain += delta }
        }
        return gain
    }

    private var avgHeartRate: Double {
        let values = runData.samples.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var formattedDistance: String { String(format: "%.2f", totalDistanceKm) }

    private var formattedDuration: String {
        let total = Int(runData.totalDuration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedAvgPace: String {
        guard totalDistanceKm > 0 else { return "--:--" }
        let secsPerKm = runData.totalDuration / totalDistanceKm
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }

    private var formattedElevGain: String { String(format: "%.0f", totalElevationGain) }
    private var formattedAvgHR: String { String(format: "%.0f", avgHeartRate) }
}
