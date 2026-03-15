import Foundation

enum InspectorFocus: String, CaseIterable {

    case visualisation = "Visualisation"

    case pipeline  = "Signals"

    case stats     = "Statistics"

    var icon: String {
        switch self {
        case .visualisation: return "sparkles"
        case .pipeline:      return "waveform.path.ecg"
        case .stats:         return "chart.bar"
        }
    }
}
