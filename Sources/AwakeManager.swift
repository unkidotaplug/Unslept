import Foundation
import IOKit.pwr_mgt
import Combine

final class AwakeManager: ObservableObject {
    @Published var isActive = false
    @Published var elapsedSeconds = 0

    private var assertionID: IOPMAssertionID = 0
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?

    // kIOPMAssertionTypePreventSystemSleep blocks system sleep
    // including lid-close on AC power — exactly what vibe coders need
    private let assertionType = kIOPMAssertionTypePreventSystemSleep as CFString
    private let assertionReason = "VibeAwake: AI vibe-coding in progress" as CFString

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
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
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

    var durationString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%dч %02dм %02dс", h, m, s) }
        if m > 0 { return String(format: "%dм %02dс", m, s) }
        return String(format: "%dс", s)
    }
}
