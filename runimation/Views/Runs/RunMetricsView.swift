import Charts
import SwiftUI

struct RunMetricsView: View {
    let player: RunPlayer

    private var run: Run? { player.runs?.run(for: .metrics) }

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
            RunPlayerControlsView(player: player)
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
                summaryCell("Max Speed", value: String(format: "%.1f", (run?.spectrum.speed.upperBound ?? 0) * 3.6), unit: "km/h")
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
        player.progress * (run?.duration ?? 0) / 60.0
    }

    private var totalDurationMinutes: Double {
        (run?.duration ?? 0) / 60.0
    }

    private var paceChart: some View {
        let movingSegments = chartSegments.filter { $0.speed > 1.0 }
        // Derive pace domain from the moving segments we'll actually plot.
        let speeds = movingSegments.map { $0.speed }
        let maxSpeed = speeds.max() ?? run?.spectrum.speed.upperBound ?? 3.0
        let minSpeed = speeds.min() ?? 1.5
        let fastestPace = 1000.0 / (maxSpeed * 60.0)
        let slowestPace  = 1000.0 / (minSpeed * 60.0)
        let margin = (slowestPace - fastestPace) * 0.05
        // Negate so faster pace (lower min/km) plots higher on the chart.
        let domainCeil  = -(fastestPace - margin)
        let domainFloor = -(slowestPace + margin)

        return Chart {
            ForEach(Array(movingSegments.enumerated()), id: \.offset) { _, segment in
                LineMark(
                    x: .value("min", minutes(of: segment)),
                    y: .value("min/km", -(1000.0 / (segment.speed * 60.0)))
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...max(totalDurationMinutes, 1))
        .chartYScale(domain: domainFloor...domainCeil)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                if let negPace = value.as(Double.self) {
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

    private var elevationChart: some View {
        let domainFloor = (run?.spectrum.elevation.lowerBound ?? 0) - 5
        let domainCeil  = (run?.spectrum.elevation.upperBound ?? 100) + 5

        return Chart {
            ForEach(Array(chartSegments.enumerated()), id: \.offset) { _, segment in
                AreaMark(
                    x: .value("min", minutes(of: segment)),
                    yStart: .value("m", domainFloor),
                    yEnd: .value("m", segment.elevation)
                )
                .foregroundStyle(.green.opacity(0.2))
                LineMark(
                    x: .value("min", minutes(of: segment)),
                    y: .value("m", segment.elevation)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...max(totalDurationMinutes, 1))
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
        let hrSegments = chartSegments.filter { $0.heartRate > 0 }
        let domainFloor = (run?.spectrum.heartRate.lowerBound ?? 60) - 10
        let domainCeil  = (run?.spectrum.heartRate.upperBound ?? 180) + 10

        return Chart {
            ForEach(Array(hrSegments.enumerated()), id: \.offset) { _, segment in
                AreaMark(
                    x: .value("min", minutes(of: segment)),
                    yStart: .value("bpm", domainFloor),
                    yEnd: .value("bpm", segment.heartRate)
                )
                .foregroundStyle(.red.opacity(0.2))
                LineMark(
                    x: .value("min", minutes(of: segment)),
                    y: .value("bpm", segment.heartRate)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.catmullRom)
            }
            RuleMark(x: .value("Now", playheadMinutes))
                .foregroundStyle(.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
        .chartXScale(domain: 0...max(totalDurationMinutes, 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxisLabel("minutes", alignment: .trailing)
        .chartYScale(domain: domainFloor...domainCeil)
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

    /// Downsampled segments — at most 500 points per chart for performance.
    private var chartSegments: [Run.Segment] {
        let segs = run?.segments ?? []
        let step = max(1, segs.count / 500)
        return stride(from: 0, to: segs.count, by: step).map { segs[$0] }
    }

    private func minutes(of segment: Run.Segment) -> Double {
        guard let origin = run?.segments.first?.time.start else { return 0 }
        return segment.time.start.timeIntervalSince(origin) / 60.0
    }

    // MARK: - Computed stats

    private var totalDistanceKm: Double { (run?.distance ?? 0) / 1000.0 }

    private var totalElevationGain: Double {
        let segs = run?.segments ?? []
        return zip(segs, segs.dropFirst()).reduce(0) { total, pair in
            let delta = pair.1.elevation - pair.0.elevation
            return delta > 0 ? total + delta : total
        }
    }

    private var avgHeartRate: Double {
        let values = (run?.segments ?? []).compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private var formattedDistance: String { String(format: "%.2f", totalDistanceKm) }

    private var formattedDuration: String {
        let total = Int(run?.duration ?? 0)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedAvgPace: String {
        guard totalDistanceKm > 0, let duration = run?.duration else { return "--:--" }
        let secsPerKm = duration / totalDistanceKm
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }

    private var formattedElevGain: String { String(format: "%.0f", totalElevationGain) }
    private var formattedAvgHR: String { String(format: "%.0f", avgHeartRate) }
}
