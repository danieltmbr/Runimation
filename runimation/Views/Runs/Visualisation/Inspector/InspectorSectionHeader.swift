import SwiftUI

/// Section title with an optional informational description shown via a popover,
/// used across inspector panels.
///
/// Owns its vertical spacing: generous top padding creates a clear visual break
/// between sections without needing extra spacers at the call site.
/// Horizontal padding is the caller's responsibility so headers align with
/// whatever padding context their parent provides.
///
/// The `.textCase(nil)` modifier prevents List section headers from applying
/// automatic uppercase styling.
///
struct InspectorSectionHeader: View {

    let title: String

    var description: String? = nil

    @State
    private var showInfo = false

    init(_ title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .textCase(nil)
                .foregroundStyle(.primary)
            Spacer()
            if let description {
                Button { showInfo.toggle() } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfo) {
                    Text(description)
                        .font(.callout)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 2)
    }
}
