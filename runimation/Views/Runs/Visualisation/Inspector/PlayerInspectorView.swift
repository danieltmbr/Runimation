import SwiftUI
import Animations

#if os(macOS)

/// Trailing sidebar inspector shown on macOS.
///
/// A glass-effect icon button row at the top switches between Visualisation Preferences,
/// Signal Preferences, and Run Statistics panels. The selected panel is highlighted
/// with the accent color and its title is shown below the selector.
/// Playback controls live in the window toolbar.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerInspectorView: View {

    @Binding
    var selectedPanel: InspectorFocus

    /// Stored directly to avoid `@Binding` property-wrapper synthesis issues
    /// with existential types. `Binding.wrappedValue` has a `nonmutating` setter,
    /// so reads and writes work correctly on a `let` stored property.
    let visualisation: Binding<any Visualisation>

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
        case .visualisation:
            ScrollView {
                VisualisationPicker(visualisation: visualisation)
                makeForm(for: visualisation.wrappedValue)
            }
        case .pipeline:
            SignalProcessingContent()
        case .stats:
            ScrollView {
                RunStatisticsContent()
            }
        }
    }

    // MARK: - Private

    /// SE-0352 opens `any Visualisation` to concrete `V`, then renders its
    /// configuration form. Returns `AnyView` so the return type does not depend
    /// on the opened type `V` — a requirement for SE-0352 implicit opening.
    ///
    private func makeForm<V: Visualisation>(for vis: V) -> AnyView {
        AnyView(vis.form(for: Binding(
            get: { visualisation.wrappedValue as! V },
            set: { visualisation.wrappedValue = $0 }
        )))
    }
}

#endif
