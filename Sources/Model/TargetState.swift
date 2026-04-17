import Foundation
import SwiftUI

enum TargetState: Hashable, Sendable {
    case draft
    case open
    case merged
    case closed
    case reopened
    case none

    init(rawState: String?, isDraft: Bool) {
        if isDraft {
            self = .draft
            return
        }
        switch rawState?.lowercased() {
        case "opened", "open": self = .open
        case "merged": self = .merged
        case "closed": self = .closed
        case "reopened": self = .reopened
        case nil, "": self = .none
        default: self = .none
        }
    }

    var label: LocalizedStringResource? {
        switch self {
        case .draft: .Menu.menuBadgeStateDraft
        case .open: .Menu.menuBadgeStateOpen
        case .merged: .Menu.menuBadgeStateMerged
        case .closed: .Menu.menuBadgeStateClosed
        case .reopened: .Menu.menuBadgeStateReopened
        case .none: nil
        }
    }

    var tint: Color {
        switch self {
        case .draft: .gray
        case .open: .green
        case .merged: .purple
        case .closed: .red
        case .reopened: .green
        case .none: .secondary
        }
    }
}
