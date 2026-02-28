import Foundation

enum InspectorFocus: String, CaseIterable {
    
    case animation = "Animation"
    
    case pipeline  = "Signals"
    
    case stats     = "Statistics"

    var icon: String {
        switch self {
        case .animation: return "sparkles"
        case .pipeline:  return "waveform.path.ecg"
        case .stats:     return "chart.bar"
        }
    }
}
