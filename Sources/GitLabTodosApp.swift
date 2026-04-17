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
            if monitor.lastError != nil {
                Image(systemName: "exclamationmark.triangle")
                Text("\(monitor.badgeCount)")
            } else if monitor.settings.onboardingCompleted {
                Image("todo-done")
                    .overlay(alignment: .bottomTrailing) {
                        if monitor.hasUnseenTodos {
                            Circle()
                                .fill(.red)
                                .frame(width: 5, height: 5)
                                .offset(x: 1, y: 1)
                        }
                    }
                Text("\(monitor.badgeCount)")
            } else {
                Image("todo-done")
            }
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
