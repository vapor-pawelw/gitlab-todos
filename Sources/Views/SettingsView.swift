import SwiftUI

struct SettingsView: View {
    @Bindable var monitor: TodoMonitorService

    var body: some View {
        TabView {
            GeneralSettingsTab(monitor: monitor)
                .tabItem {
                    Label {
                        Text("settings.general.tab", tableName: "Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }

            IntegrationSettingsTab(monitor: monitor)
                .tabItem {
                    Label {
                        Text("settings.integration.tab", tableName: "Settings")
                    } icon: {
                        Image(systemName: "terminal")
                    }
                }
        }
        .frame(width: 480, height: 400)
    }
}
