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
        .animation(.easeInOut(duration: 0.25), value: manager.isActive)
    }

    // ── Title ─────────────────────────────────────────────────────────────

    private var titleRow: some View {
        HStack {
            Text("Unslept")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("v2.0")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // ── Status card — liquid glass ─────────────────────────────────────────

    private var statusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: manager.isActive ? "cup.and.heat.waves.fill" : "moon.zzz.fill")
                .font(.system(size: 30))
                .frame(width: 40, height: 38)
                .foregroundStyle(manager.isActive ? .orange : Color(nsColor: .secondaryLabelColor))

            Text(manager.isActive ? "Мак не заснёт" : "Мак может спать")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(manager.isActive ? .primary : Color(nsColor: .secondaryLabelColor))

            // always in layout — opacity hides when inactive → zero jitter
            Text(manager.isActive ? manager.durationString : "0с")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .opacity(manager.isActive ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)          // fixed height → never shifts layout
        .background { glassCard }
    }

    // liquid glass card background
    private var glassCard: some View {
        ZStack {
            // 1. translucent base
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            // 2. warm tint when active
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(manager.isActive ? Color.orange.opacity(0.08) : Color.clear)

            // 3. glass specular highlight — diagonal sheen from top-left
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.18), location: 0),
                    .init(color: .white.opacity(0),    location: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 4. glass edge — gradient border, lighter on top
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }

    // ── Toggle — custom glass button, fixed size ───────────────────────────

    private var toggleButton: some View {
        Button {
            manager.isActive ? manager.deactivate() : manager.activate()
        } label: {
            ZStack {
                // button fill
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(manager.isActive
                          ? Color(red: 0.82, green: 0.22, blue: 0.22).opacity(0.88)
                          : Color(red: 0.18, green: 0.50, blue: 0.95).opacity(0.88))

                // button glass sheen
                LinearGradient(
                    colors: [.white.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // button border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.20), lineWidth: 0.5)

                // label
                HStack(spacing: 6) {
                    Image(systemName: manager.isActive ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 13))
                    Text(manager.isActive ? "Выключить" : "Включить ")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .transaction { t in t.animation = nil }  // no bounce on button itself
    }

    // ── Footer — always rendered ───────────────────────────────────────────

    private var footerRow: some View {
        HStack {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                Text("Лучше на зарядке")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.orange.opacity(0.85))
            .opacity(manager.isActive ? 1 : 0)

            Spacer()

            Button("Выйти") {
                manager.deactivate()
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .frame(height: 16)           // fixed footer → no shift
    }
}
