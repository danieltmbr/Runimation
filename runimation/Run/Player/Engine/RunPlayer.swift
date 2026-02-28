import Foundation

@Observable
final class RunPlayer {

    /// Reading purpose indicates the player how the data
    /// is inteded to use so it can provide the most suitable
    /// one to a given request.
    ///
    enum ReadingPurpose: Equatable, Sendable {

        /// Reads values from the original run to provide
        /// the most accurate data to the consumer.
        ///
        case metrics

        /// Reads values from the transformed run to
        /// provide an insight of how the data will be used.
        ///
        case diagnostics

        /// Reads values from the normalised run that
        /// can be leveraged to drive animations.
        ///
        case animation
    }

    /// Runs stores the data set that the player is currently
    /// working with.
    ///
    /// The `transformed` and `normalised` runs are
    /// always derived from the `original` run.
    ///
    struct Runs: Equatable, Sendable {

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
        func run(for purpose: ReadingPurpose) -> Run {
            switch purpose {
            case .metrics:
                return original
            case .diagnostics:
                return transformed
            case .animation:
                return normalised
            }
        }
    }

    // MARK: Dependencies

    private let parser: Run.Parser

    var selectedTransformers: [RunTransformerOption] = [] {
        didSet { recompute(run: runs?.original) }
    }

    var interpolatorOption: RunInterpolatorOption = .linear {
        didSet { recompute(run: runs?.original) }
    }

    // MARK: Playback States

    var duration: Duration = .thirtySeconds {
        didSet { recompute(run: runs?.original) }
    }

    private(set) var isPlaying: Bool = false

    var loop: Bool = false

    private(set) var progress: Double = 0

    // MARK: Data

    /// The run and its transformations that the player
    /// has currently loaded and playing.
    ///
    private(set) var runs: Runs? = nil

    private var playbackTask: Task<Void, Never>?

    // MARK: - Init

    init(
        parser: Run.Parser,
        transformers: [RunTransformerOption] = []
    ) {
        self.parser = parser
        self.selectedTransformers = transformers
    }

    // MARK: - Playback Controls

    func play() {
        if progress >= 1 { progress = 0 }
        isPlaying = true
        startTimer()
    }

    func pause() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }

    func stop() {
        pause()
        progress = 0
    }

    func seek(to progress: Double) {
        self.progress = min(1, max(0, progress))
    }

    // MARK: - Data readings

    /// Returns the segment corresponding to the current playback
    /// progress for the given reading purpose.
    ///
    /// Uses direct index lookup — O(1) — into the pre-computed segment
    /// array rather than interpolating at runtime, so the interpolation
    /// strategy is fully owned by the `RunInterpolator` implementation.
    ///
    func segment(for purpose: ReadingPurpose) -> Run.Segment {
        guard let run = runs?.run(for: purpose) else { return .zero }
        let segments = run.segments
        guard !segments.isEmpty else { return .zero }
        let index = min(Int(progress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    // MARK: - Configuration

    /// Loads a new run to the player for playing.
    ///
    /// Setting a run stops the current playback.
    /// After changing the run the playback has to
    /// be started manually via the `play()` method.
    ///
    func setRun(_ run: Run) {
        stop()
        recompute(run: run)
    }

    /// Loads a new run to the player for playing
    /// from a GPX track.
    ///
    /// Setting a run stops the current playback.
    /// After changing the run the playback has to
    /// be started manually via the `play()` method.
    ///
    func setRun(_ track: GPX.Track) {
        setRun(parser.run(from: track))
    }

    /// Updates the transformer and recomputes all run variants
    /// without stopping the current playback.
    ///
    /// Wraps the given transformer in an anonymous `RunTransformerOption`
    /// and replaces the entire chain with that single entry.
    ///
    func setTransformer(_ transformer: RunTransformer) {
        let option = RunTransformerOption(
            label: "Custom",
            description: "",
            transformer: transformer
        )
        selectedTransformers = [option]
    }

    /// Swaps the active interpolator and recomputes all run variants
    /// without stopping the current playback.
    ///
    func setInterpolator(_ option: RunInterpolatorOption) {
        interpolatorOption = option
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
    
    private func recompute(run: Run? = nil) {
        guard let run else { return reset() }
        let playbackDuration = duration(for: run.duration)
        let timing = Timing(duration: playbackDuration, fps: 60)
        let chain = TransformerChain(transformers: selectedTransformers.map(\.transformer))
        let transformed = run
            .transform(by: chain)
            .interpolate(
                by: interpolatorOption.interpolator,
                with: timing
            )
        runs = Runs(
            original: run,
            transformed: transformed,
            normalised: transformed.transform(by: .normalised)
        )
    }
    
    private func reset() {
        stop()
        runs = nil
    }

    private func startTimer() {
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
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
    /// `@PlayerState(\.segments.animation)`.
    ///
    struct Segments {

        private let player: RunPlayer

        fileprivate init(_ player: RunPlayer) {
            self.player = player
        }

        var animation: Run.Segment { player.segment(for: .animation) }

        var diagnostics: Run.Segment { player.segment(for: .diagnostics) }

        var metrics: Run.Segment { player.segment(for: .metrics) }
    }

    /// The current playback segments for all reading purposes.
    ///
    /// Updates on every playback tick because it reads from `progress`
    /// and `runs`, which are both `@Observable` stored properties.
    ///
    var segment: Segments { Segments(self) }
}
