import SwiftUI

struct SplashView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeScale: CGFloat = 0.55
    @State private var badgeOpacity: Double = 0
    @State private var flagRevealed = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 10
    @State private var lineProgress: CGFloat = 0
    @State private var glow = false

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            // A dashed centerline receding toward the horizon, echoing the
            // app's road-marking motif (see LaneDivider) as ambient motion.
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.45))
                    path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                }
                .trim(from: 0, to: lineProgress)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [16, 18]))
                .foregroundColor(.white.opacity(0.22))
            }
            .ignoresSafeArea()

            RadialGradient(
                colors: [.white.opacity(glow ? 0.16 : 0.05), .clear],
                center: .center, startRadius: 10, endRadius: 220
            )
            .frame(width: 440, height: 440)

            VStack(spacing: 24) {
                // The tricolor rendered as a small emblem/crest rather than a
                // literal flag graphic — reads as "official credential", which
                // fits a driving-theory certification app.
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white.opacity(0.12))
                        .frame(width: 116, height: 116)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(.white.opacity(0.35), lineWidth: 1.5)
                        )

                    HStack(spacing: 0) {
                        flagBar(Color(hex: "0055A4"), delay: 0.05)
                        flagBar(.white, delay: 0.16)
                        flagBar(Color(hex: "EF4135"), delay: 0.27)
                    }
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                }
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)
                .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(settings.t(.appName))
                        .font(.display(32, .bold))
                        .foregroundColor(.white)
                    Text(settings.t(.splashSubtitle))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.70)) {
                badgeScale = 1
                badgeOpacity = 1
            }
            flagRevealed = true
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) {
                lineProgress = 1
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.42).delay(0.22)) {
                titleOpacity = 1
                titleOffset = 0
            }
            guard !reduceMotion else {
                glow = true
                return
            }
            withAnimation(.easeInOut(duration: 1.6).delay(0.45).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private func flagBar(_ color: Color, delay: Double) -> some View {
        Rectangle()
            .fill(color)
            .scaleEffect(y: flagRevealed ? 1 : 0, anchor: .bottom)
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.72).delay(delay), value: flagRevealed)
    }
}
