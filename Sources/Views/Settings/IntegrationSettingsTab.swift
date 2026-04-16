import SwiftUI

struct IntegrationSettingsTab: View {
    @Bindable var monitor: TodoMonitorService
    @Environment(\.openWindow) private var openWindow

    @State private var isRechecking = false

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    glabPathValue
                } label: {
                    Text("settings.integration.glab.path.row", tableName: "Settings")
                }

                LabeledContent {
                    hostValue
                } label: {
                    Text("settings.integration.host.row", tableName: "Settings")
                }

                LabeledContent {
                    authValue
                } label: {
                    Text("settings.integration.auth.row", tableName: "Settings")
                }

                HStack {
                    Button {
                        isRechecking = true
                        Task {
                            await monitor.recheckIntegration()
                            isRechecking = false
                        }
                    } label: {
                        Text("settings.integration.recheck", tableName: "Settings")
                    }
                    .disabled(isRechecking)

                    Button {
                        openWindow(id: "onboarding")
                    } label: {
                        Text("settings.integration.runSetupAgain", tableName: "Settings")
                    }
                }
            } header: {
                Text("settings.integration.glab.section", tableName: "Settings")
            } footer: {
                Text("settings.integration.footer", tableName: "Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var glabPathValue: some View {
        if let path = monitor.glab.glabPath?.path {
            Text(path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        } else {
            Text("settings.integration.glab.notFound", tableName: "Settings")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var hostValue: some View {
        if let host = monitor.glab.resolvedHost, !host.isEmpty {
            Text(host)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        } else {
            Text("settings.integration.host.unresolved", tableName: "Settings")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var authValue: some View {
        switch monitor.glab.authStatus {
        case .authenticated:
            Text(
                String(
                    format: String(localized: "settings.integration.auth.authenticated.%@", table: "Settings"),
                    monitor.glab.currentUsername ?? ""
                )
            )
            .foregroundStyle(.secondary)
        case .wrongDefaultHost(let hosts):
            Text(
                String(
                    format: String(localized: "settings.integration.auth.wrongHost.%@", table: "Settings"),
                    hosts.map(\.host).joined(separator: ", ")
                )
            )
            .foregroundStyle(.orange)
        case .notAuthenticated, .unknown:
            Text("settings.integration.auth.notAuthenticated", tableName: "Settings")
                .foregroundStyle(.red)
        }
    }
}
