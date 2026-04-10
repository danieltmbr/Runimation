/// A namespace for reading playback progress at different sampling rates.
///
/// Use `@PlayerState(\.progress.animation)` for 30fps animation updates.
/// Use `@PlayerState(\.progress.metrics)` for 24fps metric label updates.
///
@dynamicMemberLookup
public struct ProgressValues {

    private let player: RunPlayer

    fileprivate init(_ player: RunPlayer) { self.player = player }

    @MainActor
    public subscript(dynamicMember keyPath: KeyPath<RunPlayer.Variant.Type, RunPlayer.Variant>) -> Double {
        player.sampler(at: RunPlayer.Variant.self[keyPath: keyPath].fps).value
    }
}

extension RunPlayer {

    /// The current playback progress under each variant's sampling rate.
    ///
    public var progress: ProgressValues { ProgressValues(self) }
}
