import AppKit
import SwiftUI

struct GlabInstallStep: View {
    let monitor: TodoMonitorService

    @State private var isRechecking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("onboarding.install.title", tableName: "Onboarding")
                .font(.title3.weight(.semibold))

            Text("onboarding.install.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)

            CommandBox(command: "brew install glab")

            if let path = monitor.glab.glabPath?.path {
                Label {
                    Text(
                        String(
                            format: String(localized: "onboarding.install.foundAt.%@", table: "Onboarding"),
                            path
                        )
                    )
                    .font(.caption.monospaced())
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Label {
                    Text("onboarding.install.notFound", tableName: "Onboarding")
                } icon: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Button {
                    isRechecking = true
                    Task {
                        if let found = await OnboardingDetector.findGlabExecutable() {
                            monitor.glab.glabPath = found
                            monitor.settings.glabPath = found
                            monitor.settings.save()
                        }
                        isRechecking = false
                    }
                } label: {
                    Text("onboarding.recheck", tableName: "Onboarding")
                }
                .disabled(isRechecking)

                Button {
                    if let url = URL(string: "https://gitlab.com/gitlab-org/cli/-/releases") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("onboarding.install.downloadManually", tableName: "Onboarding")
                }
                .buttonStyle(.link)
            }
        }
    }
}
