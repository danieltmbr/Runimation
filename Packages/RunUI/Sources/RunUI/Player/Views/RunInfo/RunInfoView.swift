import RunKit
import SwiftUI

/// Displays a run's name, date, and key metrics.
///
/// Data is passed in directly via the initialiser, so this view can be used
/// in any context — the Run Library list, player controls, or standalone screens.
///
/// For player-coupled usage (where data should track the currently loaded run),
/// use `PlayerRunInfoView` instead, which reads `@PlayerState` and forwards to this view.
///
public struct RunInfoView: View {
    
    @Environment(\.runInfoAlignment)
    private var alignment
    
    @Environment(\.runInfoStyle)
    private var style

    private let name: String
    
    private let date: Date
    
    private let distance: Double
    
    private let duration: TimeInterval

    public init(
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval
    ) {
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
    }

    public init(run: Run) {
        self.init(
            name: run.name,
            date: run.date,
            distance: run.distance,
            duration: run.duration
        )
    }

    public var body: some View {
        style.makeBody(configuration: configuration)
    }

    private var configuration: RunInfoStyleConfiguration {
        RunInfoStyleConfiguration(
            alignment: alignment,
            date: Text(date, format: .dateTime),
            distance: Text(distance.formatted(.distance)),
            duration: Text(duration.formatted(.runDuration)),
            name: Text(name)
        )
    }
}

// MARK: - Type-erased style wrapper

private struct AnyRunInfoStyle: @unchecked Sendable  {
    private let _makeBody: @MainActor (RunInfoStyleConfiguration) -> AnyView

    init<S: RunInfoStyle>(_ style: S) {
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

private struct RunInfoAlignmentKey: EnvironmentKey {
    static let defaultValue = HorizontalAlignment.leading
}

private struct RunInfoStyleKey: EnvironmentKey {
    static let defaultValue = AnyRunInfoStyle(RegularRunInfoStyle())
}

private extension EnvironmentValues {
    
    var runInfoAlignment: HorizontalAlignment {
        get { self[RunInfoAlignmentKey.self] }
        set { self[RunInfoAlignmentKey.self] = newValue }
    }

    
    var runInfoStyle: AnyRunInfoStyle {
        get { self[RunInfoStyleKey.self] }
        set { self[RunInfoStyleKey.self] = newValue }
    }
}

public extension View {
    func runInfoAlignment(_ alignment: HorizontalAlignment) -> some View {
        environment(\.runInfoAlignment, alignment)
    }
    
    func runInfoStyle<S: RunInfoStyle>(_ style: S) -> some View {
        environment(\.runInfoStyle, AnyRunInfoStyle(style))
    }
}
