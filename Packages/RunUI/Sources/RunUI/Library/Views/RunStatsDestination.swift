import RunKit
import SwiftUI

/// Stats destination for a `RunItem`.
///
/// Loads the run via `\.loadRun` and renders metrics once available.
/// The three possible states — loading, loaded, failed — are represented
/// by a single `Result<Run, Error>?`: `nil` = loading, `.success` = loaded,
/// `.failure` = error.
///
public struct RunStatsDestination: View {

    @Environment(\.loadRun)
    private var loadRun

    let item: RunItem

    @State
    private var result: Result<Run, Error>?

    public init(item: RunItem) {
        self.item = item
    }

    public var body: some View {
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
        .navigationTitle(item.name)
        .task { await load() }
    }

    private func load() async {
        do {
            result = .success(try await loadRun(item))
        } catch {
            result = .failure(error)
        }
    }
}
