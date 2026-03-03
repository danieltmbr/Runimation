import SwiftUI
import PhotosUI
import CoreKit
import CoreUI

/// User-configurable parameters for the domain warp animation.
///
/// Conforms to `FormAdjustable` so the inspector can render its controls
/// via `AdjustableForm(value: $warp)` without knowing the concrete type.
///
/// See: [Domain Warping – Inigo Quilez](https://iquilezles.org/articles/warp/)
///
public struct Warp: Option, FormAdjustable, Sendable {

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

    @MainActor
    public func form(for binding: Binding<Warp>) -> AnyView {
        AnyView(WarpForm(value: binding))
    }
}

// MARK: - Form View

/// Configuration controls for `Warp` shown via `AdjustableForm`.
///
/// Includes sliders for smoothness and detail, a photo picker for color
/// palette injection, a live color swatch strip, and a reset button.
private struct WarpForm: View {

    @Binding
    var value: Warp

    @State
    private var selectedItem: PhotosPickerItem?
    
    @State
    private var isExtracting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sliders
            paletteSection
        }
        .padding()
        .task(id: selectedItem) {
            guard let item = selectedItem else { return }
            await extractPalette(from: item)
        }
    }

    // MARK: - Subviews

    private var sliders: some View {
        Group {
            VStack(alignment: .leading) {
                Text("Smoothing")
                    .font(.caption)
                Slider(value: $value.smoothness, in: 0...1)
            }
            VStack(alignment: .leading) {
                Text("Details")
                    .font(.caption)
                Slider(value: $value.details, in: 1...12, step: 1)
            }
        }
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Palette")
                .font(.caption)

            colorSwatchStrip

            HStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label(
                        isExtracting ? "Extracting…" : "Import from Photo",
                        systemImage: "photo"
                    )
                    .font(.caption)
                }
                .disabled(isExtracting)

                Spacer()

                if value.palette != .default {
                    Button("Reset") {
                        value.palette = .default
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Proportional color swatch strip reflecting the current palette's distribution.
    private var colorSwatchStrip: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(value.palette.entries.enumerated()), id: \.offset) { _, entry in
                    Color(
                        red:   Double(entry.color.x),
                        green: Double(entry.color.y),
                        blue:  Double(entry.color.z)
                    )
                    .frame(width: geometry.size.width * CGFloat(entry.weight))
                }
            }
        }
        .frame(height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Photo Extraction

    private func extractPalette(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let ciImage = CIImage(data: data)
        else { return }

        isExtracting = true
        defer { isExtracting = false }

        let palette = await PhotoColorExtractor.extract(from: ciImage)
        value.palette = palette
    }
}
