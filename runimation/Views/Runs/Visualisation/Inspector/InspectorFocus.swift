import Foundation

enum InspectorFocus: String, CaseIterable {

    case visualisation = "Visualisation"

    case pipeline = "Signals"

    var icon: String {
        switch self {
        case .visualisation: return "sparkles"
        case .pipeline:      return "waveform.path.ecg"
        }
    }
}
