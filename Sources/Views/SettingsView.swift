import SwiftUI

struct SettingsView: View {
    @Bindable var monitor: TodoMonitorService

    var body: some View {
        TabView {
            GeneralSettingsTab(monitor: monitor)
                .tabItem {
                    Label {
                        Text(.Settings.settingsGeneralTab)
                    } icon: {
                        Image(systemName: "gear")
                    }
                }

            IntegrationSettingsTab(monitor: monitor)
                .tabItem {
                    Label {
                        Text(.Settings.settingsIntegrationTab)
                    } icon: {
                        Image(systemName: "terminal")
                    }
                }
        }
        .frame(width: 480, height: 400)
    }
}
