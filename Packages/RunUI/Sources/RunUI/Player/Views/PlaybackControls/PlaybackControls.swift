import SwiftUI

/// A view that renders playback controls — rewind, play/pause, loop, and progress —
/// using the `PlaybackControlsStyle` from the environment.
///
/// The layout and appearance are fully determined by the active style, injected via
/// `.playbackControlsStyle(_:)`. Three built-in styles are provided:
/// - `.compact` — run name + play toggle with background progress fill (compact size class / iPhone)
/// - `.regular` — inline transport + progress row (regular size class / iPad, Mac bottom bar)
/// - `.panel` — progress slider row + large icon row (playback detail sheet)
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct PlaybackControls: View {

    @Environment(\.playbackControlsStyle)
    private var style

    public init() {}

    public var body: some View {
        style.makeBody()
    }
}

// MARK: - Style Protocol

public protocol PlaybackControlsStyle: Sendable {
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody() -> Body
}

// MARK: - Static Members

extension PlaybackControlsStyle where Self == CompactPlaybackControlsStyle {
    public static var compact: Self { .init() }
}

extension PlaybackControlsStyle where Self == RegularPlaybackControlsStyle {
    public static var regular: Self { .init() }
}

extension PlaybackControlsStyle where Self == PanelPlaybackControlsStyle {
    public static var panel: Self { .init() }
}

// MARK: - View Modifier

extension View {
    public func playbackControlsStyle<S: PlaybackControlsStyle>(_ style: S) -> some View {
        environment(\.playbackControlsStyle, AnyPlaybackControlsStyle(style))
    }
}

// MARK: - Type Erasure

private struct AnyPlaybackControlsStyle: @unchecked Sendable {
    private let _makeBody: @MainActor () -> AnyView

    init<S: PlaybackControlsStyle>(_ style: S) {
        _makeBody = { AnyView(style.makeBody()) }
    }

    @MainActor
    func makeBody() -> some View {
        _makeBody()
    }
}

// MARK: - Environment

private struct PlaybackControlsStyleKey: EnvironmentKey {
    static let defaultValue = AnyPlaybackControlsStyle(CompactPlaybackControlsStyle())
}

private extension EnvironmentValues {
    var playbackControlsStyle: AnyPlaybackControlsStyle {
        get { self[PlaybackControlsStyleKey.self] }
        set { self[PlaybackControlsStyleKey.self] = newValue }
    }
}
