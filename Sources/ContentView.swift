import SwiftUI

// ── Liquid Glass card modifier ─────────────────────────────────────────────
// Layered approach matching Apple's macOS 26 / iOS 26 glass:
//   1. ultraThinMaterial base (blur + vibrancy)
//   2. Optional color tint
//   3. Top specular highlight  ← the defining glass element
//   4. Bottom inner reflection ← gives thickness/depth
//   5. Gradient rim border     ← bright top, dark bottom (lit from above)
//   6. Drop shadow             ← lifts the pane off the surface
private struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color = .clear
    var tintOpacity: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 1. blur/vibrancy base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // 2. color tint
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(tintOpacity))

                    // 3. top specular — the signature glass highlight
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.52), location: 0.00),
                                .init(color: .white.opacity(0.22), location: 0.18),
                                .init(color: .white.opacity(0.00), location: 0.42),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // 4. bottom inner reflection — gives the pane depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .clear,               location: 0.78),
                                .init(color: .white.opacity(0.07), location: 1.00),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // 5. gradient rim border (lit from top-left, shadowed on bottom)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.60), location: 0.00),
                                    .init(color: .white.opacity(0.22), location: 0.30),
                                    .init(color: .white.opacity(0.06), location: 0.65),
                                    .init(color: .black.opacity(0.07), location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
            }
            // 6. soft drop shadow lifts the pane
            .shadow(color: .black.opacity(0.13), radius: 5, x: 0, y: 2.5)
    }
}

// ── Midnight Liquid Glass button (Apple Tahoe / 21st.dev style) ────────────
// A glossy capsule in MacBook Air "Midnight" tone. Glass is built from layers:
//   1. midnight vertical gradient base (catches light at top, deep at bottom)
//   2. top specular gloss — the bright reflection across the upper third
//   3. dual rim: bright top edge + faint bottom refraction, dark sides
//   4. floating drop shadow (+ warm glow when active)
private struct MidnightGlassButtonStyle: ButtonStyle {
    var active: Bool = false

    // MacBook Air "Midnight" — deep blue-black
    private let top    = Color(red: 0.17, green: 0.20, blue: 0.27)   // #2B3345
    private let bottom = Color(red: 0.075, green: 0.088, blue: 0.13) // #131722

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                ZStack {
                    // 1. midnight base
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [top, bottom],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // 2. top specular gloss
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.28), location: 0.00),
                                .init(color: .white.opacity(0.08), location: 0.30),
                                .init(color: .white.opacity(0.00), location: 0.55),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .blendMode(.plusLighter)

                    // 3. dual rim — bright top, faint bottom refraction, dark sides
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.60), location: 0.00),
                                    .init(color: .white.opacity(0.10), location: 0.35),
                                    .init(color: .black.opacity(0.18), location: 0.72),
                                    .init(color: .white.opacity(0.22), location: 1.00),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.9
                        )
                }
            }
            // 4. floating shadow + warm glow when active
            .shadow(color: .black.opacity(0.50), radius: 13, x: 0, y: 7)
            .shadow(color: .black.opacity(0.30), radius: 3,  x: 0, y: 1)
            .shadow(color: active ? Color.orange.opacity(0.38) : .clear,
                    radius: 11, x: 0, y: 3)
            // press feedback
            .scaleEffect(configuration.isPressed ? 0.965 : 1.00)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(duration: 0.14, bounce: 0.22), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.25), value: active)
    }
}

// ── ContentView ───────────────────────────────────────────────────────────

struct ContentView: View {
    @EnvironmentObject var manager: AwakeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow
            statusCard
            toggleButton
            quitRow
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
            Text("v1.1")
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

            // always in layout, opacity hides it → zero layout shift
            Text(manager.isActive ? manager.durationString : "0с")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .opacity(manager.isActive ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .modifier(LiquidGlassModifier(
            cornerRadius: 20,
            tint: .orange,
            tintOpacity: manager.isActive ? 0.07 : 0
        ))
    }

    // ── Toggle — liquid glass button ───────────────────────────────────────

    private var toggleButton: some View {
        Button {
            manager.isActive ? manager.deactivate() : manager.activate()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: manager.isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(manager.isActive ? "Выключить" : "Включить")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .buttonStyle(MidnightGlassButtonStyle(active: manager.isActive))
    }

    // ── Quit ──────────────────────────────────────────────────────────────

    private var quitRow: some View {
        HStack {
            Spacer()
            Button("Выйти") {
                manager.deactivate()
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(height: 14)
    }
}
