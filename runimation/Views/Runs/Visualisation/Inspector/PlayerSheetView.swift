import SwiftUI


#if os(iOS)

/// Bottom sheet inspector shown on iOS.
///
/// Scrollable content area shows stats by default. Two toggle buttons at the bottom
/// switch to diagnostics charts or parameter controls — mirroring the Apple Music
/// "lyrics / queue" pattern. Tapping an active button returns to the stats view.
/// Playback controls are always visible at the bottom of the sheet.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerSheetView: View {

    @Binding var selectedPanel: PlayerPanel
    @Binding var baseH: Double
    @Binding var octaves: Double

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
            case .stats:
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
                panelToggleButton(panel: .diagnostics, icon: "waveform.path.ecg")
                Spacer()
                panelToggleButton(panel: .parameters,  icon: "slider.horizontal.3")
            }
            .padding(.horizontal, 36)
            .padding(.bottom)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func panelToggleButton(panel: PlayerPanel, icon: String) -> some View {
        let isActive = selectedPanel == panel
        return Button {
            selectedPanel = isActive ? .stats : panel
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isActive ? .primary : .secondary)
                .padding(10)
                .background(Circle().fill(.fill).opacity(isActive ? 1 : 0))
        }
        .buttonStyle(.plain)
    }

    private var elapsedLabel: String {
        guard let run = runs?.run(for: .metrics) else { return "0:00" }
        let elapsed = progress * duration(for: run.duration)
        let total = Int(elapsed)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

#endif
