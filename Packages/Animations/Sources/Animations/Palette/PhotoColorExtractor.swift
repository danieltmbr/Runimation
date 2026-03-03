import CoreImage
import simd

/// Extracts a `ColorPalette` from a photo using k-means clustering.
///
/// The image is downscaled then k-means runs directly on sRGB pixel values
/// read via `createCGImage`. Entries are sorted by hue for a smooth gradient.
public enum PhotoColorExtractor {

    /// Extracts dominant colors from a `CIImage`.
    ///
    /// This function is `nonisolated` and runs on the cooperative thread pool,
    /// so it is safe to call from a `@MainActor` context via `await`.
    ///
    /// - Parameters:
    ///   - image: Source image. Any size.
    ///   - downsamplingSize: Size to which the image will be downscaled before clustering.
    ///   - clusterCount: Number of dominant colors to extract (default: 5).
    /// - Returns: A `ColorPalette` with entries sorted by hue, or `.default` on failure.
    public static nonisolated func extract(
        from image: CIImage,
        downsamplingSize: CGSize = CGSize(width: 128, height: 128),
        clusterCount: Int = 5
    ) async -> ColorPalette {
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let resized = resized(image, to: downsamplingSize)

        guard let pixels = srgbPixels(from: resized, context: context), !pixels.isEmpty else {
            return .default
        }

        let centroids = kMeans(pixels: pixels, k: clusterCount)
        let weights   = weights(pixels: pixels, nearestTo: centroids)

        let entries = zip(centroids, weights)
            .map { ColorPalette.Entry(color: $0, weight: $1) }
            .sorted { hue(of: $0.color) < hue(of: $1.color) }

        return ColorPalette(entries: entries)
    }
}

// MARK: - Private Helpers

private extension PhotoColorExtractor {

    static func resized(_ image: CIImage, to targetSize: CGSize) -> CIImage {
        let scaleX = targetSize.width  / image.extent.width
        let scaleY = targetSize.height / image.extent.height
        return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }

    /// Reads all pixels from the image as gamma-corrected sRGB floats (0–1 per channel).
    ///
    /// Using `createCGImage` with an explicit sRGB colorspace is the most reliable path:
    /// it handles color profile conversion internally and guarantees values that match
    /// what SwiftUI's `Color(red:green:blue:)` expects.
    static func srgbPixels(from image: CIImage, context: CIContext) -> [SIMD3<Float>]? {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = context.createCGImage(image, from: image.extent, format: .RGBA8, colorSpace: srgb),
              let data = cgImage.dataProvider?.data
        else { return nil }

        let bytes = CFDataGetBytePtr(data)!
        let pixelCount = cgImage.width * cgImage.height

        return (0..<pixelCount).map { i in
            let base = i * 4
            return SIMD3<Float>(
                Float(bytes[base])     / 255.0,
                Float(bytes[base + 1]) / 255.0,
                Float(bytes[base + 2]) / 255.0
            )
        }
    }

    /// Lloyd's k-means on sRGB pixel values.
    ///
    /// Centroids are seeded by evenly spacing across the pixel array (avoids empty
    /// clusters common with purely random initialisation on bimodal images).
    static func kMeans(pixels: [SIMD3<Float>], k: Int, iterations: Int = 20) -> [SIMD3<Float>] {
        guard pixels.count >= k else { return Array(pixels.prefix(k)) }

        let step = pixels.count / k
        var centroids = (0..<k).map { pixels[$0 * step] }

        for _ in 0..<iterations {
            var sums   = [SIMD3<Float>](repeating: .zero, count: k)
            var counts = [Int](repeating: 0, count: k)

            for pixel in pixels {
                let i = nearestIndex(to: pixel, in: centroids)
                sums[i]   += pixel
                counts[i] += 1
            }

            for i in 0..<k where counts[i] > 0 {
                centroids[i] = sums[i] / Float(counts[i])
            }
        }

        return centroids
    }

    static func nearestIndex(to pixel: SIMD3<Float>, in centroids: [SIMD3<Float>]) -> Int {
        var minDist = Float.infinity
        var nearest = 0
        for (i, center) in centroids.enumerated() {
            let d = dot(pixel - center, pixel - center)
            if d < minDist { minDist = d; nearest = i }
        }
        return nearest
    }

    static func weights(pixels: [SIMD3<Float>], nearestTo centers: [SIMD3<Float>]) -> [Float] {
        var counts = [Int](repeating: 0, count: centers.count)
        for pixel in pixels {
            counts[nearestIndex(to: pixel, in: centers)] += 1
        }
        let total = Float(pixels.count)
        return counts.map { Float($0) / total }
    }

    /// Returns the hue (0–1) of an RGB color for perceptual sorting.
    static func hue(of color: SIMD3<Float>) -> Float {
        let r = color.x, g = color.y, b = color.z
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        guard delta > 0 else { return 0 }

        var h: Float
        if maxC == r      { h = (g - b) / delta }
        else if maxC == g { h = 2 + (b - r) / delta }
        else              { h = 4 + (r - g) / delta }

        h /= 6
        if h < 0 { h += 1 }
        return h
    }
}
