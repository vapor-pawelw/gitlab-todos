import Foundation

enum RefreshInterval: Int, CaseIterable, Codable, Identifiable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: Int { rawValue }

    var seconds: TimeInterval { TimeInterval(rawValue) }

    var displayKey: String.LocalizationValue {
        switch self {
        case .oneMinute: "settings.refreshInterval.1m"
        case .fiveMinutes: "settings.refreshInterval.5m"
        case .fifteenMinutes: "settings.refreshInterval.15m"
        case .thirtyMinutes: "settings.refreshInterval.30m"
        case .oneHour: "settings.refreshInterval.1h"
        }
    }
}
