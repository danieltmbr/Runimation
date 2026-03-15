import SwiftUI
import CoreKit

/// User-configurable parameters for the domain warp animation.
///
/// `FormAdjustable` conformance lives in `WarpForm.swift`.
/// `Animation` conformance (canvas rendering) lives in `WarpView.swift`.
///
/// See: [Domain Warping – Inigo Quilez](https://iquilezles.org/articles/warp/)
///
public struct Warp: Option, Equatable, Sendable {

    /// Shader H parameter offset — controls global smoothness (0–1).
    public var smoothness: Double

    /// fBM octave count — controls detail level (1–12).
    public var details: Double

    /// Photo-extracted color palette used to build the Metal LUT texture.
    /// Defaults to a sampled approximation of the original cosine palette.
    public var palette: ColorPalette

    public var label: String { "Domain Warp" }

    public var description: String {
        """
        Domain-warped fractional Brownian motion driven by run metrics.

        Check out [Domain Warping – Inigo Quilez](iquilezles.org/articles/warp) for more.
        """
    }

    public init(
        smoothness: Double = 0.8,
        details: Double = 5.0,
        palette: ColorPalette = .default
    ) {
        self.smoothness = smoothness
        self.details = details
        self.palette = palette
    }
}
