import Foundation

/// Toggles playback: plays if paused, pauses if playing.
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.togglePlay) private var togglePlay
/// togglePlay()
/// ```
///
struct TogglePlayAction {

    private let body: () -> Void

    init(_ body: @escaping () -> Void = {}) {
        self.body = body
    }

    init(player: RunPlayer) {
        self.init {
            if player.isPlaying { player.pause() } else { player.play() }
        }
    }

    func callAsFunction() { body() }
}
