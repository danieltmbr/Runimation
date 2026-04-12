import SwiftUI
import VisualiserUI
import CoreKit
import CoreUI

struct VisualisationAdjustmentForm: View {
    
    var visualisation: Binding<any Visualisation>
    
    var body: some View {
        Form {
            Section("Visualisation") {
                VisualisationPicker(visualisation: visualisation)
            }
            
            Section("Adjustments") {
                makeForm(visualisation.wrappedValue, from: visualisation)
            }
            
            Section("Description") {
                Text(visualisation.wrappedValue.description)
            }
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
