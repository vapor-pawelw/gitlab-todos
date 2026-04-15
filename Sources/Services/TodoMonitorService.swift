import Foundation
import Observation

@MainActor
@Observable
final class TodoMonitorService {
    let settings: SettingsManager
    let glab: GlabService
    let notifications: NotificationService

    private(set) var allTodos: [Todo] = []
    private(set) var lastError: GlabError?
    private(set) var lastRefresh: Date?
    private(set) var isLoading = false

    private var optimisticallyDone: Set<Int> = []
    private var timer: Timer?
    private var hasCompletedFirstFetch = false

    init(
        settings: SettingsManager = SettingsManager(),
        glab: GlabService = GlabService(),
        notifications: NotificationService = NotificationService()
    ) {
        self.settings = settings
        self.glab = glab
        self.notifications = notifications

        // Hydrate the service from any previously persisted state so the
        // glab wrapper survives a cold launch without needing onboarding.
        self.glab.glabPath = settings.glabPath
        self.glab.resolvedHost = settings.resolvedHost
    }

    // MARK: - Derived state

    var visibleTodos: [Todo] {
        allTodos
            .filter { !optimisticallyDone.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var badgeCount: Int { visibleTodos.count }

    var dashboardURL: URL {
        glab.dashboardTodosURL ?? URL(string: "https://gitlab.com/dashboard/todos")!
    }

    // MARK: - Lifecycle

    func start() {
        Task { await refreshNow() }
        restartTimer()
    }

    func restartTimer() {
        timer?.invalidate()
        let interval = settings.refreshInterval.seconds
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshNow()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Commands

    func refreshNow() async {
        isLoading = true
        defer {
            isLoading = false
            lastRefresh = Date()
        }

        let result = await glab.fetchTodos()
        switch result {
        case .success(let fetched):
            let fetchedFiltered = fetched.filter { !optimisticallyDone.contains($0.id) }

            let newIDs = TodoDiff.newIDs(
                fetched: fetchedFiltered,
                lastSeen: settings.lastSeenTodoIDs,
                isFirstFetch: !hasCompletedFirstFetch
            )

            if settings.notificationsEnabled && !newIDs.isEmpty {
                let newTodos = fetchedFiltered.filter { newIDs.contains($0.id) }
                glab.resolveHostFromTodos(fetchedFiltered)
                settings.resolvedHost = glab.resolvedHost
                notifications.deliver(newTodos: newTodos, dashboardURL: glab.dashboardTodosURL)
            } else {
                glab.resolveHostFromTodos(fetchedFiltered)
                settings.resolvedHost = glab.resolvedHost
            }

            settings.lastSeenTodoIDs = Set(fetchedFiltered.map(\.id))
            settings.save()

            allTodos = fetchedFiltered
            lastError = nil
            hasCompletedFirstFetch = true

        case .failure(let err):
            Log.monitor.error("Refresh failed: \(String(describing: err), privacy: .public)")
            lastError = err
            // Intentionally keep allTodos as-is: a stale list is more useful
            // than an empty one while the user fixes their glab auth.
        }
    }

    func markDone(_ todo: Todo) async {
        optimisticallyDone.insert(todo.id)
        let result = await glab.markAsDone(id: todo.id)
        switch result {
        case .success:
            allTodos.removeAll { $0.id == todo.id }
            optimisticallyDone.remove(todo.id)
            settings.lastSeenTodoIDs.remove(todo.id)
            settings.save()
        case .failure(let err):
            optimisticallyDone.remove(todo.id)
            lastError = err
            Log.monitor.error("Mark-as-done failed for \(todo.id, privacy: .public): \(String(describing: err), privacy: .public)")
        }
    }

    /// Re-runs glab detection and pushes the resolved state into settings so a
    /// Re-check button in Settings or Onboarding updates the monitor live.
    func recheckIntegration() async {
        if let error = await glab.recheck() {
            lastError = error
        } else {
            lastError = nil
        }
        settings.resolvedHost = glab.resolvedHost
        settings.save()
    }
}
