import SwiftUI

/// A visual-only, non-interactive progress indicator for animation playback.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerProgressBar: View {

    @PlayerState(\.progress)
    private var progress

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.25))
                Capsule()
                    .fill(.primary.opacity(0.7))
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
    }
}
