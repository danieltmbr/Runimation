import RunKit
import SwiftUI

/// Stats destination for a `LibraryEntry`.
///
/// Fetches the run via `\.fetchRun` and presents `RunMetricsView` on success.
/// The three possible states — loading, loaded, failed — are represented by
/// a single `Result<Run, Error>?`: `nil` = loading, `.success` = loaded, `.failure` = error.
///
struct RunStatsDestination: View {

    @Environment(\.fetchRun)
    private var fetchRun

    let entry: LibraryEntry

    @State
    private var result: Result<Run, Error>?

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
        .navigationTitle(entry.name)
        .task { await load() }
    }

    private func load() async {
        do {
            result = .success(try await fetchRun(entry))
        } catch {
            result = .failure(error)
        }
    }
}
