import SwiftUI
import Visualiser
import CoreKit
internal import CoreUI

/// The Customisation Panel lets users switch between the Visualisation Adjustment
/// and Data Processing Pipeline settings.
///
/// On macOS it is presented in an auxiliary window; on iOS as a bottom sheet.
/// A segmented `Picker` at the top switches between the two sections.
/// Visualisation, transformer, and interpolator selection all use
/// `NavigationLink` within the panel's own `NavigationStack`.
///
/// Requires `RunPlayer` in the environment via `.player(_:)` and
/// `VisualisationModel` via `.environment(model)`.
///
struct CustomisationPanel: View {

    // MARK: - Section

    enum Section: String, CaseIterable {
        case visualisation = "Visualisation"
        case pipeline      = "Pipeline"
    }

    // MARK: - State

    @State
    private var section: Section = .visualisation

    @Environment(VisualisationModel.self)
    private var model

    // MARK: - Body

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            VStack(spacing: 0) {
                sectionPicker
                Divider()
                sectionContent(visualisation: $model.current)
            }
            .navigationTitle("Customise")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        Picker("Section", selection: $section) {
            ForEach(Section.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Section Content

    @ViewBuilder
    private func sectionContent(visualisation: Binding<any Visualisation>) -> some View {
        switch section {
        case .visualisation:
            Form {
                SwiftUI.Section {
                    VisualisationPicker(visualisation: visualisation)
                }
                SwiftUI.Section {
                    makeForm(visualisation.wrappedValue, from: visualisation)
                }
                SwiftUI.Section {
                    Text(visualisation.wrappedValue.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        case .pipeline:
            SignalProcessingContent()
        }
    }

    // MARK: - Form Helper

    /// SE-0352 opens `any Visualisation` to concrete `V`, then renders its
    /// configuration form via the outer `binding`. Returns `AnyView` so the
    /// return type does not depend on the opened type `V`.
    ///
    private func makeForm<V: Visualisation>(_ vis: V, from binding: Binding<any Visualisation>) -> AnyView {
        AnyView(vis.form(for: Binding(
            get: { binding.wrappedValue as! V },
            set: { binding.wrappedValue = $0 }
        )))
    }
}
