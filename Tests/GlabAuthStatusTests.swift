import Foundation
import Testing

@testable import GitLabTodos

@Suite("GlabService.parseAuthedHosts")
struct GlabAuthStatusTests {
    @Test("extracts host + username pairs from multi-host status output")
    func parsesMultipleHosts() {
        let output = """
        gitlab.com
          x gitlab.com: API call failed: GET ... 401 Unauthorized
          ! No token found
        gitlab.corp.example.com
          ✓ Logged in to gitlab.corp.example.com as alice (/Users/a/Library/Application Support/glab-cli/config.yml)
          ✓ Token found: **************************
        """

        let hosts = GlabService.parseAuthedHosts(from: output)
        #expect(hosts.count == 1)
        #expect(hosts.first?.host == "gitlab.corp.example.com")
        #expect(hosts.first?.username == "alice")
    }

    @Test("returns empty when nothing is authenticated")
    func returnsEmptyWhenNoneAuthed() {
        let output = """
        gitlab.com
          x gitlab.com: API call failed: GET ... 401 Unauthorized
          ! No token found
        """
        #expect(GlabService.parseAuthedHosts(from: output).isEmpty)
    }

    @Test("handles multiple authed hosts and deduplicates")
    func collectsMultipleAuthedHosts() {
        let output = """
        ✓ Logged in to gitlab.com as alice
        ✓ Logged in to self.example.com as bob
        ✓ Logged in to gitlab.com as alice
        """
        let hosts = GlabService.parseAuthedHosts(from: output)
        #expect(hosts.count == 2)
        #expect(hosts.map(\.host) == ["gitlab.com", "self.example.com"])
    }
}
