import SwiftUI

struct ErrorBannerView: View {
    let error: GlabError
    let onOpenSetup: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onOpenSetup) {
                    Text(.Menu.menuErrorOpenSetup)
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.red.opacity(0.12))
        .overlay(
            Rectangle()
                .fill(Color.red.opacity(0.25))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var message: String {
        switch error {
        case .glabNotInstalled:
            String(localized: .Menu.menuErrorGlabNotInstalled)
        case .notAuthenticated:
            String(localized: .Menu.menuErrorNotAuthenticated)
        case .network(let detail):
            String(localized: .Menu.menuErrorNetwork(detail))
        case .decoding(let detail):
            String(localized: .Menu.menuErrorDecoding(detail))
        case .nonZeroExit(_, let stderr):
            String(localized: .Menu.menuErrorGeneric(stderr))
        case .timedOut:
            String(localized: .Menu.menuErrorTimedOut)
        case .unknown(let message):
            String(localized: .Menu.menuErrorGeneric(message))
        }
    }
}
