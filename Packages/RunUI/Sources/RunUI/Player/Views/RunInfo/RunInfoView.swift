import RunKit
import SwiftUI

/// Displays the current run's name, date, and key metrics.
///
/// Reads the run from the player environment via `@PlayerState`. Suitable
/// for use in the iOS Now Playing sheet and the macOS regular playback bar.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///

public struct RunInfoView: View {
    
    @PlayerState(\.run.metrics)
    private var run
    
    @Environment(\.runInfoViewStyle)
    private var style
    
    public init() {}
    
    public var body: some View {
        style.makeBody(configuration: configuration)
    }
    
    private var configuration: RunInfoStyleConfiguration {
        RunInfoStyleConfiguration(
            name: Text(run.name),
            date: Text(run.date, format: .dateTime),
            distance: Text(run.distance.formatted(.distance)),
            duration: Text(run.duration.formatted(.runDuration))
        )
    }
}

// MARK: - Type-erased style wrapper

private struct AnyRunInfoViewStyle: @unchecked Sendable  {
    private let _makeBody: @MainActor (RunInfoStyleConfiguration) -> AnyView
    
    init<S: RunInfoViewStyle>(_ style: S) {
        self._makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    @MainActor
    func makeBody(configuration: RunInfoStyleConfiguration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Environment

private struct RunInfoViewStyleKey: EnvironmentKey {
    static let defaultValue = AnyRunInfoViewStyle(RegularRunInfoViewStyle())
}

private extension EnvironmentValues {
    var runInfoViewStyle: AnyRunInfoViewStyle {
        get { self[RunInfoViewStyleKey.self] }
        set { self[RunInfoViewStyleKey.self] = newValue }
    }
}

public extension View {
    func runInfoViewStyle<S: RunInfoViewStyle>(_ style: S) -> some View {
        environment(\.runInfoViewStyle, AnyRunInfoViewStyle(style))
    }
}
