import SwiftUI

struct MenuBarLabel: View {
    let monitor: TodoMonitorService

    var body: some View {
        if monitor.lastError != nil {
            Label("\(monitor.badgeCount)", systemImage: "exclamationmark.triangle")
        } else if monitor.settings.onboardingCompleted {
            Label {
                Text("\(monitor.badgeCount)")
            } icon: {
                Image("todo-done")
                    .overlay(alignment: .bottomTrailing) {
                        if monitor.hasUnseenTodos {
                            Circle()
                                .fill(.red)
                                .frame(width: 5, height: 5)
                                .offset(x: 1, y: 1)
                        }
                    }
            }
        } else {
            Image("todo-done")
        }
    }
}
