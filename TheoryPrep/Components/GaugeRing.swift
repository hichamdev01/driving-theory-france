import SwiftUI

/// A speedometer-style ring: a fixed red-to-green dial that reveals up to the
/// current value, like a dashboard gauge rather than a generic progress bar.
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
            Circle()
                .stroke(Theme.border, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(colors: [zoneColor.opacity(0.7), zoneColor], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(value)%")
                    .font(.gauge(size * 0.24))
                    .foregroundColor(Theme.text)
                if let caption {
                    Text(caption)
                        .font(.system(size: size * 0.09, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .textCase(.uppercase)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) { _ in
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                animatedProgress = progress
            }
        }
    }
}
