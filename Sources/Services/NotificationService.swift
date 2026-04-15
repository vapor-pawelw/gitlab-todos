import AppKit
import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    enum DeliveryMode: Equatable {
        case individual
        case consolidated
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Pure helper — used at the call site and directly from tests.
    static func deliveryMode(newCount: Int) -> DeliveryMode {
        newCount > 3 ? .consolidated : .individual
    }

    func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            Log.notifications.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func deliver(newTodos: [Todo], dashboardURL: URL?) {
        guard !newTodos.isEmpty else { return }
        let center = UNUserNotificationCenter.current()

        switch Self.deliveryMode(newCount: newTodos.count) {
        case .individual:
            for todo in newTodos {
                let content = UNMutableNotificationContent()
                content.title = String(
                    localized: "notifications.single.title",
                    table: "Notifications"
                )
                content.subtitle = todo.project.pathWithNamespace
                content.body = todo.displayTitle
                content.userInfo = ["url": todo.targetURL.absoluteString]
                content.sound = .default
                let request = UNNotificationRequest(
                    identifier: "todo-\(todo.id)",
                    content: content,
                    trigger: nil
                )
                center.add(request) { error in
                    if let error {
                        Log.notifications.error("Failed to post: \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        case .consolidated:
            let content = UNMutableNotificationContent()
            content.title = String(
                format: String(
                    localized: "notifications.batch.title.%lld",
                    table: "Notifications"
                ),
                newTodos.count
            )
            content.body = String(
                localized: "notifications.batch.body",
                table: "Notifications"
            )
            if let dashboardURL {
                content.userInfo = ["url": dashboardURL.absoluteString]
            }
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "todo-batch-\(UUID().uuidString)",
                content: content,
                trigger: nil
            )
            center.add(request) { error in
                if let error {
                    Log.notifications.error("Failed to post batch: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString)
        {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
}
