import AppKit
import SwiftUI

struct TodoListView: View {
    @Bindable var monitor: TodoMonitorService
    let updates: UpdateService
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header

            if let error = monitor.lastError {
                ErrorBannerView(error: error) {
                    openWindow(id: "onboarding")
                }
            }

            Divider()

            content

            Divider()

            footer
        }
        .frame(width: 420, height: 560)
        .task {
            await performFirstLaunchIfNeeded()
        }
        .onAppear {
            monitor.markMenuOpened()
            Task { await monitor.refreshNow() }
        }
    }

    private func performFirstLaunchIfNeeded() async {
        if !monitor.settings.onboardingCompleted {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "onboarding")
            updates.seedIfNeeded()
            return
        }

        if updates.shouldShowWhatsNew {
            updates.loadWhatsNew()
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "whats-new")
        } else {
            updates.seedIfNeeded()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(.Menu.menuHeaderTitle)
                    .font(.headline)
                headerSubtitle
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Button {
                    NSWorkspace.shared.open(monitor.dashboardURL)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
                .help(Text(.Menu.menuHeaderOpenInBrowserTooltip))

                Button {
                    Task { await monitor.refreshNow() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(monitor.isLoading ? 360 : 0))
                        .animation(
                            monitor.isLoading
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: monitor.isLoading
                        )
                }
                .buttonStyle(.borderless)
                .help(Text(.Menu.menuHeaderRefreshTooltip))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var headerSubtitle: some View {
        if let lastRefresh = monitor.lastRefresh {
            Text(.Menu.menuHeaderUpdated(RelativeTime.string(from: lastRefresh)))
        } else {
            Text(.Menu.menuHeaderNeverUpdated)
        }
    }

    @ViewBuilder
    private var content: some View {
        if monitor.visibleTodos.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text(.Menu.menuEmptyTitle)
                    .font(.headline)
                Text(.Menu.menuEmptySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(monitor.visibleTodos) { todo in
                        TodoRowView(
                            todo: todo,
                            currentUsername: monitor.glab.currentUsername,
                            onMarkDone: { Task { await monitor.markDone(todo) } },
                            onOpen: {
                                NSWorkspace.shared.open(todo.targetURL)
                                dismissMenuBarExtra()
                            }
                        )
                        Divider()
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(.Menu.menuFooterPendingCount(monitor.visibleTodos.count))
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
                _ = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Text(.Menu.menuActionSettings)
            }
            .buttonStyle(.borderless)
            .font(.caption)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text(.Menu.menuActionQuit)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func dismissMenuBarExtra() {
        for window in NSApplication.shared.windows {
            let className = String(describing: type(of: window))
            if className.contains("MenuBarExtra") || className.contains("NSPopover") {
                window.orderOut(nil)
            }
        }
    }
}
