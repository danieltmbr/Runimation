import SwiftUI
import RunUI

struct RunEntryRow<Actions: View>: View {

    @ViewBuilder
    let actions: (RunRecord) -> Actions

    let record: RunRecord

    init(
        record: RunRecord,
        @ViewBuilder actions: @escaping (RunRecord) -> Actions
    ) {
        self.record = record
        self.actions = actions
    }

    var body: some View {
        HStack {
            PlayRunButton(record) { record in
                RunInfoView(record: record)
                    .runInfoStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)

            Menu {
                actions(record)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }
}

extension RunInfoView {
    init(record: RunRecord) {
        self.init(
            name: record.name,
            date: record.date,
            distance: record.distance,
            duration: record.duration
        )
    }
}
