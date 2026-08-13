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
                    Text(.Settings.settingsGeneralStartupLaunchAtLogin)
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
                Text(.Settings.settingsGeneralStartupSection)
            }

            Section {
                Picker(selection: refreshIntervalBinding) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.displayLabel)
                            .tag(interval)
                    }
                } label: {
                    Text(.Settings.settingsGeneralRefreshPicker)
                }
            } header: {
                Text(.Settings.settingsGeneralRefreshSection)
            }

            Section {
                Toggle(isOn: notificationsEnabledBinding) {
                    Text(.Settings.settingsGeneralNotificationsToggle)
                }

                Picker(selection: unreadReminderIntervalBinding) {
                    ForEach(UnreadReminderInterval.allCases) { interval in
                        Text(interval.displayLabel)
                            .tag(interval)
                    }
                } label: {
                    Text(.Settings.settingsGeneralNotificationsReminderPicker)
                }
                .disabled(!monitor.settings.notificationsEnabled)

                Picker(selection: unreadReminderSoundBinding) {
                    ForEach(ReminderSound.allCases) { sound in
                        reminderSoundLabel(sound)
                            .tag(sound)
                    }
                } label: {
                    Text(.Settings.settingsGeneralNotificationsReminderSoundPicker)
                }
                .disabled(!monitor.settings.notificationsEnabled)

                if notificationStatus == .denied {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(.Settings.settingsGeneralNotificationsFooterDenied)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text(.Settings.settingsGeneralNotificationsOpenSystemSettings)
                        }
                    }
                }
            } header: {
                Text(.Settings.settingsGeneralNotificationsSection)
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
                monitor.restartUnreadReminderTimer()
            }
        )
    }

    private var unreadReminderIntervalBinding: Binding<UnreadReminderInterval> {
        Binding(
            get: { monitor.settings.unreadReminderInterval },
            set: { newValue in
                monitor.settings.unreadReminderInterval = newValue
                monitor.settings.save()
                monitor.restartUnreadReminderTimer()
            }
        )
    }

    private var unreadReminderSoundBinding: Binding<ReminderSound> {
        Binding(
            get: { monitor.settings.unreadReminderSound },
            set: { newValue in
                monitor.settings.unreadReminderSound = newValue
                monitor.settings.save()
            }
        )
    }

    @ViewBuilder
    private func reminderSoundLabel(_ sound: ReminderSound) -> some View {
        if sound == .off {
            Text(.Settings.settingsReminderSoundOff)
        } else {
            Text(sound.rawValue)
        }
    }
}
