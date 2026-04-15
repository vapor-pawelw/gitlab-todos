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
                    Text("menu.error.openSetup", tableName: "Menu")
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
            String(localized: "menu.error.glabNotInstalled", table: "Menu")
        case .notAuthenticated:
            String(localized: "menu.error.notAuthenticated", table: "Menu")
        case .network(let detail):
            String(format: String(localized: "menu.error.network.%@", table: "Menu"), detail)
        case .decoding(let detail):
            String(format: String(localized: "menu.error.decoding.%@", table: "Menu"), detail)
        case .nonZeroExit(_, let stderr):
            String(format: String(localized: "menu.error.generic.%@", table: "Menu"), stderr)
        case .timedOut:
            String(localized: "menu.error.timedOut", table: "Menu")
        case .unknown(let message):
            String(format: String(localized: "menu.error.generic.%@", table: "Menu"), message)
        }
    }
}
