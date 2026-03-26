import SwiftUI

/// Empty state for the Run Library.
///
/// Differentiates between two empty states:
/// - **Not connected**: prompts the user to connect to Strava or import a GPX file.
/// - **Connected but empty**: prompts the user to record a run or import a GPX file.
///
struct LibraryEmptyView: View {

    @LibraryState(\.isConnected)
    private var isConnected

    let onImport: @MainActor () -> Void

    var body: some View {
        if isConnected {
            connectedEmptyState
        } else {
            disconnectedEmptyState
        }
    }

    // MARK: - States

    private var disconnectedEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Runs")
                .font(.title2.bold())

            VStack(spacing: 8) {
                Text("Connect your Strava account to browse your run history.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("You can also import GPX files directly.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            ConnectButton()
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            importButton
        }
        .padding(32)
    }

    private var connectedEmptyState: some View {
        ContentUnavailableView {
            Label("No Runs", systemImage: "figure.run.circle")
        } description: {
            Text("Record a run in Strava, or import a GPX file to see your runs here.")
        } actions: {
            importButton
        }
    }

    // MARK: - Shared

    private var importButton: some View {
        Button(action: onImport) {
            Label("Import File", systemImage: "square.and.arrow.down")
        }
    }
}
