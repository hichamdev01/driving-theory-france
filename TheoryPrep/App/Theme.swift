import SwiftUI
import UIKit

// MARK: - Quiet Wayfinding design system

/// Semantic roles used by migrated screens. Keeping these separate from the
/// legacy `Theme` palette lets us migrate without restyling unfinished flows.
enum AppColor {
    static let background = Theme.background
    static let surface = Theme.surface
    static let surfaceRaised = Theme.surfaceAlt
    static let text = Theme.text
    static let textSecondary = Theme.textMuted
    static let textTertiary = Color(light: "738197", dark: "8493A8")
    static let separator = Theme.border
    static let fillSubtle = Theme.routeBlue.opacity(0.09)
    static let action = Theme.routeBlue
    static let success = Theme.success
    static let danger = Theme.danger
    static let warning = Theme.accent
}

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standard: CGFloat = 16
    static let section: CGFloat = 24
    static let large: CGFloat = 32
    static let xLarge: CGFloat = 48
}

enum AppRadius {
    static let control: CGFloat = 12
    static let card: CGFloat = 16
}

/// A structural route marker for meaningful learning steps.
struct LearningRouteMark: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(AppColor.action)
                .frame(width: 12, height: 12)
            Rectangle()
                .fill(AppColor.action.opacity(0.28))
                .frame(width: 2, height: 36)
            Circle()
                .stroke(AppColor.action.opacity(0.55), lineWidth: 2)
                .frame(width: 12, height: 12)
        }
        .accessibilityHidden(true)
    }
}

enum Theme {
    // The palette comes from French road furniture: route signs, regulatory
    // rings, painted lane markings, and the warm stock used in road atlases.
    static let background = Color(light: "F3F5F8", dark: "080D16")
    static let surface = Color(light: "FFFFFF", dark: "131A26")
    static let surfaceAlt = Color(light: "E9EEF5", dark: "1B2436")
    static let routeBlue = Color(light: "1654A3", dark: "5B8EDB")
    static let routeBlueDeep = Color(light: "10294D", dark: "10294D")
    static let signalCyan = Color(light: "6BA4C8", dark: "79B7DC")
    static let accent = Color(light: "F2C84B", dark: "F6D66E")
    static let success = Color(light: "13805B", dark: "3EC992")
    static let danger = Color(light: "D5273D", dark: "FF5F70")
    static let text = Color(light: "0F1923", dark: "EDF1F6")
    static let textMuted = Color(light: "54657A", dark: "9AABC0")
    static let border = Color(light: "CED8E5", dark: "2A374B")
    static let laneWhite = Color(light: "FFFFFF", dark: "EEF3F7")

    /// Alias kept for call sites written before the palette rename.
    static let primary = routeBlue
    static let primaryDark = routeBlueDeep

    /// Real gradients — two-stop so buttons and hero cards have genuine depth.
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "2A70DA"), Color(hex: "164EA9")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "091A3A"), Color(hex: "163A78")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let screenGradient = LinearGradient(
        colors: [
            Color(light: "F8FAFC", dark: "0B111D"),
            background,
            Color(light: "EEF2F7", dark: "080D16")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.78),
                value: configuration.isPressed
            )
    }
}

/// Staggered fade + rise-in, applied to list rows so screens feel like they arrive rather than just appear.
struct AppearAnimation: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .onAppear {
                if reduceMotion {
                    shown = true
                    return
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.045)) {
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

/// The shared page background keeps every flow in the same visual world while
/// preserving strong contrast in both appearances.
struct AppScreenBackground: View {
    var body: some View {
        Theme.screenGradient
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// A bottom action-bar backing that respects Reduce Transparency: a solid
/// surface fill instead of a translucent material when the setting is on.
struct BottomBarBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Theme.surface
        } else {
            // `.regular` (not `.ultraThin`) so scrolled-past text never reads
            // through under the primary action button, at any text size.
            Rectangle().fill(.regularMaterial)
        }
    }
}

extension View {
    /// A hairline stroke that thickens under Increase Contrast so edges stay
    /// legible without depending on a subtle color difference alone.
    func adaptiveStroke(_ color: Color, radius: CGFloat, baseWidth: CGFloat = 1) -> some View {
        modifier(AdaptiveStrokeModifier(color: color, radius: radius, baseWidth: baseWidth))
    }
}

private struct AdaptiveStrokeModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    let color: Color
    let radius: CGFloat
    let baseWidth: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(color, lineWidth: contrast == .increased ? baseWidth * 1.75 : baseWidth)
        )
    }
}

/// A restrained route-map texture. It is deliberately reserved for hero
/// moments so the visual identity stays memorable instead of becoming noise.
struct RouteRibbon: View {
    var opacity: Double = 1

    var body: some View {
        Canvas { context, size in
            var route = Path()
            route.move(to: CGPoint(x: size.width * 0.88, y: -12))
            route.addCurve(
                to: CGPoint(x: size.width * 0.54, y: size.height + 18),
                control1: CGPoint(x: size.width * 0.52, y: size.height * 0.22),
                control2: CGPoint(x: size.width * 0.92, y: size.height * 0.72)
            )

            context.stroke(
                route,
                with: .color(.white.opacity(0.07)),
                style: StrokeStyle(lineWidth: 54, lineCap: .round)
            )
            context.stroke(
                route,
                with: .color(.white.opacity(0.20)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 13])
            )
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct AppScreenHeader: View {
    let eyebrow: String
    let title: String
    var accent: Color = Theme.routeBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(accent)
            Text(title)
                .font(.display(34, .bold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct AppSectionHeader: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.gauge(12, .bold))
                    .foregroundStyle(Theme.routeBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.routeBlue.opacity(0.10), in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

enum AppFeedback {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func result(correct: Bool, announcement: String) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(correct ? .success : .error)
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
