import Observation

/// Emits a player's `_progress` at a fixed FPS as an `@Observable` value.
///
/// The player creates one instance per unique FPS and stores it strongly.
/// `deinit` cancels the task when the player is freed.
///
@MainActor @Observable
final class ProgressSampler {

    let fps: Int
    
    private(set) var value: Double = 0

    @ObservationIgnored
    private var task: Task<Void, Never>?
    
    private let source: @MainActor () -> Double

    init(fps: Int, source: @escaping @MainActor () -> Double) {
        self.fps = fps
        self.source = source
    }

    deinit { task?.cancel() }

    func start() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            let interval = Duration.seconds(1.0 / Double(fps))
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                let new = source()
                if new != value { value = new }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    /// Immediately syncs `value` from source — call after seek/stop.
    ///
    func sync() {
        let new = source()
        if new != value { value = new }
    }
}
