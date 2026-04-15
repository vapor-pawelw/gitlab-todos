import Foundation
import Observation

@Observable
final class GlabService {
    /// Path to the resolved `glab` executable. Set by `OnboardingDetector` / `recheck()`.
    var glabPath: URL?

    /// Authenticated user's `username`, set on successful `recheck()`.
    var currentUsername: String?

    /// Authenticated user's `name`, set on successful `recheck()`.
    var currentUserDisplayName: String?

    /// Resolved GitLab host, e.g. `"gitlab.com"` or a self-hosted instance.
    var resolvedHost: String?

    /// Dashboard URL for "Open in browser" links in the menu header.
    var dashboardTodosURL: URL? {
        guard let resolvedHost else { return nil }
        return URL(string: "https://\(resolvedHost)/dashboard/todos")
    }

    // MARK: - Commands

    func fetchTodos() async -> Result<[Todo], GlabError> {
        guard let glabPath else { return .failure(.glabNotInstalled) }
        let output: ProcessRunner.Output
        do {
            output = try await ProcessRunner.run(
                glabPath,
                arguments: ["api", "--paginate", "/todos?per_page=100&state=pending"],
                environment: Self.shellEnvironment,
                timeout: 45
            )
        } catch ProcessRunner.RunError.timedOut {
            return .failure(.timedOut)
        } catch {
            return .failure(.unknown(String(describing: error)))
        }

        guard output.exitCode == 0 else {
            return .failure(GlabError.classify(exitCode: output.exitCode, stderr: output.stderr))
        }
        do {
            let todos = try Self.decodeTodos(output.stdout)
            return .success(todos)
        } catch {
            let snippet = String(data: output.stdout.prefix(200), encoding: .utf8) ?? ""
            Log.glab.error("Decode failed: \(error.localizedDescription, privacy: .public) — \(snippet, privacy: .public)")
            return .failure(.decoding(error.localizedDescription))
        }
    }

    func markAsDone(id: Int) async -> Result<Void, GlabError> {
        guard let glabPath else { return .failure(.glabNotInstalled) }
        let output: ProcessRunner.Output
        do {
            output = try await ProcessRunner.run(
                glabPath,
                arguments: ["api", "--method", "POST", "/todos/\(id)/mark_as_done"],
                environment: Self.shellEnvironment,
                timeout: 15
            )
        } catch ProcessRunner.RunError.timedOut {
            return .failure(.timedOut)
        } catch {
            return .failure(.unknown(String(describing: error)))
        }
        guard output.exitCode == 0 else {
            return .failure(GlabError.classify(exitCode: output.exitCode, stderr: output.stderr))
        }
        return .success(())
    }

    /// Refreshes `currentUsername`, `currentUserDisplayName` and `resolvedHost`.
    /// Returns the first hard error encountered so the caller can surface it.
    @discardableResult
    func recheck() async -> GlabError? {
        guard let glabPath else { return .glabNotInstalled }

        // Host (non-fatal: fall back to parsing target_url later).
        if let host = await resolveHost(executable: glabPath) {
            resolvedHost = host
        }

        // Current user.
        let userOutput: ProcessRunner.Output
        do {
            userOutput = try await ProcessRunner.run(
                glabPath,
                arguments: ["api", "/user"],
                environment: Self.shellEnvironment,
                timeout: 15
            )
        } catch ProcessRunner.RunError.timedOut {
            return .timedOut
        } catch {
            return .unknown(String(describing: error))
        }
        guard userOutput.exitCode == 0 else {
            return GlabError.classify(exitCode: userOutput.exitCode, stderr: userOutput.stderr)
        }
        if let decoded = try? JSONDecoder().decode(CurrentUser.self, from: userOutput.stdout) {
            currentUsername = decoded.username
            currentUserDisplayName = decoded.name
        }
        return nil
    }

    private func resolveHost(executable: URL) async -> String? {
        let output: ProcessRunner.Output
        do {
            output = try await ProcessRunner.run(
                executable,
                arguments: ["config", "get", "host"],
                environment: Self.shellEnvironment,
                timeout: 5
            )
        } catch {
            return nil
        }
        guard output.exitCode == 0 else { return nil }
        let host = String(data: output.stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let host, !host.isEmpty else { return nil }
        return host
    }

    /// Backfills `resolvedHost` from a fetched todo's `target_url` when
    /// `glab config get host` didn't return anything. Call after a successful
    /// fetch when `resolvedHost == nil`.
    func resolveHostFromTodos(_ todos: [Todo]) {
        guard resolvedHost == nil,
              let host = Self.parseHost(from: todos.first?.targetURL)
        else { return }
        resolvedHost = host
    }

    // MARK: - Pure helpers (used by the service and tests)

    static func decodeTodos(_ data: Data) throws -> [Todo] {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let d = formatter.date(from: raw) { return d }
            if let d = fallback.date(from: raw) { return d }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(raw)"
            )
        }
        return try decoder.decode([Todo].self, from: data)
    }

    static func parseHost(from url: URL?) -> String? {
        guard let url, let host = url.host, !host.isEmpty else { return nil }
        return host
    }

    private static var shellEnvironment: [String: String] {
        var env: [String: String] = [
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:/usr/bin:/bin",
            "HOME": NSHomeDirectory(),
        ]
        let passthrough = [
            "USER", "LOGNAME", "LANG", "LC_ALL",
            "XDG_CONFIG_HOME", "GLAB_CONFIG_DIR",
            "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY",
        ]
        for key in passthrough {
            if let value = ProcessInfo.processInfo.environment[key] {
                env[key] = value
            }
        }
        return env
    }

    private struct CurrentUser: Decodable {
        let username: String
        let name: String
    }
}
