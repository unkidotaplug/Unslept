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

    // kIOPMAssertionTypePreventSystemSleep blocks system sleep
    // including lid-close on AC power — exactly what vibe coders need.
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
    }

    func deactivate() {
        guard isActive else { return }
        timerCancellable?.cancel()
        timerCancellable = nil
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
        startDate = nil
        elapsedSeconds = 0
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
