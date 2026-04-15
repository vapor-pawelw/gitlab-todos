import SwiftUI

struct OnboardingView: View {
    let monitor: TodoMonitorService

    @Environment(\.dismissWindow) private var dismissWindow
    @State private var step: Step = .glabInstall

    enum Step: Int, CaseIterable {
        case glabInstall
        case glabAuth
        case notifications
        case launchAtLogin
        case done

        var index: Int { rawValue + 1 }
        static var totalUserFacing: Int { 4 }
        var isSkippable: Bool {
            switch self {
            case .notifications, .launchAtLogin: true
            default: false
            }
        }
    }

    var body: some View {
        OnboardingShell(
            step: step,
            onBack: goBack,
            onSkip: goNext,
            onContinue: goNext,
            continueEnabled: canContinue
        ) {
            switch step {
            case .glabInstall:
                GlabInstallStep(monitor: monitor)
            case .glabAuth:
                GlabAuthStep(monitor: monitor)
            case .notifications:
                NotificationsStep(monitor: monitor)
            case .launchAtLogin:
                LaunchAtLoginStep(monitor: monitor)
            case .done:
                OnboardingDoneStep()
            }
        }
        .frame(minWidth: 560, minHeight: 440)
    }

    private var canContinue: Bool {
        switch step {
        case .glabInstall: monitor.glab.glabPath != nil
        case .glabAuth: monitor.glab.currentUsername != nil
        case .notifications, .launchAtLogin, .done: true
        }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    private func goNext() {
        if step == .done {
            finish()
            return
        }
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    private func finish() {
        monitor.settings.onboardingCompleted = true
        monitor.settings.save()
        monitor.start()
        dismissWindow(id: "onboarding")
    }
}
