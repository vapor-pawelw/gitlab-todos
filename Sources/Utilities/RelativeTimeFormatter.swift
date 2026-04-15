import Foundation

enum RelativeTime {
    nonisolated(unsafe) private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        f.dateTimeStyle = .named
        return f
    }()

    static func string(from date: Date, relativeTo reference: Date = Date()) -> String {
        formatter.localizedString(for: date, relativeTo: reference)
    }
}
