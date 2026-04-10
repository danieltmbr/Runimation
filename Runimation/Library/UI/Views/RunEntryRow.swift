import SwiftUI
import RunKit
import RunUI

struct RunEntryRow<Actions: View>: View {

    @ViewBuilder
    let actions: (RunItem) -> Actions

    let item: RunItem

    init(
        item: RunItem,
        @ViewBuilder actions: @escaping (RunItem) -> Actions
    ) {
        self.item = item
        self.actions = actions
    }

    var body: some View {
        HStack {
            PlayRunButton(item) { item in
                RunInfoView(item: item)
                    .runInfoStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)

            Menu {
                actions(item)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }
}

extension RunInfoView {
    init(item: RunItem) {
        self.init(
            name: item.name,
            date: item.date,
            distance: item.distance,
            duration: item.duration
        )
    }
}
