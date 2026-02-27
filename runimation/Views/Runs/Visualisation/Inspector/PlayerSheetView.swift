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

    @Binding var selectedPanel: InspectorFocus
    @Binding var baseH: Double
    @Binding var octaves: Double

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

            PlaybackControls()
                .playbackControlsStyle(.regular)

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

    // MARK: - Panel Toggle

    private func panelToggleButton(panel: InspectorFocus, icon: String) -> some View {
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

}

#endif
