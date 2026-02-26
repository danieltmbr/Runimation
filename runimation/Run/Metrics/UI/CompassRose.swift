import SwiftUI

/// A Canvas-drawn compass rose that shows the runner's current direction of travel.
///
/// Reads from the animation segment (speed-weighted, smoothed direction) so the
/// arrow responds fluidly to changes in heading rather than snapping between GPS points.
///
struct CompassRose: View {

    @PlayerState(\.segments.animation) private var segment

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let radius = min(cx, cy) - 18

            drawRing(in: &context, cx: cx, cy: cy, radius: radius)
            drawCardinalTicks(in: &context, cx: cx, cy: cy, radius: radius)
            drawCardinalLabels(in: &context, cx: cx, cy: cy, radius: radius)
            drawDirectionArrow(for: segment?.direction ?? .zero, in: &context, cx: cx, cy: cy, radius: radius)
        }
    }

    // MARK: - Drawing helpers

    private func drawRing(in context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        context.stroke(
            Path(ellipseIn: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)),
            with: .color(.white.opacity(0.25)),
            lineWidth: 1
        )
    }

    private func drawCardinalTicks(in context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        let inner = radius * 0.82
        for k in 0..<4 {
            let angle = CGFloat(k) * .pi / 2
            var tick = Path()
            tick.move(to:    CGPoint(x: cx + inner  * sin(angle), y: cy - inner  * cos(angle)))
            tick.addLine(to: CGPoint(x: cx + radius * sin(angle), y: cy - radius * cos(angle)))
            context.stroke(tick, with: .color(.white.opacity(0.4)), lineWidth: 1)
        }
    }

    private func drawCardinalLabels(in context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        let dist = radius + 12
        for (text, dx, dy) in [("N", 0.0, -1.0), ("S", 0.0, 1.0), ("E", 1.0, 0.0), ("W", -1.0, 0.0)] {
            context.draw(
                Text(text)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45)),
                at: CGPoint(x: cx + dx * dist, y: cy + dy * dist)
            )
        }
    }

    /// Draws either a direction arrow (when moving) or a faint centre dot (when stationary).
    ///
    private func drawDirectionArrow(
        for direction: CGPoint,
        in context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        let dotRect = centredDotRect(cx: cx, cy: cy, radius: 3)

        let dirX = CGFloat(direction.x)
        let dirY = CGFloat(direction.y)
        let magnitude = sqrt(dirX * dirX + dirY * dirY)

        guard magnitude > 0.05 else {
            context.fill(Path(ellipseIn: dotRect), with: .color(.white.opacity(0.35)))
            return
        }

        // dirX = east → +x screen; dirY = north → -y screen (Y-axis is flipped on screen).
        let sDX =  dirX
        let sDY = -dirY
        drawArrowShaft(sDX: sDX, sDY: sDY, magnitude: magnitude, in: &context, cx: cx, cy: cy, radius: radius)
        drawArrowHead(sDX: sDX, sDY: sDY, magnitude: magnitude, in: &context, cx: cx, cy: cy, radius: radius)
        context.fill(Path(ellipseIn: dotRect), with: .color(.white.opacity(0.6)))
    }

    private func drawArrowShaft(
        sDX: CGFloat, sDY: CGFloat, magnitude: CGFloat,
        in context: inout GraphicsContext,
        cx: CGFloat, cy: CGFloat, radius: CGFloat
    ) {
        let arrowLen = radius * 0.62 * min(magnitude, 1.0)
        var shaft = Path()
        shaft.move(to:    CGPoint(x: cx - sDX * arrowLen * 0.2, y: cy - sDY * arrowLen * 0.2))
        shaft.addLine(to: CGPoint(x: cx + sDX * arrowLen,       y: cy + sDY * arrowLen))
        context.stroke(shaft, with: .color(.white), lineWidth: 2.5)
    }

    private func drawArrowHead(
        sDX: CGFloat, sDY: CGFloat, magnitude: CGFloat,
        in context: inout GraphicsContext,
        cx: CGFloat, cy: CGFloat, radius: CGFloat
    ) {
        let arrowLen = radius * 0.62 * min(magnitude, 1.0)
        let tip = CGPoint(x: cx + sDX * arrowLen, y: cy + sDY * arrowLen)
        let angle: CGFloat = atan2(sDY, sDX)
        let headLen: CGFloat = 9
        let spread: CGFloat = .pi / 6
        var wings = Path()
        wings.move(to: tip)
        wings.addLine(to: CGPoint(x: tip.x - headLen * cos(angle - spread),
                                  y: tip.y - headLen * sin(angle - spread)))
        wings.move(to: tip)
        wings.addLine(to: CGPoint(x: tip.x - headLen * cos(angle + spread),
                                  y: tip.y - headLen * sin(angle + spread)))
        context.stroke(wings, with: .color(.white), lineWidth: 2)
    }

    private func centredDotRect(cx: CGFloat, cy: CGFloat, radius: CGFloat) -> CGRect {
        CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
    }
}
