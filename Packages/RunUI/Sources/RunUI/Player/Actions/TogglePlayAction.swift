import Foundation
import RunKit

/// Toggles playback: plays if paused, pauses if playing.
///
/// Inject via `.player(_:)` and access in views with:
/// ```swift
/// @Environment(\.togglePlay) private var togglePlay
/// togglePlay()
/// ```
///
public struct TogglePlayAction {

    private let body: @MainActor () -> Void

    init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    init(player: RunPlayer) {
        self.init {
            if player.isPlaying { player.pause() } else { player.play() }
        }
    }

    @MainActor
    public func callAsFunction() { body() }
}
