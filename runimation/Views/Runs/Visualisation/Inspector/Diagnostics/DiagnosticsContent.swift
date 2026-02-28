import SwiftUI

struct DiagnosticsContent: View {

    var body: some View {
        VStack(spacing: 16) {
            InterpolationPicker()

            TransformerListButton()

            DiagnosticMetricChart(label: "Speed", mapper: .pace)
                .runChartShapeStyle(.orange)
            
            DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate)
                .runChartShapeStyle(.red)
            
            DiagnosticMetricChart(label: "Elevation", mapper: .elevation)
                .runChartShapeStyle(.green)
            
            CompassRose()
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
