import CoreGraphics
import SwiftUI

/// Generates a 256×1 gradient image from a `ColorPalette`.
///
/// Stop positions in the gradient are proportional to entry weights,
/// preserving the dominant-color distribution from the original photo.
/// The resulting `Image` is passed to the Metal shader as a color LUT texture.
public enum PaletteGradientRenderer {

    /// Returns a SwiftUI `Image` suitable for use as a Metal shader texture argument.
    public static func image(_ palette: ColorPalette) -> Image {
        platformImage(render(palette))
    }

    /// Renders a 256×1 `CGImage` gradient from the palette.
    public static func render(_ palette: ColorPalette) -> CGImage {
        guard !palette.entries.isEmpty else {
            return render(.default)
        }

        let width  = 256
        let height = 1
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        let colors: [CGColor] = palette.entries.map { entry in
            CGColor(
                colorSpace: colorSpace,
                components: [
                    CGFloat(entry.color.x),
                    CGFloat(entry.color.y),
                    CGFloat(entry.color.z),
                    1.0
                ]
            )!
        }

        // Cumulative positions: entry[i] starts at the sum of all preceding weights.
        var cumulative: Float = 0
        var locations: [CGFloat] = palette.entries.map { entry in
            let loc = CGFloat(cumulative)
            cumulative += entry.weight
            return loc
        }
        // Force last stop to exactly 1.0 to cover the full gradient width.
        locations[locations.count - 1] = 1.0

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        ) else {
            return fallbackImage()
        }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return fallbackImage()
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0,             y: 0),
            end:   CGPoint(x: CGFloat(width), y: 0),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )

        return context.makeImage()!
    }
}

// MARK: - Private Helpers

private extension PaletteGradientRenderer {

    static func platformImage(_ cgImage: CGImage) -> Image {
#if os(macOS)
        Image(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: 256, height: 1)))
#else
        Image(uiImage: UIImage(cgImage: cgImage))
#endif
    }

    static func fallbackImage() -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: 256,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 256 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(gray: 0.5, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 256, height: 1))
        return context.makeImage()!
    }
}
