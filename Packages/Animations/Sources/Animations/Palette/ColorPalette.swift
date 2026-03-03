import simd

/// A photo-extracted color palette: dominant colors with their proportional weights.
///
/// Each entry represents a cluster of similar colors found in the source photo.
/// Weights sum to 1.0. The palette is used to build a 1D gradient texture
/// that the Metal shader samples using warp magnitude as the UV coordinate.
///
/// Color data only — image generation happens at rendering time via `PaletteGradientRenderer`.
public struct ColorPalette: Sendable, Equatable {

    /// A single color cluster entry.
    public struct Entry: Sendable, Equatable {
        /// RGB color in linear 0–1 space.
        public var color: SIMD3<Float>
        /// Proportion of photo pixels represented by this cluster (0–1, all entries sum to 1).
        public var weight: Float

        public init(color: SIMD3<Float>, weight: Float) {
            self.color = color
            self.weight = weight
        }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    /// Default palette: approximates the current hardcoded cool-to-warm cosine spectrum.
    ///
    /// Produced by sampling the cool cosine palette
    /// (a=(0.5,0.6,0.7), b=(0.3,0.3,0.4), c=(1,1,1), d=(0,0.25,0.5))
    /// at t = 0, 0.2, 0.4, 0.6, 0.8, 1.0 with equal weights.
    public static let `default`: ColorPalette = {
        // Cool cosine palette from the original runPalette shader function.
        let a = SIMD3<Float>(0.5, 0.6, 0.7)
        let b = SIMD3<Float>(0.3, 0.3, 0.4)
        let c = SIMD3<Float>(1.0, 1.0, 1.0)
        let d = SIMD3<Float>(0.0, 0.25, 0.5)

        let tValues: [Float] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
        let weight: Float = 1.0 / Float(tValues.count)

        let entries = tValues.map { t in
            Entry(color: cosineColor(t: t, a: a, b: b, c: c, d: d), weight: weight)
        }

        return ColorPalette(entries: entries)
    }()
}

// MARK: - Private Helpers

private extension ColorPalette {
    /// Inigo Quilez cosine palette: color(t) = a + b · cos(2π(ct + d))
    static func cosineColor(t: Float, a: SIMD3<Float>, b: SIMD3<Float>, c: SIMD3<Float>, d: SIMD3<Float>) -> SIMD3<Float> {
        let twoPi: Float = .pi * 2
        let raw = SIMD3<Float>(
            a.x + b.x * cos(twoPi * (c.x * t + d.x)),
            a.y + b.y * cos(twoPi * (c.y * t + d.y)),
            a.z + b.z * cos(twoPi * (c.z * t + d.z))
        )
        return clamp(raw, min: .zero, max: .one)
    }
}
