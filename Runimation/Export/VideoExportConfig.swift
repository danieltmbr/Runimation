import AVFoundation
import CoreGraphics

/// Configuration for an offline video export.
///
struct VideoExportConfig: Sendable {

    /// Physical render resolution in pixels — determines texture dimensions and video output size.
    var resolution: CGSize

    /// Viewport size in logical points used for shader coordinate mapping.
    ///
    /// This must match the logical size the live shader sees so that the noise-space
    /// coordinate mapping is identical to the on-screen preview. When exporting at
    /// a scaled resolution (e.g. display scale × logical size), set this to the
    /// original logical viewport size and `resolution` to the scaled physical size.
    /// Defaults to `resolution` when not provided (correct for 1:1 exports).
    ///
    var logicalSize: CGSize

    /// Frames per second for the exported video.
    var fps: Int = 30

    /// Video codec for AVAssetWriter.
    /// HEVC (H.265) is the default — it preserves high-frequency fBM noise detail
    /// significantly better than H.264 at the same bitrate.
    var codec: AVVideoCodecType = .hevc

    init(resolution: CGSize, logicalSize: CGSize? = nil, fps: Int = 30, codec: AVVideoCodecType = .h264) {
        self.resolution = resolution
        self.logicalSize = logicalSize ?? resolution
        self.fps = fps
        self.codec = codec
    }
}
