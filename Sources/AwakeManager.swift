import Foundation
import IOKit.pwr_mgt
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

    private var assertionID: IOPMAssertionID = 0
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?

    // NOTE: this assertion only blocks *idle* sleep. It does NOT stop sleep
    // when the lid is physically closed (clamshell sleep) — macOS handles that
    // separately and ignores assertions. For closed-lid we use `pmset
    // disablesleep` below, which is the only mechanism that works without an
    // external display (and requires admin rights).
    private let assertionType = kIOPMAssertionTypePreventSystemSleep as CFString
    private let assertionReason = "Unslept: keeping your Mac awake" as CFString

    init() {
        autoOffMinutes = UserDefaults.standard.integer(forKey: "autoOffMinutes")
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    // ── Sleep blocking ──────────────────────────────────────────────────────

    func activate() {
        guard !isActive else { return }
        let result = IOPMAssertionCreateWithName(
            assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionReason,
            &assertionID
        )
        guard result == kIOReturnSuccess else { return }

        isActive = true
        startDate = Date()
        elapsedSeconds = 0
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }

        // the part that actually keeps the Mac awake with the lid closed
        setDisableSleep(true)
    }

    func deactivate() {
        guard isActive else { return }
        setDisableSleep(false)   // re-allow lid-close sleep
        timerCancellable?.cancel()
        timerCancellable = nil
        IOPMAssertionRelease(assertionID)
        assertionID = 0
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
