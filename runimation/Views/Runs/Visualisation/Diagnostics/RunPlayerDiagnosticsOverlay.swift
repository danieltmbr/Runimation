import SwiftUI

struct RunPlayerDiagnosticsOverlay: View {

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 10) {
                DiagnosticMetricChart(label: "Speed", mapper: .pace)
                    .runChartShapeStyle(.orange.opacity(0.85))

                DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate)
                    .runChartShapeStyle(.red.opacity(0.85))

                DiagnosticMetricChart(label: "Elevation", mapper: .elevation)
                    .runChartShapeStyle(.green.opacity(0.85))
            }

            CompassRose()
                .frame(width: 110, height: 110)
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
