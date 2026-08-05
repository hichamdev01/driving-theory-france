import SwiftUI

struct PracticeSummaryView: View {
    let total: Int
    let correct: Int
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var badgeShown = false

    private var accuracy: Int {
        total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(settings.t(.practiceComplete))
                .font(.display(24, .bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)

            CardView {
                VStack(spacing: 12) {
                    GaugeRing(value: accuracy, caption: settings.t(.accuracy))
                        .scaleEffect(badgeShown ? 1 : 0.6)
                        .opacity(badgeShown ? 1 : 0)
                    Text("\(correct) / \(total) \(settings.t(.questionsAnswered))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                }
                .frame(maxWidth: .infinity)
            }

            PrimaryButton(label: settings.t(.practiceAgain)) {
                path = NavigationPath()
            }
            PrimaryButton(label: settings.t(.backToHome), variant: .secondary) {
                path = NavigationPath()
                router.selectedTab = .today
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.1)) {
                badgeShown = true
            }
        }
    }
}
