import SwiftUI

/// A dashed rule styled after painted lane markings — stands in for a plain
/// hairline divider between sections, used sparingly as the app's signature.
struct LaneDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.textMuted.opacity(0.4))
            .frame(height: 2)
            .overlay(
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 1))
                        path.addLine(to: CGPoint(x: geo.size.width, y: 1))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 7]))
                    .foregroundColor(Theme.background)
                }
            )
    }
}
