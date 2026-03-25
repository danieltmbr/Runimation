import SwiftUI

/// A minimal progress slider style — a capsule bar with a drag-to-scrub gesture.
///
/// The bar fills its available frame; control the thickness via `.frame(height:)`
/// on the `ProgressSlider`. The seek is committed on drag release.
///
public struct MinimalProgressSliderStyle: ProgressSliderStyle {

    public func makeBody(configuration: Configuration) -> some View {
        MinimalProgressSlider(configuration: configuration)
    }
}

private struct MinimalProgressSlider: View {
    
    let configuration: ProgressSliderStyleConfiguration
    
    @State
    private var isDragging = false
    
    @State
    private var localValue: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.15))
                Capsule()
                    .fill(.primary)
                    .frame(width: geo.size.width * localValue)
            }
            .contentShape(Rectangle())
            .onChange(of: configuration.progress.wrappedValue, initial: true) { _, newValue in
                guard !isDragging else { return }
                localValue = newValue
            }
            .onChange(of: localValue, initial: false) {
                guard isDragging else { return }
                configuration.seek(localValue)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        localValue = max(0, min(1, value.location.x / geo.size.width))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
}
