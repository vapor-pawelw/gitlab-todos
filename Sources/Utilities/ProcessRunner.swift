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

        let outputCollector = ProcessOutputCollector(
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe
        )
        let state = ProcessRunState()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Output, Error>) in
                process.terminationHandler = { finished in
                    guard let reason = state.finish() else { return }
                    finished.terminationHandler = nil

                    outputCollector.whenFinished { stdoutData, stderrData in
                        switch reason {
                        case .completed:
                            cont.resume(
                                returning: Output(
                                    stdout: stdoutData,
                                    stderr: String(data: stderrData, encoding: .utf8) ?? "",
                                    exitCode: finished.terminationStatus
                                )
                            )
                        case .timedOut:
                            cont.resume(throwing: RunError.timedOut)
                        case .cancelled:
                            cont.resume(throwing: CancellationError())
                        }
                    }
                }

                outputCollector.start()
                do {
                    try process.run()
                    outputCollector.closeWritingEnds()

                    let timeoutTask = Task.detached {
                        try? await Task.sleep(
                            nanoseconds: UInt64(max(0, timeout) * 1_000_000_000)
                        )
                        guard !Task.isCancelled else { return }
                        if state.request(.timedOut) {
                            stop(process)
                        }
                    }
                    state.setTimeoutTask(timeoutTask)

                    if Task.isCancelled {
                        _ = state.request(.cancelled)
                        stop(process)
                    }
                } catch {
                    outputCollector.closeWritingEnds()
                    process.terminationHandler = nil
                    if state.failLaunch() {
                        cont.resume(throwing: RunError.launchFailed(error.localizedDescription))
                    }
                }
            }
        } onCancel: {
            if state.request(.cancelled) {
                stop(process)
            }
        }
    }

    private static func stop(_ process: Process) {
        guard process.isRunning else { return }

        let processIdentifier = process.processIdentifier
        process.terminate()

        // `terminate()` only sends SIGTERM. Escalate so a child that ignores
        // it cannot outlive a timed-out or cancelled request indefinitely.
        Task.detached {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if process.isRunning {
                _ = Darwin.kill(processIdentifier, SIGKILL)
            }
        }
    }
}

private final class ProcessRunState: @unchecked Sendable {
    enum Reason {
        case completed
        case timedOut
        case cancelled
    }

    private let lock = NSLock()
    private var reason = Reason.completed
    private var isFinished = false
    private var timeoutTask: Task<Void, Never>?

    func request(_ requestedReason: Reason) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard !isFinished, reason == .completed else { return false }
        reason = requestedReason
        return true
    }

    func setTimeoutTask(_ task: Task<Void, Never>) {
        lock.lock()
        if isFinished {
            lock.unlock()
            task.cancel()
        } else {
            timeoutTask = task
            lock.unlock()
        }
    }

    func finish() -> Reason? {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return nil
        }
        isFinished = true
        let result = reason
        let task = timeoutTask
        timeoutTask = nil
        lock.unlock()

        task?.cancel()
        return result
    }

    func failLaunch() -> Bool {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return false
        }
        isFinished = true
        let task = timeoutTask
        timeoutTask = nil
        lock.unlock()

        task?.cancel()
        return true
    }
}

private final class ProcessOutputCollector: @unchecked Sendable {
    private let stdoutPipe: Pipe
    private let stderrPipe: Pipe
    private let group = DispatchGroup()
    private let lock = NSLock()
    private var stdoutData = Data()
    private var stderrData = Data()

    init(stdoutPipe: Pipe, stderrPipe: Pipe) {
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
    }

    func start() {
        // Drain both pipes concurrently with the child. Waiting until process
        // exit can deadlock once either kernel pipe buffer becomes full.
        group.enter()
        DispatchQueue.global(qos: .utility).async { [self] in
            let data = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
            lock.lock()
            stdoutData = data
            lock.unlock()
            group.leave()
        }

        group.enter()
        DispatchQueue.global(qos: .utility).async { [self] in
            let data = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
            lock.lock()
            stderrData = data
            lock.unlock()
            group.leave()
        }
    }

    func closeWritingEnds() {
        try? stdoutPipe.fileHandleForWriting.close()
        try? stderrPipe.fileHandleForWriting.close()
    }

    func whenFinished(_ completion: @escaping @Sendable (Data, Data) -> Void) {
        group.notify(queue: .global(qos: .utility)) { [self] in
            lock.lock()
            let stdout = stdoutData
            let stderr = stderrData
            lock.unlock()
            completion(stdout, stderr)
        }
    }
}
