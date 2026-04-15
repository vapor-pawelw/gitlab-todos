import SwiftUI

@main
struct GitLabTodosApp: App {
    @State private var monitor = TodoMonitorService()
    @State private var avatarCache = AvatarCache()
    @State private var updates = UpdateService()

    var body: some Scene {
        MenuBarExtra {
            TodoListView(monitor: monitor, updates: updates)
                .environment(\.avatarCache, avatarCache)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(monitor: monitor)
        }

        Window("Setup", id: "onboarding") {
            OnboardingView(monitor: monitor)
        }
        .windowResizability(.contentSize)

        Window("What's New", id: "whats-new") {
            WhatsNewView(updates: updates)
        }
        .windowResizability(.contentSize)
    }
}
