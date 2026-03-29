import AVFoundation
import CoreGraphics
import CoreVideo
import Metal
import RunKit
import Visualiser

/// Renders a Runimation visualisation to an `.mp4` file using a raw Metal pipeline.
///
/// Each frame is rendered independently — progress is looked up via the pre-processed
/// segment array rather than running at real-time playback speed. A 2-minute
/// animation at 30 fps (3600 frames) typically takes 30–60 seconds to render.
///
/// The export pipeline uses dedicated Metal shaders (`export.metal`) compiled into
/// `Bundle.visualiser`. These mirror the live `runWarpShader` / `runPathWarpShader`
/// logic but use standard vertex + fragment functions rather than SwiftUI's
/// `[[stitchable]]` calling convention, allowing them to be driven via a plain
/// `MTLRenderCommandEncoder`.
///
struct VideoRenderer {

    // MARK: - Errors

    enum RenderError: LocalizedError {
        case noMetalDevice
        case metalLibraryNotFound
        case setupFailed(String)
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noMetalDevice:           return "No Metal device available."
            case .metalLibraryNotFound:    return "Export Metal library not found in Visualiser bundle."
            case .setupFailed(let msg):    return "Export setup failed: \(msg)"
            case .writeFailed(let error):  return "Video write failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Render

    /// Renders every frame to disk and returns the URL of the resulting `.mp4` file.
    ///
    /// - Parameters:
    ///   - segments: Pre-processed animation segments from `player.run.animation.segments`.
    ///   - path: GPS coordinates for RunPath visualisations, in normalised (-1…1) space.
    ///   - duration: Playback duration in seconds — determines total frame count.
    ///   - config: Resolution, fps, and codec settings.
    ///   - visualisation: The active visualisation (determines shader selection).
    ///   - onProgress: Called on the main actor with a 0…1 progress value after each frame.
    ///
    func render(
        segments: [Run.Segment],
        path: [CGPoint],
        duration: TimeInterval,
        config: VideoExportConfig,
        visualisation: any Visualisation,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {

        let fps = config.fps
        let totalFrames = max(1, Int(duration * Double(fps)))
        let width = Int(config.resolution.width)
        let height = Int(config.resolution.height)

        // --- Metal setup ---

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw RenderError.noMetalDevice
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw RenderError.setupFailed("Could not create command queue")
        }

        // Load the compiled .metallib from Visualiser.bundle — contains export_vertex,
        // export_warp_fragment, export_path_fragment, export_path_warp_fragment.
        guard let metalLibURL = Bundle.visualiser.url(forResource: "default", withExtension: "metallib") else {
            throw RenderError.metalLibraryNotFound
        }
        let library = try device.makeLibrary(URL: metalLibURL)

        let (vertexFunction, fragmentFunction) = try shaderFunctions(
            library: library,
            visualisation: visualisation
        )
        let pipeline = try makePipeline(
            device: device,
            vertex: vertexFunction,
            fragment: fragmentFunction
        )

        // Palette texture (Warp only)
        let paletteTexture: MTLTexture? = (visualisation as? Warp).map {
            try? makePaletteTexture(device: device, palette: $0.palette)
        } ?? nil

        // Path buffer + simplified point count (RunPath only).
        // RDP epsilon is computed from logicalSize to match the live RunPathView.
        let (pathBuffer, pathCount): (MTLBuffer?, Int32) = try makePathData(
            device: device,
            path: path,
            visualisation: visualisation,
            logicalSize: config.logicalSize
        )

        // Offscreen render target
        let renderTexture = try makeRenderTexture(device: device, width: width, height: height)

        // --- AVAssetWriter setup ---

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        // 30 Mbps average bitrate with HEVC — fBM noise has high spatial-frequency
        // content that compresses poorly; generous bitrate preserves the fine detail.
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: config.codec.rawValue,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 30_000_000,
                AVVideoMaxKeyFrameIntervalKey: config.fps,
                AVVideoExpectedSourceFrameRateKey: config.fps
            ]
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        // --- Frame loop ---

        for i in 0..<totalFrames {
            let progress = totalFrames > 1 ? Double(i) / Double(totalFrames - 1) : 0.0
            let time = Float(progress * duration)
            let segment = segments.isEmpty ? Run.Segment.zero : segments[segmentIndex(at: progress, count: segments.count)]

            let pixelBuffer = try await renderFrame(
                device: device,
                commandQueue: commandQueue,
                pipeline: pipeline,
                renderTexture: renderTexture,
                time: time,
                segment: segment,
                pathBuffer: pathBuffer,
                pathCount: pathCount,
                logicalSize: config.logicalSize,
                visualisation: visualisation,
                paletteTexture: paletteTexture
            )

            let presentationTime = CMTime(value: CMTimeValue(i), timescale: CMTimeScale(fps))
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)

            await MainActor.run { onProgress(Double(i + 1) / Double(totalFrames)) }
        }

        writerInput.markAsFinished()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting { continuation.resume() }
        }
        if let error = writer.error { throw RenderError.writeFailed(error) }

        return outputURL
    }

    // MARK: - Frame Rendering

    private func renderFrame(
        device: MTLDevice,
        commandQueue: MTLCommandQueue,
        pipeline: MTLRenderPipelineState,
        renderTexture: MTLTexture,
        time: Float,
        segment: Run.Segment,
        pathBuffer: MTLBuffer?,
        pathCount: Int32,
        logicalSize: CGSize,
        visualisation: any Visualisation,
        paletteTexture: MTLTexture?
    ) async throws -> CVPixelBuffer {

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw RenderError.setupFailed("Could not create command buffer")
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw RenderError.setupFailed("Could not create render encoder")
        }
        encoder.setRenderPipelineState(pipeline)

        if visualisation is Warp {
            try encodeWarpUniforms(
                encoder: encoder,
                device: device,
                time: time,
                segment: segment,
                logicalSize: logicalSize,
                visualisation: visualisation as! Warp,
                paletteTexture: paletteTexture
            )
        } else {
            try encodePathUniforms(
                encoder: encoder,
                device: device,
                time: time,
                segment: segment,
                logicalSize: logicalSize,
                pathBuffer: pathBuffer,
                pathCount: pathCount
            )
        }

        // Full-screen triangle: 3 vertices, no vertex buffer needed
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        // Await GPU completion using a continuation (non-blocking)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            commandBuffer.addCompletedHandler { buffer in
                if let error = buffer.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            commandBuffer.commit()
        }

        return try readbackPixelBuffer(from: renderTexture)
    }

    // MARK: - Uniform Encoding

    private func encodeWarpUniforms(
        encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        time: Float,
        segment: Run.Segment,
        logicalSize: CGSize,
        visualisation: Warp,
        paletteTexture: MTLTexture?
    ) throws {
        let elevation = Float(segment.elevation)
        let elevationOffset = (1.0 - Double(elevation) - 0.5) * 0.3
        let h = Float(max(0, min(1, visualisation.smoothness + elevationOffset)))

        var uniforms = WarpUniforms(
            time: time,
            octaves: Float(visualisation.details),
            h: h,
            scale: 0.007,
            speed: Float(segment.speed),
            heartRate: Float(segment.heartRate),
            dirX: Float(segment.direction.x),
            dirY: Float(segment.direction.y),
            offsetX: 0,
            offsetY: 0,
            sizeX: Float(logicalSize.width),
            sizeY: Float(logicalSize.height)
        )
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<WarpUniforms>.size, index: 0)

        if let palette = paletteTexture {
            encoder.setFragmentTexture(palette, index: 0)
        }
    }

    private func encodePathUniforms(
        encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        time: Float,
        segment: Run.Segment,
        logicalSize: CGSize,
        pathBuffer: MTLBuffer?,
        pathCount: Int32
    ) throws {
        var uniforms = PathUniforms(
            time: time,
            sizeX: Float(logicalSize.width),
            sizeY: Float(logicalSize.height),
            scale: 2.0,
            offsetX: 0,
            offsetY: 0,
            coordinatesX: Float(segment.coordinate.x),
            coordinatesY: Float(segment.coordinate.y),
            directionX: Float(segment.direction.x),
            directionY: Float(segment.direction.y),
            elevation: Float(segment.elevation),
            heartRate: Float(segment.heartRate),
            speed: Float(segment.speed)
        )
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<PathUniforms>.size, index: 0)

        if let pathBuffer {
            encoder.setFragmentBuffer(pathBuffer, offset: 0, index: 1)
        }
        var count = pathCount
        encoder.setFragmentBytes(&count, length: MemoryLayout<Int32>.size, index: 2)
    }

    // MARK: - Texture Readback

    private func readbackPixelBuffer(from texture: MTLTexture) throws -> CVPixelBuffer {
        let width = texture.width
        let height = texture.height

        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let pb = pixelBuffer else {
            throw RenderError.setupFailed("Could not create CVPixelBuffer")
        }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pb)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pb) else {
            throw RenderError.setupFailed("Could not get pixel buffer base address")
        }

        texture.getBytes(
            baseAddress,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(origin: MTLOriginMake(0, 0, 0), size: MTLSizeMake(width, height, 1)),
            mipmapLevel: 0
        )
        return pb
    }

    // MARK: - Setup Helpers

    private func shaderFunctions(
        library: MTLLibrary,
        visualisation: any Visualisation
    ) throws -> (MTLFunction, MTLFunction) {
        guard let vertex = library.makeFunction(name: "export_vertex") else {
            throw RenderError.setupFailed("export_vertex shader not found")
        }
        let fragmentName: String
        switch visualisation {
        case is Warp:    fragmentName = "export_warp_fragment"
        case is RunPath: fragmentName = "export_path_warp_fragment"
        default:         fragmentName = "export_warp_fragment"
        }
        guard let fragment = library.makeFunction(name: fragmentName) else {
            throw RenderError.setupFailed("\(fragmentName) shader not found")
        }
        return (vertex, fragment)
    }

    private func makePipeline(
        device: MTLDevice,
        vertex: MTLFunction,
        fragment: MTLFunction
    ) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func makePaletteTexture(device: MTLDevice, palette: ColorPalette) throws -> MTLTexture {
        let cgImage = PaletteGradientRenderer.render(palette)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cgImage.width,
            height: cgImage.height,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw RenderError.setupFailed("Could not create palette texture")
        }
        let region = MTLRegion(origin: MTLOriginMake(0, 0, 0), size: MTLSizeMake(cgImage.width, 1, 1))
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: cgImage.width, height: 1, bitsPerComponent: 8,
                            bytesPerRow: cgImage.width * 4, space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: 1))
        if let data = ctx.data {
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: cgImage.width * 4)
        }
        return texture
    }

    private func makePathData(
        device: MTLDevice,
        path: [CGPoint],
        visualisation: any Visualisation,
        logicalSize: CGSize
    ) throws -> (MTLBuffer?, Int32) {
        guard !(visualisation is Warp), path.count > 1 else { return (nil, 0) }

        // Apply RDP simplification using the same epsilon as RunPathView's overview mode.
        // logicalSize.height matches the viewport height the live shader sees.
        let simd = path.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        let overviewEpsilon = Float(2.0 * 10.0 / (logicalSize.height / 2.0))
        let indices = PathSimplifier.rdp(simd, epsilon: overviewEpsilon)
        let simplified = simd.enumerated().compactMap { indices.contains($0.offset) ? $0.element : nil }

        guard !simplified.isEmpty else { return (nil, 0) }
        let buffer = device.makeBuffer(bytes: simplified,
                                       length: simplified.count * MemoryLayout<SIMD2<Float>>.stride,
                                       options: .storageModeShared)
        return (buffer, Int32(simplified.count))
    }

    private func makeRenderTexture(device: MTLDevice, width: Int, height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw RenderError.setupFailed("Could not create render texture")
        }
        return texture
    }

    // MARK: - Helpers

    private func segmentIndex(at progress: Double, count: Int) -> Int {
        min(Int(progress * Double(count)), count - 1)
    }
}

// MARK: - Uniform Structs (must match export.metal layout)

private struct WarpUniforms {
    var time: Float
    var octaves: Float
    var h: Float
    var scale: Float
    var speed: Float
    var heartRate: Float
    var dirX: Float
    var dirY: Float
    var offsetX: Float
    var offsetY: Float
    var sizeX: Float
    var sizeY: Float
}

private struct PathUniforms {
    var time: Float
    var sizeX: Float
    var sizeY: Float
    var scale: Float
    var offsetX: Float
    var offsetY: Float
    var coordinatesX: Float
    var coordinatesY: Float
    var directionX: Float
    var directionY: Float
    var elevation: Float
    var heartRate: Float
    var speed: Float
}
