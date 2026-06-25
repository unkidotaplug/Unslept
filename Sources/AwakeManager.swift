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

import Foundation
import ServiceManagement
import Combine

final class AwakeManager: ObservableObject {
    @Published var isActive = false
    @Published var elapsedSeconds = 0

    /// Auto-off duration in minutes; 0 = never.
    @Published var autoOffMinutes: Int = 0 {
        didSet { UserDefaults.standard.set(autoOffMinutes, forKey: "autoOffMinutes") }
    }

    /// Whether the app is registered to launch at login.
    @Published var launchAtLogin: Bool = false

    // caffeinate -i prevents idle system sleep; -d prevents display sleep.
    // Both run without admin rights and are the Apple-recommended mechanism.
    private var caffeinateProc: Process?
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?

    init() {
        autoOffMinutes = UserDefaults.standard.integer(forKey: "autoOffMinutes")
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    // ── Sleep blocking ──────────────────────────────────────────────────────

    func activate() {
        guard !isActive else { return }

        // Block idle sleep + display sleep (no admin needed)
        let proc = Process()
        proc.launchPath = "/usr/bin/caffeinate"
        proc.arguments = ["-i", "-d"]
        do {
            try proc.run()
            caffeinateProc = proc
        } catch {
            NSLog("Unslept: caffeinate failed: \(error)")
            return
        }

        isActive = true
        startDate = Date()
        elapsedSeconds = 0
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }

        // pmset disablesleep covers lid-close (clamshell) sleep — caffeinate
        // alone can't prevent that. Requires admin via osascript prompt.
        setDisableSleep(true)
    }

    func deactivate() {
        guard isActive else { return }
        setDisableSleep(false)   // re-allow lid-close sleep

        caffeinateProc?.terminate()
        caffeinateProc = nil

        timerCancellable?.cancel()
        timerCancellable = nil
        isActive = false
        startDate = nil
        elapsedSeconds = 0
    }

    // ── Closed-lid sleep (pmset disablesleep, needs admin) ──────────────────

    /// Toggles the system-wide sleep lock that also covers lid-close.
    /// Runs `pmset disablesleep <0|1>` via osascript so macOS shows its native
    /// admin-password prompt. This is the only supported way to keep a Mac
    /// awake with the lid shut and no external display attached.
    private func setDisableSleep(_ on: Bool) {
        let value = on ? "1" : "0"
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.launchPath = "/usr/bin/osascript"
            proc.arguments = [
                "-e",
                "do shell script \"/usr/bin/pmset disablesleep \(value)\" with administrator privileges",
            ]
            do {
                try proc.run()
                proc.waitUntilExit()
                if proc.terminationStatus != 0 {
                    NSLog("Unslept: pmset disablesleep \(value) exited \(proc.terminationStatus)")
                }
            } catch {
                NSLog("Unslept: failed to run pmset: \(error)")
            }
        }
    }

    private func tick() {
        guard isActive, let start = startDate else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(start))

        // auto-off: release the assertion once the limit is reached
        if autoOffMinutes > 0 && elapsedSeconds >= autoOffMinutes * 60 {
            deactivate()
        }
    }

    // ── Launch at login (SMAppService) ──────────────────────────────────────

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Unslept: launch-at-login change failed: \(error)")
        }
        // reflect the real state regardless of success
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    // ── Timer display ───────────────────────────────────────────────────────

    /// Counts down when auto-off is set, otherwise counts up.
    var timerText: String {
        if autoOffMinutes > 0 {
            let remaining = max(0, autoOffMinutes * 60 - elapsedSeconds)
            return Self.format(remaining) + " left"
        }
        return Self.format(elapsedSeconds)
    }

    static func format(_ total: Int) -> String {
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}
