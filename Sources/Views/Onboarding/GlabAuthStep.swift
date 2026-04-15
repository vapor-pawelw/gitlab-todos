import AppKit
import SwiftUI

struct GlabAuthStep: View {
    let monitor: TodoMonitorService

    @State private var isRechecking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.auth.title", tableName: "Onboarding")
                .font(.title3.weight(.semibold))

            Text("onboarding.auth.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            CommandBox(command: "glab auth login")

            if let username = monitor.glab.currentUsername {
                Label {
                    Text(
                        String(
                            format: String(localized: "onboarding.auth.signedIn.%@", table: "Onboarding"),
                            username
                        )
                    )
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Label {
                    Text("onboarding.auth.notAuthenticated", tableName: "Onboarding")
                } icon: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

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
}
