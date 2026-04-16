import AppKit
import SwiftUI

struct TodoListView: View {
    @Bindable var monitor: TodoMonitorService
    let updates: UpdateService
    @Environment(\.openWindow) private var openWindow

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
                Text("menu.header.title", tableName: "Menu")
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
                .help(Text("menu.header.openInBrowser.tooltip", tableName: "Menu"))

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
                .help(Text("menu.header.refresh.tooltip", tableName: "Menu"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var headerSubtitle: some View {
        if let lastRefresh = monitor.lastRefresh {
            Text(
                String(
                    format: String(localized: "menu.header.updated.%@", table: "Menu"),
                    RelativeTime.string(from: lastRefresh)
                )
            )
        } else {
            Text("menu.header.neverUpdated", tableName: "Menu")
        }
    }

    @ViewBuilder
    private var content: some View {
        if monitor.visibleTodos.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("menu.empty.title", tableName: "Menu")
                    .font(.headline)
                Text("menu.empty.subtitle", tableName: "Menu")
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
            Text(
                String(
                    format: String(localized: "menu.footer.pendingCount.%lld", table: "Menu"),
                    monitor.visibleTodos.count
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            SettingsLink {
                Text("menu.action.settings", tableName: "Menu")
            }
            .buttonStyle(.borderless)
            .font(.caption)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("menu.action.quit", tableName: "Menu")
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
