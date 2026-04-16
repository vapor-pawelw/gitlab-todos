import AppKit
import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let currentUsername: String?
    let onMarkDone: () -> Void
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onMarkDone) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(Text("menu.action.markAsDone", tableName: "Menu"))

            AvatarView(url: todo.author.avatarURL, size: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TodoBadgeView(todo: todo)
                    Text(todo.displayTitle)
                        .font(.body.weight(.semibold))
                        .lineLimit(2)
                        .truncationMode(.tail)
                }

                Text(todo.project.pathWithNamespace)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    ActionDescriptionText(todo: todo, currentUsername: currentUsername)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    Text(RelativeTime.string(from: todo.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onOpen)
        .contextMenu {
            Button {
                onOpen()
            } label: {
                Text("menu.action.openInBrowser", tableName: "Menu")
            }
            Button(action: onMarkDone) {
                Text("menu.action.markAsDone", tableName: "Menu")
            }
            Divider()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(todo.targetURL.absoluteString, forType: .string)
            } label: {
                Text("menu.action.copyURL", tableName: "Menu")
            }
        }
    }
}
