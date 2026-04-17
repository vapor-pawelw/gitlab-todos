import SwiftUI

struct TodoBadgeView: View {
    let todo: Todo

    var body: some View {
        let state = todo.targetState
        let identifier = todo.relativeIdentifier

        HStack(spacing: 4) {
            if !identifier.isEmpty {
                Text(identifier)
                    .font(.caption2.monospaced().weight(.semibold))
            }
            if let label = state.label {
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(state.tint.opacity(0.18), in: Capsule())
        .foregroundStyle(state.tint)
        .overlay {
            Capsule()
                .stroke(state.tint.opacity(0.35), lineWidth: 0.5)
        }
        .opacity(identifier.isEmpty && state == .none ? 0 : 1)
    }
}
