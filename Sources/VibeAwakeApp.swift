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

@main
struct UnsleptApp: App {
    @StateObject private var manager = AwakeManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(manager)
        } label: {
            // Closed lock = awake/protected, open lock = sleep allowed.
            // SF Symbols stay crisp at menu-bar size and auto-tint to the theme.
            Image(systemName: manager.isActive ? "lock.fill" : "lock.open.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
