import SwiftUI

struct DiagnosticsContent: View {

    var body: some View {
        VStack(spacing: 16) {
            DiagnosticMetricChart(label: "Speed", mapper: .pace)
                .runChartShapeStyle(.orange.opacity(0.85))
            DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate)
                .runChartShapeStyle(.red.opacity(0.85))
            DiagnosticMetricChart(label: "Elevation", mapper: .elevation)
                .runChartShapeStyle(.green.opacity(0.85))
            CompassRose()
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
