import SwiftUI
import RunKit
import RunUI

#if os(iOS)

/// Bottom sheet inspector shown on iOS.
///
/// Scrollable content area shows animation controls by default. Two toggle buttons
/// at the bottom switch to the signal processing or stats panels — mirroring the Apple Music
/// "lyrics / queue" pattern. Tapping an active button returns to animation.
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
            panelTitle
            scrollableContent
            fixedControls
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    // MARK: - Sections

    private var panelTitle: some View {
        Text(selectedPanel.rawValue)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private var scrollableContent: some View {
        switch selectedPanel {
        case .animation:
            ScrollView {
                AnimationPreferencesContent(baseH: $baseH, octaves: $octaves)
            }
        case .pipeline:
            SignalProcessingContent()
        case .stats:
            ScrollView {
                RunStatisticsContent()
            }
        }
    }

    private var fixedControls: some View {
        VStack(spacing: 20) {
            Divider()

            PlaybackControls()
                .playbackControlsStyle(.regular)

            // Panel toggle buttons (pipeline left, stats right)
            HStack {
                panelToggleButton(panel: .pipeline, icon: "waveform.path.ecg")
                Spacer()
                panelToggleButton(panel: .stats, icon: "chart.bar")
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
            selectedPanel = isActive ? .animation : panel
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
