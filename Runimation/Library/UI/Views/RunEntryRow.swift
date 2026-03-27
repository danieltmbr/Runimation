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
            RunInfoView(
                name: record.name,
                date: record.date,
                distance: record.distance,
                duration: record.duration
            )
            .runInfoStyle(.compact)

            Spacer()

            Menu {
                actions(record)
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
}
