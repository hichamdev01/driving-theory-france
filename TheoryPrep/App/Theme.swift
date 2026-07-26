import SwiftUI
import UIKit

enum Theme {
    static let background = Color(light: "F3F6FC", dark: "0B1220")
    static let surface = Color(light: "FFFFFF", dark: "131B2E")
    static let surfaceAlt = Color(light: "EAF0FA", dark: "182238")
    static let routeBlue = Color(light: "1D4FA6", dark: "3B72D6")
    static let routeBlueDeep = Color(light: "0F2E66", dark: "0B2450")
    static let signalCyan = Color(light: "17B8C4", dark: "2FD0DC")
    static let accent = Color(light: "F5A623", dark: "FFC24B")
    static let success = Color(light: "16A34A", dark: "34D399")
    static let danger = Color(light: "E0263D", dark: "FF5468")
    static let text = Color(light: "10182B", dark: "F1F5FC")
    static let textMuted = Color(light: "5B6478", dark: "8D97B0")
    static let border = Color(light: "E3E8F2", dark: "253147")

    /// Alias kept for call sites written before the palette rename.
    static let primary = routeBlue
    static let primaryDark = routeBlueDeep

    static let buttonGradient = LinearGradient(
        colors: [routeBlue, signalCyan],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [routeBlueDeep, routeBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 16

    /// Dashboard-style zone color for a 0–100 gauge value: red below 50, amber below 75, green above.
    static func gaugeColor(_ value: Int) -> Color {
        if value >= 75 { return success }
        if value >= 50 { return accent }
        return danger
    }
}

extension Font {
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func gauge(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexValue = hexValue.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Adaptive color: picks the right hex for the active light/dark trait.
    init(light: String, dark: String) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

/// A press-in scale + fade, used by buttons and tappable cards for tactile feedback.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Staggered fade + rise-in, applied to list rows so screens feel like they arrive rather than just appear.
struct AppearAnimation: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                    shown = true
                }
            }
    }
}

extension View {
    func appear(_ index: Int = 0) -> some View {
        modifier(AppearAnimation(index: index))
    }
}
