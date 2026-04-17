import Foundation

enum RefreshInterval: Int, CaseIterable, Codable, Identifiable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: Int { rawValue }

    var seconds: TimeInterval { TimeInterval(rawValue) }

    var displayLabel: LocalizedStringResource {
        switch self {
        case .oneMinute: .Settings.settingsRefreshInterval1M
        case .fiveMinutes: .Settings.settingsRefreshInterval5M
        case .fifteenMinutes: .Settings.settingsRefreshInterval15M
        case .thirtyMinutes: .Settings.settingsRefreshInterval30M
        case .oneHour: .Settings.settingsRefreshInterval1H
        }
    }
}
