import SwiftUI

@main
struct UnsleptApp: App {
    @StateObject private var manager = AwakeManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(manager)
        } label: {
            Image(systemName: manager.isActive ? "sparkles" : "moon.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(manager.isActive ? .orange : .primary)
        }
        .menuBarExtraStyle(.window)
    }
}
