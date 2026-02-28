import SwiftUI

#if os(macOS)

/// Trailing sidebar inspector shown on macOS.
///
/// A glass-effect icon button row at the top switches between Animation Preferences,
/// Signal Preferences, and Run Statistics panels. The selected panel is highlighted
/// with the accent color and its title is shown below the selector.
/// Playback controls live in the window toolbar.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerInspectorView: View {

    @Binding
    var selectedPanel: InspectorFocus

    @Binding
    var baseH: Double

    @Binding
    var octaves: Double

    var body: some View {
        VStack(spacing: 0) {
            panelSelector
            panelTitle
            Divider()
            panelContent
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Panel Selector

    private var panelSelector: some View {
        HStack(spacing: 4) {
            ForEach(InspectorFocus.allCases, id: \.self) { focus in
                Button { selectedPanel = focus } label: {
                    Image(systemName: focus.icon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .foregroundStyle(selectedPanel == focus ? .white : .primary)
                        .background(
                            selectedPanel == focus
                                ? Capsule(style: .continuous).fill(Color.accentColor)
                                : nil
                        )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(4)
        .glassEffect(in: Capsule())
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Panel Title

    private var panelTitle: some View {
        Text(selectedPanel.rawValue)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }

    // MARK: - Panel Content

    @ViewBuilder
    private var panelContent: some View {
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
}

#endif
