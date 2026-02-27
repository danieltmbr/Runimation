import SwiftUI

/// The expandable bottom sheet containing run stats, diagnostics, and visualisation parameters.
///
/// The scrollable content area shows stats by default. Two toggle buttons at the bottom
/// switch to diagnostics charts or parameter controls — mirroring the Apple Music
/// "lyrics / queue" pattern. Tapping an active button returns to the stats view.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerSheetView: View {

    @Binding var baseH: Double
    @Binding var octaves: Double
    @Binding var selectedPanel: PlayerPanel?

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.progress)
    private var progress

    @PlayerState(\.duration)
    private var duration

    var body: some View {
        VStack(spacing: 0) {
            scrollableContent
            fixedControls
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var scrollableContent: some View {
        ScrollView {
            switch selectedPanel {
            case .none:
                StatsContent()
            case .diagnostics:
                DiagnosticsContent()
            case .parameters:
                ParametersContent(baseH: $baseH, octaves: $octaves)
            }
        }
    }

    private var fixedControls: some View {
        VStack(spacing: 20) {
            Divider()

            // Progress slider with elapsed time and duration picker
            HStack(spacing: 8) {
                Text(elapsedLabel)
                    .font(.caption.monospacedDigit())
                ProgressSlider()
                    .sliderThumbVisibility(.automatic)
                DurationMenu()
            }
            .padding(.horizontal)

            // Playback buttons: Spacer | Rewind | Spacer | Play(big) | Spacer | Loop | Spacer
            HStack {
                Spacer()
                RewindButton()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 26, weight: .semibold))
                Spacer()
                PlayToggle()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 46))
                Spacer()
                LoopToggle()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 26, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.primary)

            // Panel toggle buttons (diagnostics left, parameters right)
            HStack {
                Button {
                    selectedPanel = selectedPanel == .diagnostics ? nil : .diagnostics
                } label: {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20))
                        .foregroundStyle(selectedPanel == .diagnostics ? .primary : .secondary)
                        .padding(10)
                        .background(Circle().fill(.fill).opacity(selectedPanel == .diagnostics ? 1 : 0))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    selectedPanel = selectedPanel == .parameters ? nil : .parameters
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundStyle(selectedPanel == .parameters ? .primary : .secondary)
                        .padding(10)
                        .background(Circle().fill(.fill).opacity(selectedPanel == .parameters ? 1 : 0))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 36)
            .padding(.bottom)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var elapsedLabel: String {
        guard let run = runs?.run(for: .metrics) else { return "0:00" }
        let elapsed = progress * duration(for: run.duration)
        return Self.formatElapsed(elapsed)
    }

    private static func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Stats Content (default)

private struct StatsContent: View {

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

// MARK: - Diagnostics Content

private struct DiagnosticsContent: View {

    var body: some View {
        VStack(spacing: 16) {
            DiagnosticMetricChart(label: "Speed", mapper: .pace)
                .runChartShapeStyle(.orange.opacity(0.85))
            DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate)
                .runChartShapeStyle(.red.opacity(0.85))
            DiagnosticMetricChart(label: "Elevation", mapper: .elevation)
                .runChartShapeStyle(.green.opacity(0.85))
            CompassRose()
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

// MARK: - Parameters Content

private struct ParametersContent: View {

    @Binding var baseH: Double
    @Binding var octaves: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("H: \(baseH, specifier: "%.2f")")
                    .font(.caption)
                Slider(value: $baseH, in: 0...1)
            }
            HStack {
                Text("Octaves: \(Int(octaves))")
                    .font(.caption)
                Slider(value: $octaves, in: 1...12, step: 1)
            }
        }
        .padding()
    }
}
