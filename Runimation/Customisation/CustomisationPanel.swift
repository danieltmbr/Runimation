import CoreKit
import CoreUI
import SwiftUI
import VisualiserUI

/// The Customisation Panel lets users switch between the Visualisation Adjustment
/// and Data Processing Pipeline settings.
///
/// On macOS it is presented in an auxiliary window; on iOS as a bottom sheet.
/// A segmented `Picker` at the top switches between the two sections.
/// Visualisation, transformer, and interpolator selection all use
/// `NavigationLink` within the panel's own `NavigationStack`.
///
/// Requires `RunPlayer` and `RunLibrary` in the environment via `.player(_:)`
/// and `.library(_:)`.
///
struct CustomisationPanel: View {

    enum Content: String, CaseIterable {
        case visualisation = "Visualisation"
        case pipeline      = "Signals"
    }

    @State
    private var content: Content = .visualisation

    @NowPlaying
    private var nowPlaying

    var body: some View {
        NavigationStack {
            VStack {
                sectionPicker

                switch content {
                case .visualisation:
                    VisualisationAdjustmentForm(visualisation: nowPlaying.visualisation)
                        .formStyle(.grouped)
                case .pipeline:
                    SignalProcessingContent(
                        transformers: nowPlaying.transformers,
                        interpolator: nowPlaying.interpolator
                    )
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
