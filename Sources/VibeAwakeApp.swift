import SwiftUI
import AppKit

@main
struct UnsleptApp: App {
    @StateObject private var manager = AwakeManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(manager)
        } label: {
            barIcon(active: manager.isActive)
        }
        .menuBarExtraStyle(.window)
    }

    // Custom bar icons (template → auto-tinted to match the menu bar / theme).
    // bar_on = lock-check (protection on), bar_off = lock-minus (off).
    private func barIcon(active: Bool) -> Image {
        let name = active ? "bar_on" : "bar_off"
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let ns = NSImage(contentsOf: url) {
            ns.isTemplate = true
            ns.size = NSSize(width: 18, height: 18)
            return Image(nsImage: ns)
        }
        // fallback if resources are missing (e.g. `swift run` without bundle)
        return Image(systemName: active ? "checkmark.circle.fill" : "minus.circle")
    }
}
