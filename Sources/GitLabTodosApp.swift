import SwiftUI

@main
struct GitLabTodosApp: App {
    @State private var monitor = TodoMonitorService()
    @State private var avatarCache = AvatarCache()

    var body: some Scene {
        MenuBarExtra {
            TodoListView(monitor: monitor)
                .environment(\.avatarCache, avatarCache)
                .task {
                    await performFirstLaunchIfNeeded()
                }
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PlaceholderSettingsView()
        }

        Window("Setup", id: "onboarding") {
            PlaceholderOnboardingView(monitor: monitor)
        }
        .windowResizability(.contentSize)
    }

    @MainActor
    private func performFirstLaunchIfNeeded() async {
        guard !monitor.settings.onboardingCompleted else {
            if monitor.glab.glabPath == nil {
                monitor.glab.glabPath = Self.findGlabExecutable()
                monitor.settings.glabPath = monitor.glab.glabPath
                monitor.settings.save()
            }
            if monitor.lastRefresh == nil {
                monitor.start()
            }
            return
        }

        // First launch / not yet onboarded: best-effort path probe so the
        // error banner surfaces the right message. Task #8 will replace this
        // with the full OnboardingDetector flow.
        if monitor.glab.glabPath == nil {
            monitor.glab.glabPath = Self.findGlabExecutable()
        }
        await monitor.glab.recheck()
        monitor.settings.glabPath = monitor.glab.glabPath
        monitor.settings.resolvedHost = monitor.glab.resolvedHost
        monitor.settings.save()
        monitor.start()
    }

    private static func findGlabExecutable() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/glab",
            "/usr/local/bin/glab",
            "/opt/local/bin/glab",
            "/usr/bin/glab",
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}

// MARK: - Placeholders (replaced by Task #7 / Task #8)

private struct PlaceholderSettingsView: View {
    var body: some View {
        Text("Settings (coming soon)")
            .padding(40)
    }
}

private struct PlaceholderOnboardingView: View {
    let monitor: TodoMonitorService

    var body: some View {
        VStack(spacing: 16) {
            Text("Setup")
                .font(.largeTitle)
            Text("The guided setup is not yet implemented.")
                .foregroundStyle(.secondary)
            Button("Mark onboarding complete") {
                monitor.settings.onboardingCompleted = true
                monitor.settings.save()
                monitor.start()
            }
        }
        .frame(width: 480, height: 320)
    }
}
