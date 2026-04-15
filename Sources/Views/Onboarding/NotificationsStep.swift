import AppKit
import SwiftUI
import UserNotifications

struct NotificationsStep: View {
    let monitor: TodoMonitorService

    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.notifications.title", tableName: "Onboarding")
                .font(.title3.weight(.semibold))

            Text("onboarding.notifications.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            statusView
        }
        .task {
            status = await OnboardingDetector.checkNotificationPermission()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .authorized, .provisional, .ephemeral:
            Label {
                Text("onboarding.notifications.enabled", tableName: "Onboarding")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

        case .denied:
            VStack(alignment: .leading, spacing: 10) {
                Text("onboarding.notifications.denied", tableName: "Onboarding")
                    .foregroundStyle(.secondary)
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("onboarding.notifications.openSystemSettings", tableName: "Onboarding")
                }
            }

        case .notDetermined:
            Button {
                Task {
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    status = await OnboardingDetector.checkNotificationPermission()
                }
            } label: {
                Text("onboarding.notifications.enable", tableName: "Onboarding")
            }

        @unknown default:
            EmptyView()
        }
    }
}
