import CoreImage
import PhotosUI
import SwiftUI

/// Reusable palette editor: proportional color swatch strip, a photo picker
/// that extracts dominant colors via `PhotoColorExtractor`, a cluster count
/// stepper, and a reset button.
///
/// Designed to be embedded in any animation form that accepts a `ColorPalette`.
/// All transient state (picker selection, extraction progress, cluster count)
/// is managed internally.
struct ColorPalettePicker: View {

    @Binding
    var palette: ColorPalette

    @State
    private var isExtracting = false

    @State
    private var selectedItem: PhotosPickerItem?

    /// Loaded once from `selectedItem`; retained so cluster-count changes
    /// can re-trigger extraction without re-fetching from the photo library.
    @State
    private var loadedImage: CIImage?

    @State
    private var clusterCount: Double = 5

    var body: some View {
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

                if palette != .default {
                    Button("Reset") {
                        palette = .default
                        loadedImage = nil
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            LabeledContent("Number of colors:") {
                Stepper(clusterCount.formatted(), value: $clusterCount, in: 2...8, format: .number)
            }
        }
        // Load image data when a new photo is picked.
        .task(id: selectedItem) {
            guard let item = selectedItem,
                  let data = try? await item.loadTransferable(type: Data.self)
            else { return }
            loadedImage = CIImage(data: data)
        }
        // Re-extract whenever the loaded image or cluster count changes.
        .task(id: ExtractionKey(image: loadedImage, clusterCount: Int(clusterCount))) {
            guard let image = loadedImage else { return }
            isExtracting = true
            defer { isExtracting = false }
            palette = await PhotoColorExtractor.extract(
                from: image,
                clusterCount: Int(clusterCount)
            )
        }
    }

    // MARK: - Subviews

    /// Proportional color swatch strip reflecting the palette's weight distribution.
    private var colorSwatchStrip: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(palette.entries.enumerated()), id: \.offset) { _, entry in
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
}

// MARK: - Private Helpers

private extension ColorPalettePicker {

    /// Equatable key combining image identity and cluster count for `.task(id:)`.
    ///
    /// Uses `ObjectIdentifier` for the image so comparison is O(1) —
    /// a new `CIImage` instance means a new photo was loaded.
    struct ExtractionKey: Equatable {
        let imageID: ObjectIdentifier?
        let clusterCount: Int

        init(image: CIImage?, clusterCount: Int) {
            imageID = image.map(ObjectIdentifier.init)
            self.clusterCount = clusterCount
        }
    }
}
