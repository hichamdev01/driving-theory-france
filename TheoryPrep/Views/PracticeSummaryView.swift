import SwiftUI

struct PracticeSummaryView: View {
    let total: Int
    let correct: Int
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeShown = false
    @AccessibilityFocusState private var titleFocused: Bool

    private var accuracy: Int {
        total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(accuracy >= 75 ? Theme.success : Theme.routeBlue)
                    .accessibilityHidden(true)

                Text(settings.t(.practiceComplete))
                    .font(.display(28, .bold))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)

            CardView {
                VStack(spacing: 12) {
                    GaugeRing(value: accuracy, caption: settings.t(.accuracy))
                        .scaleEffect(badgeShown ? 1 : 0.6)
                        .opacity(badgeShown ? 1 : 0)
                    Text("\(correct) / \(total) \(settings.t(.questionsAnswered))")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.text)
                }
                .frame(maxWidth: .infinity)
            }

            PrimaryButton(label: settings.t(.practiceAgain), icon: "arrow.clockwise") {
                path = NavigationPath()
            }
            PrimaryButton(label: settings.t(.backToHome), variant: .secondary, icon: "house") {
                path = NavigationPath()
                router.selectedTab = .today
            }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppScreenBackground())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.68).delay(0.1)) {
                badgeShown = true
            }
            AppFeedback.result(correct: true, announcement: settings.t(.practiceComplete))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                titleFocused = true
            }
        }
    }
}
