import AppKit
import SwiftUI

@MainActor
final class MenuBarStatusItemController: NSObject {
    private let monitor: TodoMonitorService
    private let updates: UpdateService
    private let avatarCache: AvatarCache
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var updateTimer: Timer?
    private var blinkReminderTimer: Timer?
    private var blinkStepTimer: Timer?
    private var blinkReminderInterval: TimeInterval?
    private var remainingBlinkSteps = 0
    private var isBlinkAlertVisible = false
    private lazy var redDotImage = Self.makeRedDotImage()

    init(monitor: TodoMonitorService, updates: UpdateService, avatarCache: AvatarCache) {
        self.monitor = monitor
        self.updates = updates
        self.avatarCache = avatarCache
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configurePopover()
        configureStatusButton()
        updateStatusButton()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusButton()
                self?.synchronizeBlinkReminderTimer()
            }
        }
    }

    private func configurePopover() {
        let content = TodoListView(monitor: monitor, updates: updates)
            .environment(\.avatarCache, avatarCache)

        popover.contentSize = NSSize(width: 420, height: 560)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: content)
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.title = " 0"
        button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }

        if isBlinkAlertVisible {
            button.image = redDotImage
            button.image?.isTemplate = false
        } else if monitor.lastError != nil {
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: nil)
            button.image?.isTemplate = true
        } else if monitor.settings.onboardingCompleted {
            button.image = monitor.badgeCount == 0
                ? GitLabTodosAsset.todoDoneClear.image
                : GitLabTodosAsset.todoDone.image
            button.image?.isTemplate = monitor.badgeCount > 0
        } else {
            button.image = GitLabTodosAsset.todoDone.image
            button.image?.isTemplate = true
        }

        if button.image == nil {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
        }
        button.title = " \(monitor.badgeCount)"
        button.toolTip = "GitLab To-Dos"
    }

    private func synchronizeBlinkReminderTimer() {
        guard monitor.lastError == nil,
              monitor.settings.notificationsEnabled,
              monitor.hasUnseenTodos,
              let interval = monitor.settings.unreadReminderInterval.seconds
        else {
            stopBlinkReminderTimer()
            stopBlinkSequence()
            return
        }

        guard blinkReminderTimer == nil || blinkReminderInterval != interval else {
            return
        }

        stopBlinkReminderTimer()
        blinkReminderInterval = interval
        blinkReminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.startBlinkSequence()
            }
        }
    }

    private func stopBlinkReminderTimer() {
        blinkReminderTimer?.invalidate()
        blinkReminderTimer = nil
        blinkReminderInterval = nil
    }

    private func startBlinkSequence() {
        guard monitor.lastError == nil,
              monitor.settings.notificationsEnabled,
              monitor.hasUnseenTodos
        else {
            stopBlinkSequence()
            return
        }

        remainingBlinkSteps = 6
        isBlinkAlertVisible = true
        updateStatusButton()

        blinkStepTimer?.invalidate()
        blinkStepTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self,
                      self.monitor.lastError == nil,
                      self.monitor.hasUnseenTodos,
                      self.remainingBlinkSteps > 0
                else {
                    self?.stopBlinkSequence()
                    return
                }

                self.isBlinkAlertVisible.toggle()
                self.remainingBlinkSteps -= 1
                self.updateStatusButton()

                if self.remainingBlinkSteps == 0 {
                    self.stopBlinkSequence()
                }
            }
        }
    }

    private func stopBlinkSequence() {
        blinkStepTimer?.invalidate()
        blinkStepTimer = nil
        remainingBlinkSteps = 0
        if isBlinkAlertVisible {
            isBlinkAlertVisible = false
            updateStatusButton()
        }
    }

    private static func makeRedDotImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            monitor.markMenuOpened()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
