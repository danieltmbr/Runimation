import SwiftUI

/// A detail sheet for any `Option`-conforming type.
///
/// Shows the option's description, and — when an editable `binding` is provided
/// and the value conforms to `FormAdjustable` — a "Configuration" section
/// populated via `AdjustableForm`.
///
/// ```swift
/// // Editable
/// OptionDetail(item: item, binding: $applied[index])
///
/// // Read-only (catalog preview)
/// OptionDetail(item: item)
/// ```
///
public struct OptionDetail<Value: Sendable>: View {

    let item: Item<Value>

    var binding: Binding<Item<Value>>? = nil

    public init(item: Item<Value>, binding: Binding<Item<Value>>? = nil) {
        self.item = item
        self.binding = binding
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.description)
                        .foregroundStyle(.secondary)
                }

                if let binding, let adjustable = item.value as? any FormAdjustable {
                    Section("Configuration") {
                        formView(for: adjustable, itemBinding: binding)
                    }
                }
            }
            .navigationTitle(item.label)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .presentationDetents([.medium])
    }

    // MARK: - Private

    /// Bridges `Binding<Item<Value>>` to a typed `Binding<T>` and wraps it in
    /// `AdjustableForm`. SE-0352 opens the `any FormAdjustable` existential when
    /// passed to the generic `T` parameter. The force-cast in the setter is safe
    /// because `T` was retrieved from `item.value`, guaranteeing the cast succeeds.
    ///
    private func formView<T: FormAdjustable>(
        for value: T,
        itemBinding: Binding<Item<Value>>
    ) -> AdjustableForm {
        AdjustableForm(value: Binding<T>(
            get: { itemBinding.wrappedValue.value as! T },
            set: { itemBinding.wrappedValue = itemBinding.wrappedValue.with($0 as! Value) }
        ))
    }
}
