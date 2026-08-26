import SwiftUI

struct MistakesView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var path = NavigationPath()
    @State private var mistakes: [MistakeRow] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppScreenHeader(
                        eyebrow: settings.t(.appName),
                        title: settings.t(.mistakes),
                        accent: Theme.danger
                    )
                    .padding(.top, 12)

                    if mistakes.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(Theme.success)
                                    .accessibilityHidden(true)
                                Text(settings.t(.noMistakesTitle))
                                    .font(.headline)
                                    .foregroundColor(Theme.text)
                                Text(settings.t(.noMistakesSubtitle))
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textMuted)
                                PrimaryButton(
                                    label: settings.t(.randomPractice),
                                    variant: .secondary,
                                    icon: "shuffle"
                                ) {
                                    path.append(LearningRoute.question(mode: .practice, categoryId: nil))
                                }
                            }
                        }
                    } else {
                        PrimaryButton(label: settings.t(.practiceMistakes)) {
                            path.append(LearningRoute.question(mode: .mistakes, categoryId: nil))
                        }

                        if confidentlyWrongCount > 0 { confidentlyWrongCard }
                        ForEach(Array(mistakes.enumerated()), id: \.element.id) { i, mistake in
                            CardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mistake.question.categoryName)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.routeBlue)
                                        .textCase(.uppercase)

                                    if let imagePath = mistake.question.imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                                            .accessibilityLabel(mistake.question.questionText)
                                    }

                                    Text(mistake.question.questionText)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(Theme.text)
                                    Text(settings.t(.incorrectTimes, count: mistake.incorrectCount))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.danger)

                                    if mistake.wasConfidentlyWrong {
                                        HStack(spacing: 5) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption2.weight(.bold))
                                                .accessibilityHidden(true)
                                            Text(settings.t(.confidentBadge))
                                                .font(.caption.weight(.semibold))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .foregroundColor(Theme.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.accent.opacity(0.12), in: Capsule())
                                    }
                                }
                            }
                            .appear(i)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, AppSpacing.section)
            }
            .background(AppScreenBackground())
            .navigationBarHidden(true)
            .navigationDestination(for: LearningRoute.self) { route in
                switch route {
                case .question(let mode, let categoryId):
                    QuestionView(mode: mode, categoryId: categoryId, path: $path)
                case .summary(let total, let correct):
                    PracticeSummaryView(total: total, correct: correct, path: $path)
                case .roadSigns:
                    RoadSignsView()
                }
            }
            .onAppear(perform: reload)
        }
    }

    /// Mistakes made while the learner believed they knew the answer. These are
    /// listed first by the query, because nothing else prompts the learner to
    /// revise them — they do not feel like gaps.
    private var confidentlyWrongCount: Int {
        mistakes.filter(\.wasConfidentlyWrong).count
    }

    private var confidentlyWrongCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(settings.t(.confidentlyWrongTitle, confidentlyWrongCount))
                        .font(.headline)
                        .foregroundColor(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(settings.t(.confidentlyWrongBody))
                    .font(.subheadline)
                    .foregroundColor(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        mistakes = Queries.getMistakes(Database.shared, country, language)
    }
}
