import SwiftUI

/// A grouped-form selection list that presents labeled items with a checkmark on the active selection.
///
/// Drives selection via a `Binding<Item<Value>>`. Tapping a row updates the binding and
/// automatically dismisses the view via the environment.
/// The navigation title should be set by the caller via `.navigationTitle(_:)`.
///
/// ```swift
/// SelectionList(items: catalog, selection: $selectedItem)
///     .navigationTitle("Choose")
/// ```
///
public struct SelectionList<Value: Sendable>: View {

    let items: [Item<Value>]

    @Binding
    var selection: Item<Value>

    @Environment(\.dismiss)
    private var dismiss

    public init(items: [Item<Value>], selection: Binding<Item<Value>>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        Form {
            Section {
                ForEach(items) { item in
                    row(for: item)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Row

    private func row(for item: Item<Value>) -> some View {
        Button {
            selection = item
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selection.id == item.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }
}
