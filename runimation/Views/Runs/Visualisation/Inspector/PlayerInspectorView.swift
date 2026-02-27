import SwiftUI

#if os(macOS)

/// Trailing sidebar inspector shown on macOS.
///
/// An icon-only segmented picker at the top switches between stats, diagnostics,
/// and parameters. Playback controls live in the window toolbar.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerInspectorView: View {

    @Binding var selectedPanel: PlayerPanel
    @Binding var baseH: Double
    @Binding var octaves: Double

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedPanel) {
                Image(systemName: "chart.bar")
                    .tag(PlayerPanel.stats)
                
                Image(systemName: "waveform.path.ecg")
                    .tag(PlayerPanel.diagnostics)
                
                Image(systemName: "slider.horizontal.3")
                    .tag(PlayerPanel.parameters)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            Divider()
            
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
    }
}

#endif
