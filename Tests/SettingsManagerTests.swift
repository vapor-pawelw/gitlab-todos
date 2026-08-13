import Foundation
import Testing
@testable import GitLabTodos

@MainActor
@Suite("SettingsManager")
struct SettingsManagerTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "GitLabTodosTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("registers sensible defaults on first init")
    func registersDefaults() {
        let defaults = makeDefaults()
        let settings = SettingsManager(defaults: defaults)
        #expect(settings.refreshInterval == .fiveMinutes)
        #expect(settings.unreadReminderInterval == .fiveMinutes)
        #expect(settings.unreadReminderSound == .off)
        #expect(settings.notificationsEnabled == true)
        #expect(settings.onboardingCompleted == false)
        #expect(settings.launchAtLoginPreference == true)
        #expect(settings.lastSeenTodoIDs.isEmpty)
        #expect(settings.glabPath == nil)
        #expect(settings.resolvedHost == nil)
        #expect(settings.isFirstLaunch == true)
    }

    @Test("round-trips mutated state through save/reload")
    func roundTrip() {
        let defaults = makeDefaults()
        let settings = SettingsManager(defaults: defaults)
        settings.refreshInterval = .fifteenMinutes
        settings.unreadReminderInterval = .thirtyMinutes
        settings.unreadReminderSound = .ping
        settings.notificationsEnabled = false
        settings.onboardingCompleted = true
        settings.launchAtLoginPreference = false
        settings.lastSeenTodoIDs = [1, 2, 3, 42]
        settings.resolvedHost = "gitlab.corp.example.com"
        settings.glabPath = URL(fileURLWithPath: "/opt/homebrew/bin/glab")
        settings.save()

        let reloaded = SettingsManager(defaults: defaults)
        #expect(reloaded.refreshInterval == .fifteenMinutes)
        #expect(reloaded.unreadReminderInterval == .thirtyMinutes)
        #expect(reloaded.unreadReminderSound == .ping)
        #expect(reloaded.notificationsEnabled == false)
        #expect(reloaded.onboardingCompleted == true)
        #expect(reloaded.launchAtLoginPreference == false)
        #expect(reloaded.lastSeenTodoIDs == [1, 2, 3, 42])
        #expect(reloaded.resolvedHost == "gitlab.corp.example.com")
        #expect(reloaded.glabPath?.path == "/opt/homebrew/bin/glab")
    }

    @Test("clearing optional fields removes them from defaults")
    func clearsOptionals() {
        let defaults = makeDefaults()
        let settings = SettingsManager(defaults: defaults)
        settings.resolvedHost = "gitlab.com"
        settings.glabPath = URL(fileURLWithPath: "/usr/local/bin/glab")
        settings.save()

        settings.resolvedHost = nil
        settings.glabPath = nil
        settings.save()

        let reloaded = SettingsManager(defaults: defaults)
        #expect(reloaded.resolvedHost == nil)
        #expect(reloaded.glabPath == nil)
    }

    @Test("markLaunched flips isFirstLaunch")
    func firstLaunchFlip() {
        let defaults = makeDefaults()
        let settings = SettingsManager(defaults: defaults)
        #expect(settings.isFirstLaunch == true)
        settings.markLaunched()
        let reloaded = SettingsManager(defaults: defaults)
        #expect(reloaded.isFirstLaunch == false)
    }
}
