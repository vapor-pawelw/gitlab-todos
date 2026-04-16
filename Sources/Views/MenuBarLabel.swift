import SwiftUI

struct MenuBarLabel: View {
    let monitor: TodoMonitorService

    var body: some View {
        if monitor.lastError != nil {
            Label("\(monitor.badgeCount)", systemImage: "exclamationmark.triangle")
        } else if monitor.settings.onboardingCompleted {
            Label("\(monitor.badgeCount)", image: "todo-done")
        } else {
            Image("todo-done")
        }
    }
}
