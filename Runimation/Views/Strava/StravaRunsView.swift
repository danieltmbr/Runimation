import AuthenticationServices
import RunKit
import StravaKit
import SwiftUI

/// Displays the user's Strava run history and lets them load any run into the player.
///
/// When not connected, shows a "Connect to Strava" prompt. Once authenticated,
/// lists activities filtered to runs, with pagination on scroll. Tapping a row
/// fetches the GPS/sensor streams and calls `onRunLoaded` after handing the
/// resulting track to `RunPlayer`.
///
struct StravaRunsView: View {

    // MARK: - Dependencies

    @Environment(StravaClient.self)
    private var client

    @Environment(RunPlayer.self)
    private var player

    // MARK: - State

    /// Called after a run has been successfully loaded into the player
    /// so the parent can navigate to the Visualisation tab.
    let onRunLoaded: () -> Void

    @State private var activities: [StravaActivity] = []
    @State private var fetchError: Error?
    @State private var isLoadingActivities = false
    @State private var loadingRunID: Int?

    // MARK: - Body

    var body: some View {
        if client.isAuthenticated {
            activityList
        } else {
            connectPrompt
        }
    }

    // MARK: - Unauthenticated

    private var connectPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Connect to Strava")
                .font(.title2.bold())
            Text("Link your Strava account to browse your runs and load them into the animation.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Connect", action: authenticate)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
    }

    // MARK: - Activity List

    @ViewBuilder
    private var activityList: some View {
        Group {
            if isLoadingActivities && activities.isEmpty {
                ProgressView("Loading runs…")
            } else if activities.isEmpty, let error = fetchError {
                ContentUnavailableView {
                    Label("Could not load runs", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Try again") { Task { await loadActivities() } }
                }
            } else {
                List(activities.filter(\.isRun)) { activity in
                    activityRow(activity)
                        .onAppear {
                            if activity.id == activities.last?.id {
                                Task { await loadNextPage() }
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
        .task { await loadActivities() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Disconnect", role: .destructive) { client.signOut() }
            }
        }
    }

    @ViewBuilder
    private func activityRow(_ activity: StravaActivity) -> some View {
        Button {
            Task { await loadRun(activity) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                    Text(activity.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label(formattedDistance(activity.distance), systemImage: "arrow.left.and.right")
                        Label(formattedDuration(activity.movingTime), systemImage: "clock")
                        if let hr = activity.averageHeartrate {
                            Label("\(Int(hr)) bpm", systemImage: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if loadingRunID == activity.id {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(loadingRunID != nil)
    }

    // MARK: - Actions

    private func authenticate() {
        Task {
            do {
                #if os(macOS)
                try await client.authenticate()
                #else
                try await client.authenticate(presentingFrom: presentationAnchor)
                #endif
                await loadActivities()
            } catch {
                fetchError = error
            }
        }
    }

    private func loadActivities() async {
        guard !isLoadingActivities else { return }
        isLoadingActivities = true
        fetchError = nil
        do {
            activities = try await client.activities(page: 1, perPage: 30)
        } catch {
            fetchError = error
        }
        isLoadingActivities = false
    }

    private func loadNextPage() async {
        let nextPage = activities.count / 30 + 1
        guard !isLoadingActivities else { return }
        isLoadingActivities = true
        do {
            let more = try await client.activities(page: nextPage, perPage: 30)
            activities += more
        } catch { /* silently ignore pagination errors */ }
        isLoadingActivities = false
    }

    private func loadRun(_ activity: StravaActivity) async {
        loadingRunID = activity.id
        defer { loadingRunID = nil }
        do {
            let track = try await client.track(for: activity.id)
            try await player.setRun(track)
            onRunLoaded()
        } catch {
            fetchError = error
        }
    }

    // MARK: - Formatting Helpers

    private func formattedDistance(_ meters: Double) -> String {
        let km = Measurement(value: meters / 1_000, unit: UnitLength.kilometers)
        return km.formatted(.measurement(width: .abbreviated, usage: .road))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    // MARK: - Platform Anchor

    private var presentationAnchor: ASPresentationAnchor {
        #if os(macOS)
        NSApplication.shared.windows.first ?? NSWindow()
        #else
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? UIWindow()
        #endif
    }

}
