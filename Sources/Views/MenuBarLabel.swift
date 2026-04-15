import SwiftUI

struct MenuBarLabel: View {
    let monitor: TodoMonitorService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbolName)
            if monitor.settings.onboardingCompleted,
               monitor.lastError == nil,
               monitor.badgeCount > 0
            {
                Text("\(monitor.badgeCount)")
            }
        }
    }

    private var symbolName: String {
        if monitor.lastError != nil { return "exclamationmark.triangle" }
        return "checklist"
    }
}
