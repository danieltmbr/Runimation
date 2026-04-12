import Foundation
import CoreKit

/// RunPlayer manages the loading, processing, and playback of a `Run`.
///
/// All state is isolated to the main actor, matching the `@Observable`
/// requirement for SwiftUI integration. Heavy work (parsing, transforming,
/// interpolating) is dispatched to a background thread via `Task.detached`
/// and the result is applied back on the main actor when complete.
///
@MainActor @Observable
public final class RunPlayer {

    /// Runs stores the data set that the player is currently
    /// working with.
    ///
    /// The `transformed` and `normalised` runs are
    /// always derived from the `original` run.
    ///
    @dynamicMemberLookup
    public struct Runs: Equatable, Sendable {

        /// Runs with zero segments and all zero spectrums
        ///
        public static let zero = Runs(original: .sedentary, transformed: .sedentary, normalised: .sedentary)

        /// The identifier linking this set of runs back to their `RunRecord`.
        ///
        public var id: RunID { original.id }

        /// Unmodified run, good for displaying precise metrics.
        ///
        fileprivate let original: Run

        /// Transformed run, good for displaying animation diagnostics.
        ///
        fileprivate let transformed: Run

        /// Transformed & normalised run, good for driving animations.
        ///
        fileprivate let normalised: Run

        /// Returns a run appropriate for the given variant's purpose.
        ///
        public func callAsFunction(for purpose: Variant.Purpose) -> Run {
            switch purpose {
            case .metrics:     return original
            case .diagnostics: return transformed
            case .animation:   return normalised
            }
        }

        public subscript(dynamicMember keyPath: KeyPath<Variant.Type, Variant>) -> Run {
            callAsFunction(for: Variant.self[keyPath: keyPath].purpose)
        }
    }

    /// A namespace for reading the current playback segment
    /// under each reading variant, enabling KeyPath-based access:
    /// `@Player(\.segment.animation)`.
    ///
    @dynamicMemberLookup
    @MainActor public struct Segments {

        private let player: RunPlayer

        fileprivate init(_ player: RunPlayer) {
            self.player = player
        }

        public subscript(dynamicMember keyPath: KeyPath<Variant.Type, Variant>) -> Run.Segment {
            let variant = Variant.self[keyPath: keyPath]
            return player.segment(for: variant.purpose, at: player.sampler(at: variant.fps).value)
        }
    }

    // MARK: Dependencies

    public private(set) var transformers: [any RunTransformer] = []

    public private(set) var interpolator: any RunInterpolator = SmoothStepRunInterpolator()

    // MARK: Playback States

    public var duration: TimeInterval = 30

    public private(set) var isPlaying: Bool = false

    /// True while a run is being parsed, transformed, and interpolated
    /// on a background thread. The play button should be disabled during this time.
    ///
    public private(set) var isProcessing: Bool = false

    public var loop: Bool = false

    // MARK: Data

    /// The run and its transformations that the player
    /// has currently loaded and playing.
    ///
    public private(set) var run: Runs = .zero

    /// The current playback segments for all reading variants.
    ///
    public var segment: Segments { Segments(self) }

    @ObservationIgnored
    private var _progress: Double = 0

    @ObservationIgnored
    private var playbackTask: Task<Void, Never>?

    @ObservationIgnored
    private var samplers: [Int: ProgressSampler] = [:]

    private var processTask: Task<Runs, Never>?

    // MARK: - Init

    public init(
        transformers: [any RunTransformer] = [],
        interpolator: any RunInterpolator = .linear
    ) {
        self.transformers = transformers
        self.interpolator = interpolator
    }

    // MARK: - Playback Controls

    public func play() {
        if _progress >= 1 { _progress = 0 }
        isPlaying = true
        startTimer()
        samplers.values.forEach { $0.start() }
    }

    public func pause() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
        samplers.values.forEach { $0.stop() }
    }

    public func stop() {
        pause()
        _progress = 0
        syncSamplers()
    }

    public func seek(to progress: Double) {
        _progress = progress.clamped(0, 1)
        syncSamplers()
    }

    // MARK: - Data Readings

    /// Returns the segment corresponding to the current playback
    /// progress for the given variant's purpose.
    ///
    /// Uses direct index lookup — O(1) — into the pre-computed segment
    /// array rather than interpolating at runtime, so the interpolation
    /// strategy is fully owned by the `RunInterpolator` implementation.
    ///
    public func segment(
        for purpose: Variant.Purpose,
        at progress: Double
    ) -> Run.Segment {
        let segments = run(for: purpose).segments
        guard !segments.isEmpty else { return .zero }
        let index = min(Int(progress.clamped(0, 1) * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    // MARK: - Configuration
    
    /// Updates the playback duration and reprocesses the current run.
    ///
    /// Resolves when the player is ready to play with the new duration,
    /// or throws `CancellationError` if preempted by another processing call.
    ///
    public func setDuration(_ newValue: TimeInterval) async throws {
        duration = newValue
        let original = run.original
        try await process { original }
    }

    /// Updates the interpolation strategy and reprocesses the current run.
    ///
    /// Resolves when the player is ready to play with the new interpolator,
    /// or throws `CancellationError` if preempted by another processing call.
    ///
    public func setInterpolator(_ newValue: any RunInterpolator) async throws {
        interpolator = newValue
        let original = run.original
        try await process { original }
    }

    /// Loads a new run to the player.
    ///
    /// Stops the current playback and processes the run on a background
    /// thread. Cancels any in-flight processing. Resolves when the player
    /// is ready to play, or throws `CancellationError` if preempted by
    /// another `setRun` call.
    ///
    public func setRun(_ newRun: Run) async throws {
        stop()
        try await process { newRun }
    }

    /// Loads a new run to the player from a GPX track.
    ///
    /// Stops the current playback and parses + processes the track on a
    /// background thread. Cancels any in-flight processing. Resolves when
    /// the player is ready to play, or throws `CancellationError` if
    /// preempted by another `setRun` call.
    ///
    public func setRun(
        _ track: GPX.Track,
        parser: Run.Parser = .init()
    ) async throws {
        stop()
        try await process { parser.run(from: track) }
    }
    
    /// Updates the signal processing chain and reprocesses the current run.
    ///
    /// Resolves when the player is ready to play with the new transformers,
    /// or throws `CancellationError` if preempted by another processing call.
    ///
    public func setTransformers(_ transformers: [any RunTransformer]) async throws {
        self.transformers = transformers
        let original = run.original
        try await process { original }
    }

    // MARK: - Private

    func sampler(at fps: Int) -> ProgressSampler {
        if let existing = samplers[fps] { return existing }
        let sampler = ProgressSampler(fps: fps) { [weak self] in self?._progress ?? 0 }
        if isPlaying { sampler.start() }
        samplers[fps] = sampler
        return sampler
    }

    private func syncSamplers() {
        samplers.values.forEach { $0.sync() }
    }

    private func advance(by dt: TimeInterval) {
        guard duration > 0 else { return }
        let newProgress = _progress + dt / duration
        if newProgress >= 1 {
            if loop {
                _progress = newProgress.truncatingRemainder(dividingBy: 1)
            } else {
                _progress = 1
                pause()
            }
        } else {
            _progress = newProgress
        }
    }

    /// Dispatches run building to a background thread and applies the result
    /// on the main actor when complete.
    ///
    /// Cancels any in-flight processing before starting a new task.
    /// If preempted by a subsequent call (i.e. the task was cancelled
    /// before its result could be applied), throws `CancellationError`
    /// without modifying `run` or `isProcessing`.
    ///
    private func process(_ makeRun: @escaping @Sendable () -> Run) async throws {
        processTask?.cancel()
        isProcessing = true

        let transformers = self.transformers
        let interpolator = self.interpolator
        let duration = self.duration

        let task = Task<Runs, Never>.detached(priority: .userInitiated) {
            let rawRun = makeRun()
            let timing = Timing(duration: duration, fps: 30)
            let transformed = transformers.reduce(rawRun) { $0.transform(by: $1) }
            return Runs(
                original: rawRun,
                transformed: transformed.interpolate(by: interpolator, with: timing),
                normalised: transformed.transform(by: NormalisedRun()).interpolate(by: interpolator, with: timing)
            )
        }
        processTask = task

        let computed = await task.value
        guard !task.isCancelled else { throw CancellationError() }
        run = computed
        isProcessing = false
    }

    private func startTimer() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            let clock = ContinuousClock()
            var last = clock.now
            while !Task.isCancelled {
                try? await clock.sleep(for: .milliseconds(16))
                let now = clock.now
                let dt = min((now - last).asTimeInterval, 0.030)
                last = now
                self?.advance(by: dt)
            }
        }
    }
}

private extension Duration {
    var asTimeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) * 1e-18
    }
}
