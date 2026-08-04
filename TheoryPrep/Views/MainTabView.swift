import SwiftUI

enum TabBarLayout {
    // The custom bar is taller than a standard tab bar because its exam
    // button is raised. Scroll content needs this much trailing space so its
    // final control can move completely above the bar.
    static let scrollContentBottomPadding: CGFloat = 120
}

struct MainTabView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var router = TabRouter()
    @State private var hidesTabBar = false

    var body: some View {
        activeScreen
            .onPreferenceChange(TabBarHiddenPreferenceKey.self) { hidesTabBar = $0 }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !hidesTabBar {
                    RouteTabBar(selection: $router.selectedTab)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .environmentObject(router)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hidesTabBar)
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch router.selectedTab {
        case .home:
            NavigationStack { HomeView() }
        case .practice:
            PracticeView()
        case .exam:
            ExamFlowView()
        case .roadSigns:
            RoadSignsView()
        case .mistakes:
            MistakesView()
        case .progress:
            NavigationStack { ProgressScreen() }
        }
    }
}

struct TabBarHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct RouteTabBar: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var selection: MainTab

    // The raised exam button's geometry is expressed with explicit frame
    // sizes rather than a negative .offset() past a smaller parent frame —
    // offsetting outside a frame's bounds can get clipped by an enclosing
    // safeAreaInset container, which is what was hiding the button. Instead
    // the whole bar reserves real layout space for both the pill and the
    // button, so nothing ever renders outside its own container.
    private let pillHeight: CGFloat = 64
    private let pillTopInset: CGFloat = 36  // distance from bar top to pill top
    private var totalHeight: CGFloat { pillTopInset + pillHeight }

    var body: some View {
        ZStack(alignment: .top) {
            // Frosted-glass pill, pushed down from the top of the bar
            VStack(spacing: 0) {
                Spacer().frame(height: pillTopInset)

                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)

                    // Four tabs, with a clear slot in the middle for the exam button
                    HStack(spacing: 0) {
                        tabItem(.home,      icon: "house",          key: .home)
                        tabItem(.practice,  icon: "graduationcap",  key: .practice)
                        Color.clear.frame(maxWidth: .infinity)   // exam slot
                        tabItem(.roadSigns, icon: "signpost.right", key: .roadSigns)
                        tabItem(.progress,  icon: "chart.bar",      key: .progress)
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: pillHeight)
            }

            // Exam button — pinned to the very top of the bar, fully within
            // its own bounds so it can never be clipped by an ancestor.
            HStack {
                Spacer(minLength: 0)
                examButton
                Spacer(minLength: 0)
            }
        }
        .frame(height: totalHeight)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: – Regular tab item

    private func tabItem(_ tab: MainTab, icon: String, key: StringKey) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.routeBlue : Theme.textMuted)
                    .frame(height: 24)

                // Active indicator dot
                Circle()
                    .fill(Theme.routeBlue)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
                    .scaleEffect(isSelected ? 1 : 0.1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(settings.t(key))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: – Centre exam button

    private var examButton: some View {
        let isSelected = selection == .exam
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selection = .exam
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "1654A3").opacity(0.45), radius: 14, x: 0, y: 6)

                    // Inner highlight arc
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 56, height: 56)

                    // Speed-limit ring
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Text("40")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(settings.t(.exam))
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.routeBlue : Theme.textMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(settings.t(.exam))
    }
}
