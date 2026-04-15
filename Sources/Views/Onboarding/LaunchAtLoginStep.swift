import SwiftUI

struct LaunchAtLoginStep: View {
    let monitor: TodoMonitorService

    @State private var enabled: Bool = LaunchAtLoginService.isEnabled
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.launchAtLogin.title", tableName: "Onboarding")
                .font(.title3.weight(.semibold))

            Text("onboarding.launchAtLogin.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            Toggle(isOn: toggleBinding) {
                Text("onboarding.launchAtLogin.toggle", tableName: "Onboarding")
            }
            .toggleStyle(.switch)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task {
            enabled = LaunchAtLoginService.isEnabled
        }
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                do {
                    try LaunchAtLoginService.setEnabled(newValue)
                    enabled = newValue
                    errorMessage = nil
                    monitor.settings.launchAtLoginPreference = newValue
                    monitor.settings.save()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        )
    }
}
