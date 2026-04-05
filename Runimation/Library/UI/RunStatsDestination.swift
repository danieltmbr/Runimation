import RunKit
import SwiftUI

/// Stats destination for a `RunEntry`.
///
/// Resolves the entry's display name via `RunLibrary` and fetches the run
/// via `\.loadRun`. The three possible states — loading, loaded, failed —
/// are represented by a single `Result<Run, Error>?`:
/// `nil` = loading, `.success` = loaded, `.failure` = error.
///
struct RunStatsDestination: View {

    @Environment(RunLibrary.self)
    private var library

    @Environment(\.loadEntry)
    private var loadEntry

    let entry: RunEntry

    @State
    private var result: Result<Run, Error>?

    private var record: RunRecord? { library.record(for: entry) }

    var body: some View {
        Group {
            switch result {
            case .none:
                ProgressView("Loading stats…")
            case .success(let run):
                RunMetricsView(run: run)
            case .failure(let error):
                ContentUnavailableView {
                    Label("Could not load run", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
            }
        }
        .navigationTitle(record?.name ?? "Run Stats")
        .task { await load() }
    }

    private func load() async {
        do {
            result = .success(try await loadEntry(entry))
        } catch {
            result = .failure(error)
        }
    }
}
