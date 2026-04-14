import SwiftUI

@main
struct GitLabTodosApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("GitLab To-Dos")
                .padding()
        } label: {
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)
    }
}
