import SwiftUI
import RunUI

struct MetricHeader: View {
    
    let title: String
    
    let mapper: (any RunChartValueMapper)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            if let mapper {
                Spacer()
                
                ChartCurrentValueLabel(mapper: mapper)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
