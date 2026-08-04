import SwiftUI

/// A speedometer-style ring: a fixed dial that reveals up to the current value,
/// like a dashboard gauge. The arc colour transitions red → amber → green.
struct GaugeRing: View {
    let value: Int
    var size: CGFloat = 132
    var lineWidth: CGFloat = 14
    var caption: String? = nil

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat { CGFloat(max(0, min(100, value))) / 100 }
    private var zoneColor: Color { Theme.gaugeColor(value) }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Theme.border, lineWidth: lineWidth)

            // Filled arc — gradient from the zone colour to a lighter tint
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [zoneColor.opacity(0.55), zoneColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * Double(animatedProgress))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Inner glow dot at the arc tip
            Circle()
                .fill(zoneColor)
                .frame(width: lineWidth * 0.6, height: lineWidth * 0.6)
                .shadow(color: zoneColor.opacity(0.7), radius: 4)
                .offset(y: -(size / 2))
                .rotationEffect(.degrees(-90 + 360 * Double(animatedProgress)))
                .opacity(animatedProgress > 0.03 ? 1 : 0)

            // Centre text
            VStack(spacing: 2) {
                Text("\(value)%")
                    .font(.gauge(size * 0.24, .bold))
                    .foregroundColor(Theme.text)
                if let caption {
                    Text(caption)
                        .font(.system(size: size * 0.09, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.82).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.82)) {
                animatedProgress = progress
            }
        }
    }
}
