import SwiftUI
import UIKit

enum Theme {
    // The palette comes from French road furniture: route signs, regulatory
    // rings, painted lane markings, and the warm stock used in road atlases.
    static let background = Color(light: "EFF1F5", dark: "090D15")
    static let surface = Color(light: "FFFFFF", dark: "131A26")
    static let surfaceAlt = Color(light: "E8ECF2", dark: "1B2436")
    static let routeBlue = Color(light: "1654A3", dark: "5B8EDB")
    static let routeBlueDeep = Color(light: "10294D", dark: "10294D")
    static let signalCyan = Color(light: "6BA4C8", dark: "79B7DC")
    static let accent = Color(light: "F2C84B", dark: "F6D66E")
    static let success = Color(light: "13805B", dark: "3EC992")
    static let danger = Color(light: "D5273D", dark: "FF5F70")
    static let text = Color(light: "0F1923", dark: "EDF1F6")
    static let textMuted = Color(light: "5E6E82", dark: "8899AE")
    static let border = Color(light: "D4DCE6", dark: "222E40")
    static let laneWhite = Color(light: "FFFFFF", dark: "EEF3F7")

    /// Alias kept for call sites written before the palette rename.
    static let primary = routeBlue
    static let primaryDark = routeBlueDeep

    /// Real gradients — two-stop so buttons and hero cards have genuine depth.
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "2B72E3"), Color(hex: "0F44C4")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "0B1B3E"), Color(hex: "163378")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dangerGradient = LinearGradient(
        colors: [Color(hex: "E63A50"), Color(hex: "B51D30")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [Color(hex: "1CA876"), Color(hex: "0E7050")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "F9D55C"), Color(hex: "E0A820")],
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

    /// Matching gradient for the gauge zone color.
    static func gaugeGradient(_ value: Int) -> LinearGradient {
        if value >= 75 { return successGradient }
        if value >= 50 { return accentGradient }
        return dangerGradient
    }
}

extension Font {
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let name: String
        switch weight {
        case .black, .heavy, .bold, .semibold:
            name = "AvenirNextCondensed-DemiBold"
        default:
            name = "AvenirNextCondensed-Medium"
        }
        return .custom(name, size: size, relativeTo: .title2)
    }
    static func gauge(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
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
