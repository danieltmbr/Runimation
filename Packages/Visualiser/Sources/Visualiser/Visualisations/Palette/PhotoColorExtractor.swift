import CoreImage
import simd

/// Extracts a `ColorPalette` from a photo using k-means clustering.
///
/// Uses `CIKMeans` for clustering, following Apple's recommended pattern:
/// https://developer.apple.com/documentation/accelerate/calculating-the-dominant-colors-in-an-image
///
/// The critical step is `settingAlphaOne` on the filter output — `CIKMeans` produces
/// pixels with alpha=0, and Core Image's premultiplied-alpha pipeline zeros out every
/// colour channel unless alpha is explicitly set to 1 before rendering.
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
        let resized  = resized(image, to: downsamplingSize)

        guard let centers = clusterCentroids(from: resized, sourceColorSpace: image.colorSpace, context: context, count: clusterCount),
              !centers.isEmpty,
              let pixels = pixels(from: resized, sourceColorSpace: image.colorSpace, context: context)
        else {
            return .default
        }

        let weights = weights(pixels: pixels, nearestTo: centers)
        let entries = zip(centers, weights)
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

    /// Runs `CIKMeans` and returns the cluster centroid colors.
    ///
    /// - `inputPerceptual: true` clusters in a perceptual color space for more natural results.
    /// - `settingAlphaOne` is mandatory: `CIKMeans` outputs alpha=0, and Core Image's
    ///    premultiplied pipeline zeroes every channel without it.
    /// - Rendering uses the source image's color space so component values match the
    ///    original photo's encoding, which is what `Color(red:green:blue:)` expects.
    static func clusterCentroids(
        from image: CIImage,
        sourceColorSpace: CGColorSpace?,
        context: CIContext,
        count: Int
    ) -> [SIMD3<Float>]? {
        guard let filter = CIFilter(name: "CIKMeans") else { return nil }

        filter.setValue(image,                              forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: image.extent),    forKey: "inputExtent")
        filter.setValue(count as NSNumber,                 forKey: "inputCount")
        filter.setValue(10 as NSNumber,                    forKey: "inputPasses")
        filter.setValue(true as NSNumber,                  forKey: "inputPerceptual")

        guard var output = filter.outputImage else { return nil }

        // Without this, alpha=0 in CI's premultiplied space zeroes all colour channels.
        output = output.settingAlphaOne(in: output.extent)

        let colorSpace = sourceColorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        var bitmap = [UInt8](repeating: 0, count: count * 4)
        context.render(output, toBitmap: &bitmap, rowBytes: count * 4,
                       bounds: output.extent, format: .RGBA8, colorSpace: colorSpace)

        return (0..<count).map { i in
            let base = i * 4
            return SIMD3<Float>(
                Float(bitmap[base])     / 255.0,
                Float(bitmap[base + 1]) / 255.0,
                Float(bitmap[base + 2]) / 255.0
            )
        }
    }

    /// Reads all pixels from the downsampled image for cluster weight computation.
    static func pixels(
        from image: CIImage,
        sourceColorSpace: CGColorSpace?,
        context: CIContext
    ) -> [SIMD3<Float>]? {
        let width  = Int(image.extent.width)
        let height = Int(image.extent.height)
        guard width > 0, height > 0 else { return nil }

        let colorSpace = sourceColorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        context.render(image, toBitmap: &bytes, rowBytes: width * 4,
                       bounds: image.extent, format: .RGBA8, colorSpace: colorSpace)

        return (0..<(width * height)).map { i in
            let base = i * 4
            return SIMD3<Float>(
                Float(bytes[base])     / 255.0,
                Float(bytes[base + 1]) / 255.0,
                Float(bytes[base + 2]) / 255.0
            )
        }
    }

    static func weights(pixels: [SIMD3<Float>], nearestTo centers: [SIMD3<Float>]) -> [Float] {
        var counts = [Int](repeating: 0, count: centers.count)
        for pixel in pixels {
            counts[nearestIndex(to: pixel, in: centers)] += 1
        }
        let total = Float(pixels.count)
        return counts.map { Float($0) / total }
    }

    static func nearestIndex(to pixel: SIMD3<Float>, in centers: [SIMD3<Float>]) -> Int {
        var minDist = Float.infinity
        var nearest = 0
        for (i, center) in centers.enumerated() {
            let d = dot(pixel - center, pixel - center)
            if d < minDist { minDist = d; nearest = i }
        }
        return nearest
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
