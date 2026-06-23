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

// ── Liquid Glass button — colourless, clear glass (21st.dev screenshot) ────
// A translucent frosted capsule. No tint, no colour — pure glass:
//   1. ultraThinMaterial base (blurs whatever is behind it)
//   2. faint white film → the bright frosted look from the reference
//   3. top specular gloss across the upper third
//   4. dual rim bevel: bright top edge + bottom refraction, dark sides
//   5. soft floating drop shadow
private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                ZStack {
                    // 1. barely-there glass body — max transparency, just enough
                    //    to catch light. Background shows straight through.
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.10), .white.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        ))

                    // 2. top specular gloss — the glass reflection
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.30), location: 0.00),
                                .init(color: .white.opacity(0.06), location: 0.30),
                                .init(color: .white.opacity(0.00), location: 0.55),
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .blendMode(.plusLighter)

                    // 3. dual rim — draws the glass edge on any background
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.65), location: 0.00),
                                    .init(color: .white.opacity(0.10), location: 0.38),
                                    .init(color: .black.opacity(0.12), location: 0.72),
                                    .init(color: .white.opacity(0.22), location: 1.00),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                }
            }
            // 4. soft floating shadow — keeps the clear capsule readable
            .shadow(color: .black.opacity(0.22), radius: 11, x: 0, y: 6)
            .shadow(color: .black.opacity(0.12), radius: 2,  x: 0, y: 1)
            // press feedback
            .scaleEffect(configuration.isPressed ? 0.965 : 1.00)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(duration: 0.14, bounce: 0.22), value: configuration.isPressed)
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
            settings
            quitRow
        }
        .padding(16)
        .frame(width: 256)
        .animation(.easeInOut(duration: 0.25), value: manager.isActive)
    }

    // ── Title ─────────────────────────────────────────────────────────────

    private var titleRow: some View {
        HStack {
            Text("Unslept")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("v1.2")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // ── Status card — liquid glass ─────────────────────────────────────────

    private var statusCard: some View {
        VStack(spacing: 10) {
            Image(systemName: manager.isActive ? "cup.and.heat.waves.fill" : "moon.zzz.fill")
                .font(.system(size: 34))
                .frame(width: 44, height: 40)
                .foregroundStyle(manager.isActive ? .primary : .secondary)

            // plain text — not a button, no glass frame
            Text(manager.isActive ? "Mac stays awake" : "Mac can sleep")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(manager.isActive ? .primary : .secondary)

            // always in layout, opacity hides it → zero layout shift
            Text(manager.isActive ? manager.timerText : "0s")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .opacity(manager.isActive ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // ── Toggle — liquid glass button ───────────────────────────────────────

    private var toggleButton: some View {
        Button {
            manager.isActive ? manager.deactivate() : manager.activate()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: manager.isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(manager.isActive ? "Turn off" : "Turn on")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .buttonStyle(GlassButtonStyle())
    }

    // ── Settings ────────────────────────────────────────────────────────────

    private var settings: some View {
        VStack(spacing: 9) {
            Divider().opacity(0.4)

            HStack(spacing: 8) {
                Image(systemName: "power").font(.system(size: 11)).foregroundStyle(.secondary)
                Text("Launch at login").font(.system(size: 12))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { manager.launchAtLogin },
                    set: { manager.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.mini)
            }

            HStack(spacing: 8) {
                Image(systemName: "timer").font(.system(size: 11)).foregroundStyle(.secondary)
                Text("Auto-off").font(.system(size: 12))
                Spacer()
                Picker("", selection: $manager.autoOffMinutes) {
                    Text("Off").tag(0)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                    Text("4 hours").tag(240)
                    Text("8 hours").tag(480)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .fixedSize()
            }
        }
    }

    // ── Quit ──────────────────────────────────────────────────────────────

    private var quitRow: some View {
        HStack {
            Spacer()
            Button("Quit") {
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
