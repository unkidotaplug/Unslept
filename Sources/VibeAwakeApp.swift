// SPDX-License-Identifier: GPL-3.0-or-later
//
// Unslept — keep your Mac awake while AI codes, even with the lid closed.
// Copyright (C) 2026 unkidotaplug
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version. Distributed WITHOUT ANY WARRANTY. See the GNU General
// Public License <https://www.gnu.org/licenses/> for more details.
//

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
