import SwiftUI
import Metal
import CoreGraphics

/// Renders the run's GPS path as a line using an SDF fragment shader.
///
/// The visible path is computed once on appear and re-computed after each
/// gesture ends. While a gesture is in progress the previous LOD is shown
/// unchanged, keeping the interaction responsive.
///
/// LOD strategy:
/// - **Overview** — RDP over the full path with a loose epsilon (~10 px in
///   normalised space). Guarantees a complete, always-visible backbone.
/// - **Detail** — RDP over the viewport-clipped subset with a tight epsilon
///   (~1 px). Spends the point budget on what is actually on screen.
/// - **Merge** — Union of both index sets, filtered from the original array
///   in enumeration order. Preserves polyline topology with no phantom segments.
///
public struct RunPathView: View {

    let state: AnimationState

    @State private var scale: CGFloat = 2
    
    @State private var baseScale: CGFloat = 2
    
    @State private var offset: CGVector = .zero
    
    @State private var baseOffset: CGVector = .zero
    
    @State private var viewSize: CGSize = .zero
    
    @State private var visiblePath: [SIMD2<Float>] = []

    public init(state: AnimationState) {
        self.state = state
    }

    public var body: some View {
        let animTime    = state.time
        let scale       = self.scale
        let offset      = self.offset
        let coordinates = state.coordinates
        let direction   = state.direction
        let elevation   = state.elevation
        let heartRate   = state.heartRate
        let pathData    = visiblePath.withUnsafeBytes { Data($0) }
        let speed       = state.speed

        Rectangle()
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.bundle(.module).runPathWarpShader(
                        .float(animTime),
                        .float2(proxy.size),
                        .float(scale),
                        .float2(offset),
                        .float2(coordinates),
                        .float2(direction),
                        .float(elevation),
                        .float(heartRate),
                        .data(pathData),
                        .float(speed)
                    )
                )
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
                viewSize = newSize
                recomputePath()
            }
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .onChange(of: state.path) { _, _ in
                recomputePath()
            }
    }

    // MARK: - LOD

    private func recomputePath() {
        let path = state.path
        guard path.count > 2, viewSize.height > 0 else {
            visiblePath = path
            return
        }

        let s = Float(scale)
        let o = SIMD2<Float>(Float(offset.dx), Float(offset.dy))
        let halfHeight = Float(viewSize.height / 2)

        let overviewEpsilon = s * 10 / halfHeight
        let detailEpsilon   = s *  1 / halfHeight

        let overviewIndices = PathSimplifier.rdp(path, epsilon: overviewEpsilon)
        let detailIndices   = visibleIndices(in: path, scale: s, offset: o, epsilon: detailEpsilon)

        let merged = overviewIndices.union(detailIndices)
        visiblePath = path.enumerated().compactMap { index, coord in
            merged.contains(index) ? coord : nil
        }
    }

    /// Returns RDP indices for the portion of the path visible in the current viewport.
    ///
    /// The viewport is expanded by 10% on each side so segments crossing the
    /// boundary are included and the path doesn't abruptly stop at the edge.
    ///
    private func visibleIndices(
        in path: [SIMD2<Float>],
        scale: Float,
        offset: SIMD2<Float>,
        epsilon: Float
    ) -> Set<Int> {
        let aspectRatio = Float(viewSize.width / viewSize.height)
        let halfW = scale * aspectRatio * 1.1
        let halfH = scale * 1.1
        let minX = offset.x - halfW,  maxX = offset.x + halfW
        let minY = offset.y - halfH,  maxY = offset.y + halfH

        // Collect indices of visible points plus their immediate neighbours so
        // segments that cross the viewport boundary are drawn completely.
        var indices: [Int] = []
        for (i, p) in path.enumerated() {
            guard p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY else { continue }
            if i > 0 && indices.last != i - 1 { indices.append(i - 1) }
            indices.append(i)
            if i + 1 < path.count { indices.append(i + 1) }
        }

        guard indices.count > 2 else { return Set(indices) }

        // Deduplicate while preserving order (neighbours may be inserted twice).
        var seen = Set<Int>()
        let unique = indices.filter { seen.insert($0).inserted }
        let clipped = unique.map { path[$0] }
        return Set(PathSimplifier.rdp(clipped, epsilon: epsilon).map { unique[$0] })
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let halfHeight = viewSize.height / 2
                // Center and y-flip the pinch location to match UV space.
                let cx = value.startLocation.x - viewSize.width / 2
                let cy = viewSize.height / 2 - value.startLocation.y
                let newScale = clamp(baseScale / value.magnification, min: 0.1, max: 5)
                offset = CGVector(
                    dx: baseOffset.dx + cx * (baseScale - newScale) / halfHeight,
                    dy: baseOffset.dy + cy * (baseScale - newScale) / halfHeight
                )
                scale = newScale
            }
            .onEnded { _ in
                baseScale = scale
                baseOffset = offset
                recomputePath()
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let halfHeight = viewSize.height / 2
                // Screen y increases downward; UV y increases upward — so y sign flips.
                offset.dx = baseOffset.dx - value.translation.width  * Double(scale) / halfHeight
                offset.dy = baseOffset.dy + value.translation.height * Double(scale) / halfHeight
            }
            .onEnded { _ in
                baseOffset = offset
                recomputePath()
            }
    }

    private func clamp(_ value: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
        Swift.min(hi, Swift.max(lo, value))
    }
}

#Preview {
    RunPathView(state: .zero)
}

extension Shader.Argument {
    static func float2(_ simd: SIMD2<Float>) -> Shader.Argument {
        .float2(simd.x, simd.y)
    }
}
