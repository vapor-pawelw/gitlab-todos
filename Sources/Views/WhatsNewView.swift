import SwiftUI

struct WhatsNewView: View {
    let updates: UpdateService

    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let entry = updates.whatsNewEntry {
                        Text(entry.body)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("whatsNew.empty", tableName: "Menu")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }

            Divider()

            footer
        }
        .frame(minWidth: 520, minHeight: 420)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("whatsNew.title", tableName: "Menu")
                .font(.title2.weight(.semibold))
            Text(
                String(
                    format: String(localized: "whatsNew.version.%@", table: "Menu"),
                    updates.currentVersion
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(20)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                updates.acknowledgeCurrentVersion()
                dismissWindow(id: "whats-new")
            } label: {
                Text("whatsNew.dismiss", tableName: "Menu")
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}
