import Foundation

enum ProcessRunner {
    struct Output: Sendable {
        let stdout: Data
        let stderr: String
        let exitCode: Int32
    }

    enum RunError: Error {
        case timedOut
        case launchFailed(String)
    }

    static func run(
        _ executable: URL,
        arguments: [String] = [],
        environment: [String: String],
        timeout: TimeInterval = 30
    ) async throws -> Output {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let box = ResumeBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Output, Error>) in
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(max(0, timeout) * 1_000_000_000))
                    if Task.isCancelled { return }
                    if box.claim() {
                        if process.isRunning { process.terminate() }
                        cont.resume(throwing: RunError.timedOut)
                    }
                }

                process.terminationHandler = { finished in
                    if box.claim() {
                        timeoutTask.cancel()
                        let stdoutData = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
                        let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
                        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
                        cont.resume(
                            returning: Output(
                                stdout: stdoutData,
                                stderr: stderrString,
                                exitCode: finished.terminationStatus
                            )
                        )
                    }
                }

                do {
                    try process.run()
                } catch {
                    if box.claim() {
                        timeoutTask.cancel()
                        cont.resume(throwing: RunError.launchFailed(error.localizedDescription))
                    }
                }
            }
        } onCancel: {
            if process.isRunning { process.terminate() }
        }
    }
}

private final class ResumeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !claimed else { return false }
        claimed = true
        return true
    }
}
