import SwiftUI
import RunKit

/// A slider that reflects and controls the player's playback progress.
///
/// Reads progress via `@PlayerState` and commits seeks via `SeekAction`,
/// keeping the local drag value frozen while the user is interacting.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct ProgressSlider: View {
    
    @Environment(\.seek)
    private var seek

    @PlayerState(\.progress.animation)
    private var progress

    @State
    private var isEditing = false
    
    @State
    private var localValue: Double = 0
    
    public init() {}

    public var body: some View {
        Slider(value: $localValue, in: 0...1) { editing in
            isEditing = editing
        }
        .onChange(of: progress, initial: true) { _, newValue in
            guard !isEditing else { return }
            localValue = newValue
        }
        .onChange(of: localValue, initial: false) {
            guard isEditing else { return }
            seek(to: localValue)
        }
    }
}
