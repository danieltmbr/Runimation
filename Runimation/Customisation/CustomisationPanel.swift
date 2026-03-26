import SwiftUI
import Visualiser
import CoreKit
import CoreUI

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

    enum Content: String, CaseIterable {
        case visualisation = "Visualisation"
        case pipeline      = "Signals"
    }

    @State
    private var content: Content = .visualisation

    @Environment(VisualisationModel.self)
    private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            VStack {
                sectionPicker
                
                switch content {
                case .visualisation:
                    VisualisationAdjustmentForm(visualisation: $model.current)
                        .formStyle(.grouped)
                case .pipeline:
                    SignalProcessingContent()
                }
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

    private var sectionPicker: some View {
        Picker("Section", selection: $content) {
            ForEach(Content.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
}
