import SwiftUI

@main
struct VibeAwakeApp: App {
    @StateObject private var manager = AwakeManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(manager)
        } label: {
            Image(
                systemName: manager.isActive
                    ? "cup.and.heat.waves.fill"
                    : "moon.zzz.fill"
            )
            .foregroundStyle(manager.isActive ? .orange : .primary)
            .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
