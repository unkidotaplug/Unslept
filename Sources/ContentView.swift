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

// ── Liquid Glass button style ──────────────────────────────────────────────
private struct LiquidGlassButtonStyle: ButtonStyle {
    var color: Color = .blue
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                ZStack {
                    // solid color base (gives button its identity)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(color)

                    // ultra-thin vibrancy over the color
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.25))

                    // top specular — same glass formula, more intense on buttons
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.48), location: 0.00),
                                .init(color: .white.opacity(0.18), location: 0.22),
                                .init(color: .white.opacity(0.00), location: 0.50),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // gradient rim
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.55), location: 0.00),
                                    .init(color: .white.opacity(0.15), location: 0.45),
                                    .init(color: .black.opacity(0.06), location: 1.00),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                }
            }
            .shadow(color: color.opacity(0.40), radius: 6, x: 0, y: 3)
            // press feedback: subtle scale + dim
            .scaleEffect(configuration.isPressed ? 0.96 : 1.00)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(duration: 0.12, bounce: 0.2), value: configuration.isPressed)
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
            HStack(spacing: 6) {
                Image(systemName: manager.isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                Text(manager.isActive ? "Выключить" : "Включить ")
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .buttonStyle(LiquidGlassButtonStyle(
            color: manager.isActive
                ? Color(red: 0.80, green: 0.18, blue: 0.18)
                : Color(red: 0.16, green: 0.46, blue: 0.92)
        ))
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
