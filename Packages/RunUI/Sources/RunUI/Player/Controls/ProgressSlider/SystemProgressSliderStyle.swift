import SwiftUI

/// The default progress slider style — a native SwiftUI `Slider`.
///
public struct SystemProgressSliderStyle: ProgressSliderStyle {

    public func makeBody(configuration: Configuration) -> some View {
        SystemProgressSlider(configuration: configuration)
    }
}

private struct SystemProgressSlider: View {
    
    let configuration: ProgressSliderStyleConfiguration
    
    @State
    private var isDragging = false
    
    @State
    private var localValue: Double = 0

    var body: some View {
        Slider(value: $localValue, in: 0...1) { dragging in
            isDragging = dragging
        }
        .onChange(of: configuration.progress.wrappedValue, initial: true) { _, newValue in
            guard !isDragging else { return }
            localValue = newValue
        }
        .onChange(of: localValue, initial: false) {
            guard isDragging else { return }
            configuration.seek(localValue)
        }
    }
}
