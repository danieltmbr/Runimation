import Foundation

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
    public struct Runs: Equatable, Sendable {

        /// Unmodified run, good for displaying precise metrics.
        ///
        fileprivate let original: Run

        /// Transformed run, good for displaying animation diagnostics.
        ///
        fileprivate let transformed: Run

        /// Transformed & normalised run, good for driving animations.
        ///
        fileprivate let normalised: Run

        /// Returns a run data appropriate for a purpose.
        ///
        public func run(for purpose: ReadingPurpose) -> Run {
            switch purpose {
            case .metrics: return original
            case .diagnostics: return transformed
            case .animation: return normalised
            }
        }
    }

    // MARK: Dependencies

    private let parser: Run.Parser

    public var transformers: [RunTransformerOption] = [] {
        didSet {
            guard let original = runs?.original else { return }
            Task { [weak self] in try? await self?.process { original } }
        }
    }

    public private(set) var interpolator: RunInterpolatorOption = .linear {
        didSet {
            guard let original = runs?.original else { return }
            Task { [weak self] in try? await self?.process { original } }
        }
    }

    // MARK: Playback States

    public var duration: Duration = .thirtySeconds {
        didSet {
            guard let original = runs?.original else { return }
            Task { [weak self] in try? await self?.process { original } }
        }
    }

    public private(set) var isPlaying: Bool = false

    /// True while a run is being parsed, transformed, and interpolated
    /// on a background thread. The play button should be disabled during this time.
    ///
    public private(set) var isProcessing: Bool = false

    public var loop: Bool = false

    public private(set) var progress: Double = 0

    // MARK: Data

    /// The run and its transformations that the player
    /// has currently loaded and playing.
    ///
    public private(set) var runs: Runs? = nil

    private var playbackTask: Task<Void, Never>?
    
    private var processTask: Task<Runs, Never>?

    // MARK: - Init

    required init(
        parser: Run.Parser,
        transformers: [RunTransformerOption] = []
    ) {
        self.parser = parser
        self.transformers = transformers
    }

    public convenience init(transformers: [RunTransformerOption] = []) {
        self.init(parser: Run.Parser(), transformers: transformers)
    }

    // MARK: - Playback Controls

    public func play() {
        if progress >= 1 { progress = 0 }
        isPlaying = true
        startTimer()
    }

    public func pause() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }

    public func stop() {
        pause()
        progress = 0
    }

    public func seek(to progress: Double) {
        self.progress = min(1, max(0, progress))
    }

    // MARK: - Data Readings

    /// Returns the segment corresponding to the current playback
    /// progress for the given reading purpose.
    ///
    /// Uses direct index lookup — O(1) — into the pre-computed segment
    /// array rather than interpolating at runtime, so the interpolation
    /// strategy is fully owned by the `RunInterpolator` implementation.
    ///
    public func segment(for purpose: ReadingPurpose) -> Run.Segment {
        guard let run = runs?.run(for: purpose) else { return .zero }
        let segments = run.segments
        guard !segments.isEmpty else { return .zero }
        let index = min(Int(progress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    // MARK: - Configuration

    /// Loads a new run to the player.
    ///
    /// Stops the current playback and processes the run on a background
    /// thread. Cancels any in-flight processing. Resolves when the player
    /// is ready to play, or throws `CancellationError` if preempted by
    /// another `setRun` call.
    ///
    public func setRun(_ run: Run) async throws {
        stop()
        try await process { run }
    }

    /// Loads a new run to the player from a GPX track.
    ///
    /// Stops the current playback and parses + processes the track on a
    /// background thread. Cancels any in-flight processing. Resolves when
    /// the player is ready to play, or throws `CancellationError` if
    /// preempted by another `setRun` call.
    ///
    public func setRun(_ track: GPX.Track) async throws {
        stop()
        let parser = self.parser
        try await process { parser.run(from: track) }
    }

    /// Updates the transformer and reprocesses all run variants
    /// without stopping the current playback.
    ///
    /// Wraps the given transformer in an anonymous `RunTransformerOption`
    /// and replaces the entire chain with that single entry.
    ///
    public func setTransformer(_ transformer: RunTransformer) {
        let option = RunTransformerOption(
            label: "Custom",
            description: "",
            transformer: transformer
        )
        transformers = [option]
    }

    /// Swaps the active interpolator and reprocesses all run variants
    /// without stopping the current playback.
    ///
    public func setInterpolator(_ option: RunInterpolatorOption) {
        interpolator = option
    }

    // MARK: - Private

    private func advance(by dt: TimeInterval) {
        guard let runs else { return }
        let playbackDuration = duration(for: runs.original.duration)
        guard playbackDuration > 0 else { return }
        let newProgress = progress + dt / playbackDuration
        if newProgress >= 1 {
            if loop {
                progress = newProgress.truncatingRemainder(dividingBy: 1)
            } else {
                progress = 1
                pause()
            }
        } else {
            progress = newProgress
        }
    }

    /// Dispatches run building to a background thread and applies the result
    /// on the main actor when complete.
    ///
    /// Cancels any in-flight processing before starting a new task.
    /// If preempted by a subsequent call (i.e. the task was cancelled
    /// before its result could be applied), throws `CancellationError`
    /// without modifying `runs` or `isProcessing`.
    ///
    private func process(_ makeRun: @escaping @Sendable () -> Run) async throws {
        processTask?.cancel()
        isProcessing = true

        let transformers = self.transformers
        let interpolator = self.interpolator
        let duration = self.duration

        let task = Task<Runs, Never>.detached(priority: .userInitiated) {
            let run = makeRun()
            let playbackDuration = duration(for: run.duration)
            let timing = Timing(duration: playbackDuration, fps: 60)
            let chain = TransformerChain(transformers: transformers.map(\.transformer))
            let transformed = run
                .transform(by: chain)
                .interpolate(by: interpolator.interpolator, with: timing)
            return Runs(
                original: run,
                transformed: transformed,
                normalised: transformed.transform(by: .normalised)
            )
        }
        processTask = task

        let computed = await task.value
        guard !task.isCancelled else { throw CancellationError() }
        runs = computed
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

// MARK: - Segments

extension RunPlayer {

    /// A namespace for reading the current playback segment
    /// under each reading purpose, enabling KeyPath-based access:
    /// `@PlayerState(\.segment.animation)`.
    ///
    @MainActor public struct Segments {

        private let player: RunPlayer

        fileprivate init(_ player: RunPlayer) {
            self.player = player
        }

        public var animation: Run.Segment { player.segment(for: .animation) }

        public var diagnostics: Run.Segment { player.segment(for: .diagnostics) }

        public var metrics: Run.Segment { player.segment(for: .metrics) }
    }

    /// The current playback segments for all reading purposes.
    ///
    /// Updates on every playback tick because it reads from `progress`
    /// and `runs`, which are both `@Observable` stored properties.
    ///
    public var segment: Segments { Segments(self) }
}
