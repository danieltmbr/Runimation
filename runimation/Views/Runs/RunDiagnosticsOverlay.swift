import Charts
import SwiftUI

struct RunDiagnosticsOverlay: View {
    let engine: PlaybackEngine

    private var totalDuration: Double { engine.runData.totalDuration }

    private var downsampledSamples: [NormalizedRunSample] {
        let samples = engine.runData.normalized
        let step = max(1, samples.count / 500)
        return Swift.stride(from: 0, to: samples.count, by: step).map { samples[$0] }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 10) {
                metricChart("Speed", keyPath: \.speed, color: .orange)
                metricChart("Heart Rate", keyPath: \.heartRate, color: .red)
                metricChart("Elevation", keyPath: \.elevation, color: .green)
            }

            compassRose
                .frame(width: 110, height: 110)
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func metricChart(
        _ label: String,
        keyPath: KeyPath<NormalizedRunSample, Float>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Chart {
                ForEach(downsampledSamples, id: \.timeOffset) { sample in
                    LineMark(
                        x: .value("Progress", sample.timeOffset / totalDuration),
                        y: .value(label, Double(sample[keyPath: keyPath]))
                    )
                    .foregroundStyle(color.opacity(0.85))
                    .interpolationMethod(.catmullRom)
                }
                RuleMark(x: .value("Now", engine.progress))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartXScale(domain: 0...1)
            .chartYScale(domain: 0...1)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 50)
        }
    }

    private var compassRose: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let radius = min(cx, cy) - 18

            // Outer ring
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: cx - radius, y: cy - radius,
                    width: radius * 2, height: radius * 2
                )),
                with: .color(.white.opacity(0.25)),
                lineWidth: 1
            )

            // Cardinal ticks at N/E/S/W
            for k in 0..<4 {
                let a = CGFloat(k) * .pi / 2
                let inner = radius * 0.82
                var tick = Path()
                tick.move(to: CGPoint(x: cx + inner * sin(a), y: cy - inner * cos(a)))
                tick.addLine(to: CGPoint(x: cx + radius * sin(a), y: cy - radius * cos(a)))
                context.stroke(tick, with: .color(.white.opacity(0.4)), lineWidth: 1)
            }

            // N/S/E/W labels
            let labelDist = radius + 12
            for (text, dx, dy) in [("N", 0.0, -1.0), ("S", 0.0, 1.0),
                                    ("E", 1.0,  0.0), ("W", -1.0, 0.0)] {
                context.draw(
                    Text(text)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.45)),
                    at: CGPoint(x: cx + dx * labelDist, y: cy + dy * labelDist)
                )
            }

            // Direction arrow — engine.currentDir is already speed-weighted,
            // so magnitude ≈ 0 when the runner is at rest.
            let dirX = CGFloat(engine.currentDirX)
            let dirY = CGFloat(engine.currentDirY)
            let magnitude = sqrt(dirX * dirX + dirY * dirY)

            let dotR: CGFloat = 3
            let dotRect = CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)

            guard magnitude > 0.05 else {
                context.fill(Path(ellipseIn: dotRect), with: .color(.white.opacity(0.35)))
                return
            }

            // dirX = east → +x in screen; dirY = north → −y in screen (SwiftUI y flips).
            let sDX = dirX
            let sDY = -dirY
            let arrowLen = radius * 0.62 * min(magnitude, 1.0)

            let tipPt    = CGPoint(x: cx + sDX * arrowLen,        y: cy + sDY * arrowLen)
            let tailPt   = CGPoint(x: cx - sDX * arrowLen * 0.2, y: cy - sDY * arrowLen * 0.2)

            var shaft = Path()
            shaft.move(to: tailPt)
            shaft.addLine(to: tipPt)
            context.stroke(shaft, with: .color(.white), lineWidth: 2.5)

            // Arrowhead wings
            let angle: CGFloat = atan2(sDY, sDX)
            let headLen: CGFloat = 9
            let spread: CGFloat = .pi / 6
            var wings = Path()
            wings.move(to: tipPt)
            wings.addLine(to: CGPoint(
                x: tipPt.x - headLen * cos(angle - spread),
                y: tipPt.y - headLen * sin(angle - spread)
            ))
            wings.move(to: tipPt)
            wings.addLine(to: CGPoint(
                x: tipPt.x - headLen * cos(angle + spread),
                y: tipPt.y - headLen * sin(angle + spread)
            ))
            context.stroke(wings, with: .color(.white), lineWidth: 2)

            context.fill(Path(ellipseIn: dotRect), with: .color(.white.opacity(0.6)))
        }
    }
}
