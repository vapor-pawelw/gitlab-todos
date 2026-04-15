import Foundation

enum TodoDiff {
    /// Returns the ids of newly appeared todos. When `lastSeen` is empty and
    /// `isFirstFetch` is true we deliberately return an empty set so the first
    /// cold-launch fetch does not notify the user about every existing item.
    static func newIDs(
        fetched: [Todo],
        lastSeen: Set<Int>,
        isFirstFetch: Bool
    ) -> Set<Int> {
        if isFirstFetch && lastSeen.isEmpty { return [] }
        return Set(fetched.map(\.id)).subtracting(lastSeen)
    }
}
