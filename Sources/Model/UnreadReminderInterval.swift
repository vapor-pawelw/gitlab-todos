import Foundation

enum UnreadReminderInterval: Int, CaseIterable, Codable, Identifiable, Sendable {
    case off = 0
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: Int { rawValue }

    var seconds: TimeInterval? {
        rawValue > 0 ? TimeInterval(rawValue) : nil
    }

    var displayLabel: LocalizedStringResource {
        switch self {
        case .off: .Settings.settingsReminderIntervalOff
        case .fiveMinutes: .Settings.settingsReminderInterval5M
        case .fifteenMinutes: .Settings.settingsReminderInterval15M
        case .thirtyMinutes: .Settings.settingsReminderInterval30M
        case .oneHour: .Settings.settingsReminderInterval1H
        }
    }
}
