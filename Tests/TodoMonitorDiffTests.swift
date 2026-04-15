import Foundation
import Testing
@testable import GitLabTodos

@Suite("TodoDiff")
struct TodoMonitorDiffTests {
    private static func makeTodo(id: Int) -> Todo {
        let json = """
        {
            "id": \(id),
            "action_name": "mentioned",
            "target_type": "MergeRequest",
            "target_url": "https://gitlab.com/x/y/-/merge_requests/\(id)",
            "body": "t",
            "state": "pending",
            "created_at": "2026-04-12T09:15:00Z",
            "project": {"id": 1, "name_with_namespace": "X", "path_with_namespace": "x/y"},
            "author": {"id": 1, "username": "a", "name": "A", "avatar_url": null},
            "target": {"id": 1, "iid": \(id), "title": "t", "state": "opened", "draft": false, "work_in_progress": false}
        }
        """.data(using: .utf8)!
        return try! GlabService.decodeTodos("[\(String(data: json, encoding: .utf8)!)]".data(using: .utf8)!)[0]
    }

    @Test("silent seed on first fetch with empty lastSeen")
    func silentSeed() {
        let fetched = [Self.makeTodo(id: 1), Self.makeTodo(id: 2)]
        let newIDs = TodoDiff.newIDs(fetched: fetched, lastSeen: [], isFirstFetch: true)
        #expect(newIDs.isEmpty)
    }

    @Test("diff on subsequent fetch picks up new ids only")
    func normalDiff() {
        let fetched = [Self.makeTodo(id: 1), Self.makeTodo(id: 2), Self.makeTodo(id: 3)]
        let newIDs = TodoDiff.newIDs(fetched: fetched, lastSeen: [1], isFirstFetch: false)
        #expect(newIDs == [2, 3])
    }

    @Test("removed items do not count as new")
    func removedIgnored() {
        let fetched = [Self.makeTodo(id: 1)]
        let newIDs = TodoDiff.newIDs(fetched: fetched, lastSeen: [1, 2, 3], isFirstFetch: false)
        #expect(newIDs.isEmpty)
    }

    @Test("non-first fetch with empty lastSeen still treats everything as new")
    func relaunchedWithClearedLastSeen() {
        let fetched = [Self.makeTodo(id: 1), Self.makeTodo(id: 2)]
        let newIDs = TodoDiff.newIDs(fetched: fetched, lastSeen: [], isFirstFetch: false)
        #expect(newIDs == [1, 2])
    }
}
