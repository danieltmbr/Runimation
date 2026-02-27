import SwiftUI

/// A view that renders playback controls — rewind, play/pause, loop, and progress —
/// using the `PlaybackControlsStyle` from the environment.
///
/// The layout and appearance are fully determined by the active style, injected via
/// `.playbackControlsStyle(_:)`. Three built-in styles are provided:
/// - `.compact` — minimal icon row with a background progress fill (tab bar accessory)
/// - `.regular` — progress slider row + large icon row (sheet inspector)
/// - `.horizontal` — all controls in a single inline row (toolbar)
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlaybackControls: View {

    @Environment(\.playbackControlsStyle)
    private var style

    var body: some View {
        style.makeBody()
    }
}

// MARK: - Style Protocol

protocol PlaybackControlsStyle {
    associatedtype Body: View
    @ViewBuilder func makeBody() -> Body
}

// MARK: - Static Members

extension PlaybackControlsStyle where Self == CompactPlaybackControlsStyle {
    static var compact: Self { .init() }
}

extension PlaybackControlsStyle where Self == RegularPlaybackControlsStyle {
    static var regular: Self { .init() }
}

extension PlaybackControlsStyle where Self == ToolbarPlaybackControlsStyle {
    static var toolbar: Self { .init() }
}

// MARK: - View Modifier

extension View {
    func playbackControlsStyle<S: PlaybackControlsStyle>(_ style: S) -> some View {
        environment(\.playbackControlsStyle, AnyPlaybackControlsStyle(style))
    }
}

// MARK: - Type Erasure

private struct AnyPlaybackControlsStyle {
    private let _makeBody: () -> AnyView

    init<S: PlaybackControlsStyle>(_ style: S) {
        _makeBody = { AnyView(style.makeBody()) }
    }

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
