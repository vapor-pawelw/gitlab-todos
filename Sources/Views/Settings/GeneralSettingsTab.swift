import SwiftUI
import UserNotifications

struct GeneralSettingsTab: View {
    @Bindable var monitor: TodoMonitorService

    @State private var launchAtLogin: Bool = LaunchAtLoginService.isEnabled
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $launchAtLogin) {
                    Text("settings.general.startup.launchAtLogin", tableName: "Settings")
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        try LaunchAtLoginService.setEnabled(newValue)
                        monitor.settings.launchAtLoginPreference = newValue
                        monitor.settings.save()
                    } catch {
                        Log.settings.error("Launch-at-login toggle failed: \(error.localizedDescription, privacy: .public)")
                        launchAtLogin = !newValue
                    }
                }
            } header: {
                Text("settings.general.startup.section", tableName: "Settings")
            }

            Section {
                Picker(selection: refreshIntervalBinding) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(String(localized: interval.displayKey, table: "Settings"))
                            .tag(interval)
                    }
                } label: {
                    Text("settings.general.refresh.picker", tableName: "Settings")
                }
            } header: {
                Text("settings.general.refresh.section", tableName: "Settings")
            }

            Section {
                Toggle(isOn: notificationsEnabledBinding) {
                    Text("settings.general.notifications.toggle", tableName: "Settings")
                }

                if notificationStatus == .denied {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("settings.general.notifications.footer.denied", tableName: "Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("settings.general.notifications.openSystemSettings", tableName: "Settings")
                        }
                    }
                }
            } header: {
                Text("settings.general.notifications.section", tableName: "Settings")
            }
        }
        .formStyle(.grouped)
        .task {
            launchAtLogin = LaunchAtLoginService.isEnabled
            notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
    }

    private var refreshIntervalBinding: Binding<RefreshInterval> {
        Binding(
            get: { monitor.settings.refreshInterval },
            set: { newValue in
                monitor.settings.refreshInterval = newValue
                monitor.settings.save()
                monitor.restartTimer()
            }
        )
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { monitor.settings.notificationsEnabled },
            set: { newValue in
                monitor.settings.notificationsEnabled = newValue
                monitor.settings.save()
            }
        )
    }
}
