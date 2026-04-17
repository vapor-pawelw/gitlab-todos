import AppKit
import SwiftUI

struct GlabInstallStep: View {
    let monitor: TodoMonitorService

    @State private var isRechecking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.Onboarding.onboardingInstallTitle)
                .font(.title3.weight(.semibold))

            Text(.Onboarding.onboardingInstallBody)
                .foregroundStyle(.secondary)

            CommandBox(command: "brew install glab")

            if let path = monitor.glab.glabPath?.path {
                Label {
                    Text(.Onboarding.onboardingInstallFoundAt(path))
                    .font(.caption.monospaced())
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Label {
                    Text(.Onboarding.onboardingInstallNotFound)
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
                    Text(.Onboarding.onboardingRecheck)
                }
                .disabled(isRechecking)

                Button {
                    if let url = URL(string: "https://gitlab.com/gitlab-org/cli/-/releases") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(.Onboarding.onboardingInstallDownloadManually)
                }
                .buttonStyle(.link)
            }
        }
    }
}
