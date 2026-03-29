import Foundation
import simd

/// Ramer–Douglas–Peucker polyline simplification.
///
/// Returns a set of indices into the original point array that form a
/// simplified version of the polyline. Points whose perpendicular distance
/// from the simplified line is less than `epsilon` are omitted.
///
/// The first and last indices are always included so the simplified path
/// spans the full extent of the input.
///
public enum PathSimplifier {

    /// Simplifies `points` and returns the retained indices.
    ///
    /// - Parameters:
    ///   - points: The input polyline.
    ///   - epsilon: Maximum allowed perpendicular deviation. Points closer
    ///     than this to the simplified segment are discarded.
    /// - Returns: Unordered set of retained indices.
    ///
    public static func rdp(_ points: [SIMD2<Float>], epsilon: Float) -> Set<Int> {
        guard points.count > 2 else { return Set(points.indices) }
        var result = Set<Int>()
        rdp(points, from: 0, to: points.count - 1, epsilon: epsilon, into: &result)
        return result
    }

    // MARK: - Private

    private static func rdp(
        _ points: [SIMD2<Float>],
        from start: Int,
        to end: Int,
        epsilon: Float,
        into result: inout Set<Int>
    ) {
        result.insert(start)
        result.insert(end)

        guard end - start > 1 else { return }

        let a = points[start]
        let b = points[end]
        var maxDist: Float = 0
        var maxIndex = start

        for i in (start + 1)..<end {
            let d = perpendicularDistance(from: points[i], lineStart: a, lineEnd: b)
            if d > maxDist {
                maxDist = d
                maxIndex = i
            }
        }

        guard maxDist > epsilon else { return }

        rdp(points, from: start, to: maxIndex, epsilon: epsilon, into: &result)
        rdp(points, from: maxIndex, to: end, epsilon: epsilon, into: &result)
    }

    /// Perpendicular distance from `point` to the infinite line through `lineStart` and `lineEnd`.
    ///
    private static func perpendicularDistance(
        from point: SIMD2<Float>,
        lineStart: SIMD2<Float>,
        lineEnd: SIMD2<Float>
    ) -> Float {
        let ab = lineEnd - lineStart
        let lenSq = simd_dot(ab, ab)
        guard lenSq > 0 else { return simd_length(point - lineStart) }
        let t = simd_dot(point - lineStart, ab) / lenSq
        let closest = lineStart + t * ab
        return simd_length(point - closest)
    }
}
