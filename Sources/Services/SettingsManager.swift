import Foundation
import Observation

@MainActor
@Observable
final class SettingsManager {
    private let defaults: UserDefaults

    var refreshInterval: RefreshInterval
    var notificationsEnabled: Bool
    var lastSeenTodoIDs: Set<Int>
    var onboardingCompleted: Bool
    var glabPath: URL?
    var resolvedHost: String?
    var launchAtLoginPreference: Bool
    var lastMenuOpenedAt: Date?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        Self.registerDefaults(in: defaults)

        let rawInterval = defaults.integer(forKey: Key.refreshInterval)
        self.refreshInterval = RefreshInterval(rawValue: rawInterval) ?? .fiveMinutes
        self.notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        self.onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        self.launchAtLoginPreference = defaults.bool(forKey: Key.launchAtLoginPreference)
        self.resolvedHost = defaults.string(forKey: Key.resolvedHost)
        let storedMenuOpenedAt = defaults.double(forKey: Key.lastMenuOpenedAt)
        self.lastMenuOpenedAt = storedMenuOpenedAt > 0
            ? Date(timeIntervalSince1970: storedMenuOpenedAt)
            : nil

        if let pathString = defaults.string(forKey: Key.glabPath), !pathString.isEmpty {
            self.glabPath = URL(fileURLWithPath: pathString)
        } else {
            self.glabPath = nil
        }

        if let data = defaults.data(forKey: Key.lastSeenTodoIDs),
           let decoded = try? JSONDecoder().decode([Int].self, from: data)
        {
            self.lastSeenTodoIDs = Set(decoded)
        } else {
            self.lastSeenTodoIDs = []
        }
    }

    func save() {
        defaults.set(refreshInterval.rawValue, forKey: Key.refreshInterval)
        defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted)
        defaults.set(launchAtLoginPreference, forKey: Key.launchAtLoginPreference)
        if let glabPath {
            defaults.set(glabPath.path, forKey: Key.glabPath)
        } else {
            defaults.removeObject(forKey: Key.glabPath)
        }
        if let resolvedHost {
            defaults.set(resolvedHost, forKey: Key.resolvedHost)
        } else {
            defaults.removeObject(forKey: Key.resolvedHost)
        }
        if let data = try? JSONEncoder().encode(Array(lastSeenTodoIDs).sorted()) {
            defaults.set(data, forKey: Key.lastSeenTodoIDs)
        }
        if let lastMenuOpenedAt {
            defaults.set(lastMenuOpenedAt.timeIntervalSince1970, forKey: Key.lastMenuOpenedAt)
        } else {
            defaults.removeObject(forKey: Key.lastMenuOpenedAt)
        }
    }

    var isFirstLaunch: Bool {
        !defaults.bool(forKey: Key.hasLaunchedBefore)
    }

    func markLaunched() {
        defaults.set(true, forKey: Key.hasLaunchedBefore)
    }

    private static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: [
            Key.refreshInterval: RefreshInterval.fiveMinutes.rawValue,
            Key.notificationsEnabled: true,
            Key.onboardingCompleted: false,
            Key.launchAtLoginPreference: true,
            Key.hasLaunchedBefore: false,
        ])
    }

    private enum Key {
        static let refreshInterval = "refreshInterval"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastSeenTodoIDs = "lastSeenTodoIDs"
        static let onboardingCompleted = "onboardingCompleted"
        static let glabPath = "glabPath"
        static let resolvedHost = "resolvedHost"
        static let launchAtLoginPreference = "launchAtLoginPreference"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let lastMenuOpenedAt = "lastMenuOpenedAt"
    }
}
