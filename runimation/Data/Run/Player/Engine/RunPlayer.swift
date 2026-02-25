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
    
    // TODO: Discuss this
    //
    // I'm not entirely sure how valuable this struct is
    // or if we need it at all.
    //
    // I guess the graphs just gonna display the full data
    // set that will be stored and acces from the `Runs`
    // and not a stream of individual data points.
    //
    // A stream of individual (normalised) data points would
    // be great for driving the animation. But I'm not sure
    // that's the only use case we have. If so maybe we could
    // just have a single
    //
    // Also, probably the current data point (current means
    // data point that should be presented for the current
    // progress state of the player) don't need to be stored
    // as a state. It's basically derived from the `Runs` and
    // the progress. I GUESS
    //
    struct Values: Equatable, Sendable {
        
        /// Unmodified data point, good for displaying precise metrics.
        ///
        fileprivate let original: Run.Segment
        
        /// Transformed data point, good for displaying diagnostics.
        ///
        fileprivate let transformed: Run.Segment
        
        /// Transformed & normalised data point to drive animation.
        ///
        fileprivate let normalised: Run.Segment
        
        /// Returns a data point appropriate for a purpose.
        ///
        func run(for purpose: ReadingPurpose) -> Run.Segment {
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
    
    // TODO: Discuss
    //
    // I imagine a AsyncSequence based timer that can be
    // than mapped to a AsyncSequence of data points that
    // always emits the appropriate gata point of a run
    // based on the timer/progress for a specific reading
    // purpose.
    //
    private let timer: ???
    
    private var transformer: RunTransformer
    
    // MARK: Playback States
    
    var duration: Duration = .fifteenSeconds
    
    private(set) var isPlaying: Bool = false
    
    var loop: Bool = false
    
    private(set) var progress: Double = 0
    
    // MARK: Data
    
    // TODO: Discuss
    //
    // I'm not sure if this should be publicly
    // accessible. Since the Player is `Observable`
    // it might be good expose this so it updates
    // the consumers when the run has been changed.
    //
    /// The run and its transformations that the player
    /// has currently loaded and playing.
    ///
    private(set) var runs: Runs? = nil
        
    // MARK: - Init
    
    init(
        parser: Run.Parser,
        timer: ???,
        transformer: RunTransformer
    ) {
        self.parser = parser
        self.timer = timer
        self.transformer = transformer
    }
    
    // MARK: - Playback Controls
    
    func play() { ... }
    
    func pause() { ... }
    
    func stop() { ... }
    
    func seek(to progress: Double) { ... }
    
    // MARK: - Data readings
    
    // TODO: Discuss
    //
    // I guess the main purpose of this is to get a stream
    // that drives the animation. What I don't know is how the
    // animation is being driven right now.
    //
    // I think the segments from the `Runs` needs to be
    // interpolated. Otherwise the animation can "hang"
    // especially in the "real time" playback.
    //
    // If we only work with the given data points, in the
    // "real-time" playback we only change the parameters
    // of the warping every 5 or 10 seconds... Instead of
    // creating a smooth 30 or 60 FPS animation.
    //
    // This also raises the question where should that
    // interpolation live. As a first idea I was thinking
    // that an interpolation is basically just another
    // `RunTransformer`, but apart from changing the
    // values in the data points, it also injects more
    // data points to guarantee a smooth 30-60 FPS for
    // the animation.
    //
    // Would be cool if this interpolator could be swapped
    // as well in the player so we can see how different
    // interpolation methods changes the animation.
    //
    // But now that I'm saying things like "to see how
    // different interpolation method changes tha animation"
    // it makes me think that it might need to be part
    // of the transformer chain. Because we might want
    // to see the interpolation on the diagnostics.
    //
    func stream(for purpose: ReadingPurpose) -> AsyncStream<Run.Segment> {
        ...
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
        let transformed = run.transform(by: transformer)
        runs = Runs(
            original: run,
            transformed: transformed,
            normalised: transformed.transform(by: .normalised)
        )
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
    
    // TODO: Discuss: Changing the transformation
    // shouldn't stop the playback, it would be cool
    // to see the jump and get the sense how a changed
    // transformer changes the output compared to
    // the previous one. However this might make the
    // data stream a bit more complicated.
    //
    /// Updates the transformer and the current
    /// runs with the new transformation.
    ///
    func setTransformer(_ transformer: RunTransformer) {
        self.transformer = transformer
    }
}
