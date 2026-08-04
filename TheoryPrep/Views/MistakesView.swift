import SwiftUI

struct MistakesView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var path = NavigationPath()
    @State private var mistakes: [MistakeRow] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.t(.appName).uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.danger)
                        Text(settings.t(.mistakes))
                            .font(.display(34, .bold))
                            .foregroundColor(Theme.text)
                    }
                    .padding(.top, 12)

                    if mistakes.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settings.t(.noMistakesTitle))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.text)
                                Text(settings.t(.noMistakesSubtitle))
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                    } else {
                        PrimaryButton(label: settings.t(.practiceMistakes)) {
                            path.append(LearningRoute.question(mode: .mistakes, categoryId: nil))
                        }
                        ForEach(Array(mistakes.enumerated()), id: \.element.id) { i, mistake in
                            CardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mistake.question.categoryName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.routeBlue)
                                        .textCase(.uppercase)

                                    if let imagePath = mistake.question.imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                                    }

                                    Text(mistake.question.questionText)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.text)
                                    Text(settings.t(.incorrectTimes, count: mistake.incorrectCount))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.danger)
                                }
                            }
                            .appear(i)
                        }
                    }
                }
                .padding(20)
                .padding(
                    .bottom,
                    TabBarLayout.scrollContentBottomPadding - 20
                )
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
        mistakes = Queries.getMistakes(Database.shared, country, language)
    }
}
