import Foundation
import UserNotifications

enum OnboardingDetector {
    static let defaultCandidates: [String] = [
        "/opt/homebrew/bin/glab",
        "/usr/local/bin/glab",
        "/opt/local/bin/glab",
        "/usr/bin/glab",
    ]

    /// Probes the well-known install locations first, then falls back to a
    /// login-interactive shell so PATH entries from zprofile/zshrc apply.
    static func findGlabExecutable() async -> URL? {
        for path in defaultCandidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        let shell = URL(fileURLWithPath: "/bin/zsh")
        let output: ProcessRunner.Output
        do {
            output = try await ProcessRunner.run(
                shell,
                arguments: ["-lic", "command -v glab"],
                environment: minimalShellEnvironment,
                timeout: 5
            )
        } catch {
            return nil
        }
        guard output.exitCode == 0 else { return nil }
        let trimmed = String(data: output.stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        guard FileManager.default.isExecutableFile(atPath: trimmed) else { return nil }
        return URL(fileURLWithPath: trimmed)
    }

    struct AuthProbe: Sendable {
        let isAuthenticated: Bool
        let username: String?
        let displayName: String?
    }

    /// Runs `glab auth status` and, when successful, follows up with
    /// `glab api /user` to surface the signed-in identity.
    static func checkGlabAuth(executable: URL) async -> AuthProbe {
        let status: ProcessRunner.Output
        do {
            status = try await ProcessRunner.run(
                executable,
                arguments: ["auth", "status"],
                environment: minimalShellEnvironment,
                timeout: 10
            )
        } catch {
            return AuthProbe(isAuthenticated: false, username: nil, displayName: nil)
        }
        guard status.exitCode == 0 else {
            return AuthProbe(isAuthenticated: false, username: nil, displayName: nil)
        }

        let user: ProcessRunner.Output
        do {
            user = try await ProcessRunner.run(
                executable,
                arguments: ["api", "/user"],
                environment: minimalShellEnvironment,
                timeout: 10
            )
        } catch {
            return AuthProbe(isAuthenticated: true, username: nil, displayName: nil)
        }
        guard user.exitCode == 0,
              let decoded = try? JSONDecoder().decode(UserPayload.self, from: user.stdout)
        else {
            return AuthProbe(isAuthenticated: true, username: nil, displayName: nil)
        }
        return AuthProbe(
            isAuthenticated: true,
            username: decoded.username,
            displayName: decoded.name
        )
    }

    static func checkNotificationPermission() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private static var minimalShellEnvironment: [String: String] {
        var env: [String: String] = [
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:/usr/bin:/bin",
            "HOME": NSHomeDirectory(),
        ]
        for key in ["USER", "LOGNAME", "LANG", "LC_ALL", "XDG_CONFIG_HOME", "GLAB_CONFIG_DIR"] {
            if let value = ProcessInfo.processInfo.environment[key] {
                env[key] = value
            }
        }
        return env
    }

    private struct UserPayload: Decodable {
        let username: String
        let name: String
    }
}
