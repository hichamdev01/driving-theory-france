import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var path = NavigationPath()
    @State private var categories: [CategoryWithName] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(settings.t(.practice))
                        .font(.display(26, .bold))
                        .foregroundColor(Theme.text)
                        .padding(.top, 12)

                    Button(action: { path.append(LearningRoute.question(mode: .practice, categoryId: nil)) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t(.randomPractice))
                                .font(.display(18, .bold))
                                .foregroundColor(.white)
                            Text(settings.t(.randomPracticeSubtitle))
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Theme.heroGradient)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: Theme.routeBlue.opacity(0.3), radius: 14, x: 0, y: 6)
                    }
                    .buttonStyle(PressableStyle())

                    LaneDivider().padding(.vertical, 2)

                    Text(settings.t(.practiceByCategory))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .textCase(.uppercase)

                    ForEach(Array(categories.enumerated()), id: \.element.id) { i, category in
                        CardView(action: { path.append(LearningRoute.question(mode: .practice, categoryId: category.id)) }) {
                            Text(category.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.text)
                        }
                        .appear(i)
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: LearningRoute.self) { route in
                switch route {
                case .question(let mode, let categoryId):
                    QuestionView(mode: mode, categoryId: categoryId, path: $path)
                case .summary(let total, let correct):
                    PracticeSummaryView(total: total, correct: correct, path: $path)
                }
            }
            .onAppear(perform: reload)
        }
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        categories = Queries.getCategoriesForCountry(Database.shared, country, language)
    }
}
