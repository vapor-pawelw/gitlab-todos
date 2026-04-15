import SwiftUI

@main
struct GitLabTodosApp: App {
    @State private var monitor = TodoMonitorService()
    @State private var avatarCache = AvatarCache()

    var body: some Scene {
        MenuBarExtra {
            TodoListView(monitor: monitor)
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
    }
}
