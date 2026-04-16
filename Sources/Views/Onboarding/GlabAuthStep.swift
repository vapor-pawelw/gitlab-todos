import AppKit
import SwiftUI

struct GlabAuthStep: View {
    let monitor: TodoMonitorService

    @State private var isRechecking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(titleLocalized)
                .font(.title3.weight(.semibold))

            bodyContent

            HStack {
                Button {
                    let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
                    NSWorkspace.shared.open(terminal)
                } label: {
                    Text("onboarding.auth.openTerminal", tableName: "Onboarding")
                }

                Button {
                    isRechecking = true
                    Task {
                        await monitor.recheckIntegration()
                        isRechecking = false
                    }
                } label: {
                    Text("onboarding.recheck", tableName: "Onboarding")
                }
                .disabled(isRechecking)
            }
        }
    }

    private var titleLocalized: String {
        switch monitor.glab.authStatus {
        case .wrongDefaultHost:
            String(localized: "onboarding.auth.wrongHost.title", table: "Onboarding")
        default:
            String(localized: "onboarding.auth.title", table: "Onboarding")
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        switch monitor.glab.authStatus {
        case .authenticated:
            authenticatedBody
        case .wrongDefaultHost(let hosts):
            wrongHostBody(hosts: hosts)
        case .notAuthenticated, .unknown:
            notAuthenticatedBody
        }
    }

    private var authenticatedBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("onboarding.auth.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            CommandBox(command: "glab auth login")

            Label {
                Text(
                    String(
                        format: String(localized: "onboarding.auth.signedIn.%@", table: "Onboarding"),
                        monitor.glab.currentUsername ?? ""
                    )
                )
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var notAuthenticatedBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("onboarding.auth.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            CommandBox(command: "glab auth login")

            Label {
                Text("onboarding.auth.notAuthenticated", tableName: "Onboarding")
            } icon: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func wrongHostBody(hosts: [GlabService.AuthedHost]) -> some View {
        let primary = hosts.first
        let defaultHost = monitor.glab.resolvedHost ?? ""
        let authedSummary = hosts.map(\.host).joined(separator: ", ")

        return VStack(alignment: .leading, spacing: 12) {
            Text(
                String(
                    format: String(localized: "onboarding.auth.wrongHost.body.%@", table: "Onboarding"),
                    authedSummary
                )
            )
            .foregroundStyle(.secondary)

            if !defaultHost.isEmpty {
                Label {
                    Text(
                        String(
                            format: String(localized: "onboarding.auth.wrongHost.currentDefault.%@", table: "Onboarding"),
                            defaultHost
                        )
                    )
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Text("onboarding.auth.wrongHost.instruction", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            if let primary {
                CommandBox(command: "glab config set host \(primary.host) --global")
            }
        }
    }
}
