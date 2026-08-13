import SwiftUI

@MainActor
final class GitLabTodosAppDelegate: NSObject, NSApplicationDelegate {
    let monitor = TodoMonitorService()
    let avatarCache = AvatarCache()
    let updates = UpdateService()
    private var statusItemController: MenuBarStatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = MenuBarStatusItemController(
            monitor: monitor,
            updates: updates,
            avatarCache: avatarCache
        )
    }
}

@main
struct GitLabTodosApp: App {
    @NSApplicationDelegateAdaptor(GitLabTodosAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(monitor: appDelegate.monitor)
        }

        Window("Setup", id: "onboarding") {
            OnboardingView(monitor: appDelegate.monitor)
        }
        .windowResizability(.contentSize)

        Window("What's New", id: "whats-new") {
            WhatsNewView(updates: appDelegate.updates)
        }
        .windowResizability(.contentSize)
    }
}
