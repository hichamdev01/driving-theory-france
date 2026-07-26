import SwiftUI

struct ExamResultView: View {
    let examResultId: Int64
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var result: ExamResultRow?
    @State private var answers: [ExamResultAnswerRow] = []
    @State private var showReview = false

    var body: some View {
        ScrollView {
            if let result {
                VStack(alignment: .leading, spacing: 16) {
                    Text(settings.t(.examResults))
                        .font(.display(26, .bold))
                        .foregroundColor(Theme.text)
                        .padding(.top, 12)

                    CardView {
                        VStack(spacing: 8) {
                            Text(result.passed ? settings.t(.passed) : settings.t(.failed))
                                .font(.display(20, .heavy))
                                .foregroundColor(result.passed ? Theme.success : Theme.danger)
                            GaugeRing(value: result.score, caption: settings.t(.yourScore))
                                .padding(.vertical, 4)
                            Text("\(result.correctQuestions) / \(result.totalQuestions) \(settings.t(.questionsAnswered))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.text)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    let incorrect = answers.filter { !$0.wasCorrect }

                    if !showReview {
                        PrimaryButton(
                            label: "\(settings.t(.reviewAnswers)) (\(incorrect.count))",
                            variant: .secondary,
                            disabled: incorrect.isEmpty
                        ) {
                            showReview = true
                        }
                    } else {
                        ForEach(incorrect) { row in
                            CardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(row.question.categoryName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.primary)
                                        .textCase(.uppercase)

                                    if let imagePath = row.question.imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                                    }

                                    Text(row.question.questionText)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.text)
                                    Text("\(settings.t(.correctAnswerWas)) \(row.question.answerText(for: row.question.correctAnswer))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.success)
                                    Text(row.question.explanation)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        PrimaryButton(label: settings.t(.retakeExam)) {
                            path = NavigationPath()
                        }
                        PrimaryButton(label: settings.t(.backToHome), variant: .secondary) {
                            path = NavigationPath()
                            router.selectedTab = .home
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            guard let language = settings.languageCode else { return }
            result = Queries.getExamResultById(Database.shared, examResultId)
            answers = Queries.getExamResultAnswers(Database.shared, examResultId, language)
        }
    }
}
