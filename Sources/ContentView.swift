import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: AwakeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow
            statusCard
            toggleButton
            footerRow
        }
        .padding(14)
        .frame(width: 256)
        // single animation driver — everything transitions together
        .animation(.easeInOut(duration: 0.22), value: manager.isActive)
    }

    // ── Title ─────────────────────────────────────────────────────────────

    private var titleRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.orange)
            Text("VibeAwake")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("v1.0")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // ── Status card — FIXED height so nothing ever jumps ──────────────────

    private var statusCard: some View {
        VStack(spacing: 7) {
            Image(systemName: manager.isActive ? "cup.and.heat.waves.fill" : "moon.zzz.fill")
                .font(.system(size: 30))
                .frame(width: 36, height: 36)           // lock icon frame
                .foregroundStyle(manager.isActive ? .orange : Color(nsColor: .secondaryLabelColor))

            Text(manager.isActive ? "Мак не заснёт" : "Мак может спать")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(manager.isActive ? .primary : Color(nsColor: .secondaryLabelColor))

            // always rendered — opacity hides it when inactive
            Text(manager.isActive ? manager.durationString : "0с")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .opacity(manager.isActive ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)                             // fixed height = zero jitter
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(manager.isActive
                      ? Color.orange.opacity(0.10)
                      : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            manager.isActive
                                ? Color.orange.opacity(0.25)
                                : Color(nsColor: .separatorColor).opacity(0.4),
                            lineWidth: 1
                        )
                )
        )
    }

    // ── Toggle — fixed frame, text same length ─────────────────────────────

    private var toggleButton: some View {
        Button {
            manager.isActive ? manager.deactivate() : manager.activate()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: manager.isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 14))
                Text(manager.isActive ? "Выключить" : "Включить ")  // trailing space = equal width
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
        }
        .buttonStyle(.borderedProminent)
        .tint(manager.isActive ? Color(red: 0.85, green: 0.25, blue: 0.25) : Color.blue)
        .transaction { t in t.animation = nil }         // suppress button's own bounce
    }

    // ── Footer — always rendered, opacity-only change ──────────────────────

    private var footerRow: some View {
        HStack {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                Text("На зарядке работает лучше")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.orange.opacity(0.85))
            .opacity(manager.isActive ? 1 : 0)          // never shifts layout

            Spacer()

            Button("Выйти") {
                manager.deactivate()
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .frame(height: 16)                              // fixed footer height
    }
}
