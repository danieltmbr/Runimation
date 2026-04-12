import SwiftUI
import RunKit

/// A view that reflects and controls the player's playback progress.
///
/// Reads progress via `@Player` and commits seeks via `SeekAction`.
/// The appearance and interaction mechanism are controlled by
/// `progressSliderStyle(_:)`:
/// - `.system` (default): native SwiftUI `Slider`
/// - `.minimal`: a thin capsule bar with a drag-to-scrub gesture
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct ProgressSlider: View {

    @Environment(\.progressSliderStyle)
    private var style

    @Environment(\.seek)
    private var seek

    @Player(\.progress.animation)
    private var progress

    public init() {}

    public var body: some View {
        style.makeBody(configuration: configuration)
    }

    private var configuration: ProgressSliderStyleConfiguration {
        ProgressSliderStyleConfiguration(
            progress: $progress,
            seek: { seek(to: $0) }
        )
    }
}

// MARK: - Environment

private struct AnyProgressSliderStyle: @unchecked Sendable {
    private let _makeBody: @MainActor (ProgressSliderStyleConfiguration) -> AnyView

    init<S: ProgressSliderStyle>(_ style: S) {
        _makeBody = { AnyView(style.makeBody(configuration: $0)) }
    }

    @MainActor
    func makeBody(configuration: ProgressSliderStyleConfiguration) -> some View {
        _makeBody(configuration)
    }
}

private struct ProgressSliderStyleKey: EnvironmentKey {
    static let defaultValue = AnyProgressSliderStyle(SystemProgressSliderStyle())
}

private extension EnvironmentValues {
    var progressSliderStyle: AnyProgressSliderStyle {
        get { self[ProgressSliderStyleKey.self] }
        set { self[ProgressSliderStyleKey.self] = newValue }
    }
}

public extension View {
    func progressSliderStyle<S: ProgressSliderStyle>(_ style: S) -> some View {
        environment(\.progressSliderStyle, AnyProgressSliderStyle(style))
    }
}
