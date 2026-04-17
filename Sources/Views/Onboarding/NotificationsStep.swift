import AppKit
import SwiftUI
import UserNotifications

struct NotificationsStep: View {
    let monitor: TodoMonitorService

    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.Onboarding.onboardingNotificationsTitle)
                .font(.title3.weight(.semibold))

            Text(.Onboarding.onboardingNotificationsBody)
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
                Text(.Onboarding.onboardingNotificationsEnabled)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

        case .denied:
            VStack(alignment: .leading, spacing: 10) {
                Text(.Onboarding.onboardingNotificationsDenied)
                    .foregroundStyle(.secondary)
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(.Onboarding.onboardingNotificationsOpenSystemSettings)
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
                Text(.Onboarding.onboardingNotificationsEnable)
            }

        @unknown default:
            EmptyView()
        }
    }
}
