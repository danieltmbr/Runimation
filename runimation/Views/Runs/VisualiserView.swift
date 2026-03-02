import SwiftUI
import RunKit
import RunUI

struct VisualiserView: View {
    
    @Environment(RunPlayer.self)
    private var player
    
    @Binding
    var showInspector: Bool
    
    @State
    private var selectedPanel: InspectorFocus = .animation
    
    @State
    private var baseH: Double = 0.8
    
    @State
    private var octaves: Double = 5.0
    
    var body: some View {
        WarpView(
            smoothness: $baseH,
            details: $octaves
        )
        .ignoresSafeArea()
        .backgroundExtensionEffect()
#if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
#endif
        .inspector(isPresented: $showInspector) {
#if os(macOS)
            PlayerInspectorView(selectedPanel: $selectedPanel, baseH: $baseH, octaves: $octaves)
                .inspectorColumnWidth(min: 200, ideal: 270, max: 400)
                .player(player)
#else
            PlayerSheetView(selectedPanel: $selectedPanel, baseH: $baseH, octaves: $octaves)
                .player(player)
#endif
        }
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .principal) {
                PlaybackControls()
                    .playbackControlsStyle(.toolbar)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showInspector.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
            }
#endif
        }
    }
}
