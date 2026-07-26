import SwiftUI

struct RoadSignBadge: View {
    let shape: String
    let color: String
    var size: CGFloat = 56

    var body: some View {
        Group {
            switch shape {
            case "triangle":
                Triangle()
                    .fill(Color(hex: color))
                    .frame(width: size, height: size)
            case "square":
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: color))
                    .frame(width: size * 0.75, height: size * 0.75)
                    .rotationEffect(.degrees(45))
                    .frame(width: size, height: size)
            case "octagon":
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: color))
                    .frame(width: size, height: size)
            default:
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: size, height: size)
            }
        }
        .overlay(
            LinearGradient(
                colors: [.white.opacity(0.35), .clear],
                startPoint: .top, endPoint: .center
            )
            .blendMode(.overlay)
        )
        .shadow(color: Color(hex: color).opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
