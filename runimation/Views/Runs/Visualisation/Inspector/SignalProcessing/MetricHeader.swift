import SwiftUI

struct MetricHeader: View {
    
    let title: String
    
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if !value.isEmpty {
                Spacer()
                Text(value)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
