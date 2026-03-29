import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// Sheet presenting two export options for the currently playing run.
///
/// - **Runimation file (.runi)** — instant: encodes the run + config as a few-kB JSON file
///   and opens the system share sheet immediately. Works for AirDrop, Messages, etc.
/// - **Video (.mp4)** — renders the animation offline via `VideoRenderer`, shows a progress
///   bar while rendering, then opens the share sheet automatically when done.
///
/// Requires `@NowPlaying`, `@Environment(\.exportRuni)`, and `@Environment(\.exportVideo)`
/// in the environment (injected by `.export(player:)` and `.library(_:)`).
///
struct ExportSheet: View {

    // MARK: - Environment

    @NowPlaying
    private var nowPlaying

    @Environment(\.exportRuni)
    private var exportRuni
    
    @Environment(\.exportVideo)
    private var exportVideo
    
    @Environment(\.displayScale)
    private var displayScale
    
    @State
    private var isRenderingVideo = false
    
    @State
    private var videoProgress: Double = 0
    
    @State
    private var renderedVideoURL: URL?
    
    @State
    private var renderError: Error?

    let viewportSize: CGSize

    private var resolution: CGSize {
        CGSize(
            width: viewportSize.width * displayScale,
            height: viewportSize.height * displayScale
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            title

            VStack(spacing: 12) {
                runiShareButton
                videoSection
            }
        }
        .padding(24)
        .frame(minWidth: 280)
        .presentationCompactAdaptation(.sheet)
    }

    // MARK: - Subviews

    private var title: some View {
        Text("Share as…")
            .font(.title2.bold())
    }

    private var runiShareButton: some View {
        Group {
            if let doc = exportRuni(nowPlaying.record) {
                ShareLink(
                    item: doc,
                    preview: SharePreview(nowPlaying.name, image: Image(systemName: "figure.run"))
                ) {
                    ExportOptionRow(
                        icon: "doc.badge.arrow.up",
                        title: "Runimation File",
                        subtitle: "A few kB · plays back in Runimation"
                    )
                }
                .buttonStyle(.plain)
            } else {
                ExportOptionRow(
                    icon: "doc.badge.arrow.up",
                    title: "Runimation File",
                    subtitle: "Run data not loaded yet"
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var videoSection: some View {
        if isRenderingVideo {
            renderingProgress
        } else if let url = renderedVideoURL {
            ShareLink(
                item: RenderedVideo(url: url, name: nowPlaying.name),
                preview: SharePreview(nowPlaying.name, image: Image(systemName: "video"))
            ) {
                ExportOptionRow(
                    icon: "video.badge.checkmark",
                    title: "Video",
                    subtitle: "Tap to share the rendered video"
                )
            }
            .buttonStyle(.plain)
        } else {
            Button { startVideoExport() } label: {
                ExportOptionRow(
                    icon: "video",
                    title: "Video (.mp4)",
                    subtitle: "Renders offline — takes a few seconds"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var renderingProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Rendering video…", systemImage: "video")
                .font(.headline)
            ProgressView(value: videoProgress)
                .progressViewStyle(.linear)
            Text("\(Int(videoProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Video Export

    private func startVideoExport() {
        isRenderingVideo = true
        videoProgress = 0
        renderedVideoURL = nil
        renderError = nil

        let config = VideoExportConfig(resolution: resolution, logicalSize: viewportSize)
        let record = nowPlaying.record

        Task {
            do {
                let url = try await exportVideo(record, config: config) { @Sendable progress in
                    Task { @MainActor in
                        videoProgress = progress
                    }
                }
                isRenderingVideo = false
                renderedVideoURL = url
            } catch {
                isRenderingVideo = false
                renderError = error
            }
        }
    }
}

// MARK: - Rendered Video

/// A typed wrapper around the rendered video URL.
///
/// Declaring `exportedContentType: .mpeg4Movie` gives the system the UTType hint
/// it needs to show "Save to Photos" and "Save to File" in the macOS share sheet,
/// and avoids the double-paste issue that occurs when sharing a raw `URL` (which
/// carries both a file representation and a URL string representation).
///
private struct RenderedVideo: Transferable {

    let url: URL
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .mpeg4Movie) { video in
            SentTransferredFile(video.url)
        }
    }
}

// MARK: - Export Option Row

/// A tappable row presenting one export option with icon, title and subtitle.
///
private struct ExportOptionRow: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}
