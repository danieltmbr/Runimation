import SwiftUI
import Visualiser
import RunUI
import CoreUI

#if os(iOS)

/// Customisation sheet shown on iOS.
///
/// Scrollable content area shows visualisation controls by default. A toggle button
/// at the bottom switches to the signal processing pipeline panel. Tapping an active
/// button returns to the visualisation panel.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerSheetView: View {

    @Binding var selectedPanel: InspectorFocus

    /// Stored directly to avoid `@Binding` property-wrapper synthesis issues
    /// with existential types. `Binding.wrappedValue` has a `nonmutating` setter,
    /// so reads and writes work correctly on a `let` stored property.
    let visualisation: Binding<any Visualisation>

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
        case .visualisation:
            ScrollView {
                VisualisationPicker(visualisation: visualisation)
                makeForm(for: visualisation.wrappedValue)
            }
        case .pipeline:
            SignalProcessingContent()
        }
    }

    private var fixedControls: some View {
        VStack {
            Divider()
            HStack {
                Spacer()
                panelToggleButton(panel: .pipeline, icon: "waveform.path.ecg")
                Spacer()
            }
            .padding(.bottom)
        }
        .padding(.top, 4)
    }

    // MARK: - Panel Toggle

    private func panelToggleButton(panel: InspectorFocus, icon: String) -> some View {
        let isActive = selectedPanel == panel
        return Button {
            selectedPanel = isActive ? .visualisation : panel
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isActive ? .primary : .secondary)
                .padding(10)
                .background(Circle().fill(.fill).opacity(isActive ? 1 : 0))
        }
        .buttonStyle(.plain)
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
