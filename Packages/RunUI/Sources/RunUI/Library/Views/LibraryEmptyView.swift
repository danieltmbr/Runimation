import CoreUI
import RunKit
import SwiftUI

/// Empty state for the Run Library.
///
/// Differentiates between two empty states:
/// - **Not connected**: prompts the user to connect a tracker or import a GPX file.
/// - **Connected but empty**: prompts the user to record a run or import a GPX file.
///
public struct LibraryEmptyView: View {

    @Library(\.isConnected)
    private var isConnected

    @Navigation(\.library.showFilePicker)
    private var showFilePicker
    
    @Library(\.trackers)
    private var trackers

    public init() {}

    public var body: some View {
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

            ForEach(trackers, id: \.id) { tracker in
                ConnectToggle(tracker: tracker)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }

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
        Button {
            showFilePicker = true
        } label: {
            Label("Import File", systemImage: "square.and.arrow.down")
        }
    }
}
