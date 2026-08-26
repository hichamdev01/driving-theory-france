import SwiftUI

struct ExamResultView: View {
    let examResultId: Int64
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var result: ExamResultRow?
    @State private var answers: [ExamResultAnswerRow] = []
    @State private var showReview = false
    @AccessibilityFocusState private var resultFocused: Bool

    var body: some View {
        ScrollView {
            if let result {
                VStack(alignment: .leading, spacing: 16) {
                    AppScreenHeader(eyebrow: settings.t(.exam), title: settings.t(.examResults))
                        .padding(.top, 12)
                        .accessibilityFocused($resultFocused)

                    CardView {
                        VStack(spacing: 8) {
                            Text(result.passed ? settings.t(.passed) : settings.t(.failed))
                                .font(.display(20, .heavy))
                                .foregroundColor(result.passed ? Theme.success : Theme.danger)
                            GaugeRing(value: result.score, caption: settings.t(.yourScore))
                                .padding(.vertical, 4)
                            Text("\(result.correctQuestions) / \(result.totalQuestions) \(settings.t(.questionsAnswered))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.text)
                            Text("\(result.totalQuestions - result.correctQuestions) \(settings.t(.mistakeCount))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(result.passed ? Theme.textMuted : Theme.danger)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityElement(children: .combine)

                    let incorrect = answers.filter { !$0.wasCorrect }

                    if !showReview {
                        PrimaryButton(
                            label: "\(settings.t(.reviewAnswers)) (\(incorrect.count))",
                            variant: .secondary,
                            disabled: incorrect.isEmpty
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) { showReview = true }
                            AppFeedback.selection()
                        }
                    } else {
                        ForEach(incorrect) { row in
                            CardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(row.question.categoryName)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.primary)
                                        .textCase(.uppercase)

                                    if row.question.imagePath != nil || row.question.videoPath != nil {
                                        BundledQuestionMedia(imagePath: row.question.imagePath, videoPath: row.question.videoPath)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                                            .accessibilityLabel(row.question.questionText)
                                    }

                                    Text(row.question.questionText)
                                        .font(.body.weight(.bold))
                                        .foregroundColor(Theme.text)
                                    Text("\(settings.t(.correctAnswerWas)) \(row.question.correctAnswerText(displayOrder: row.answerOrder))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.success)
                                    Text(row.question.explanation)
                                        .font(.body)
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }

                    VStack(spacing: 12) {
                        PrimaryButton(label: settings.t(.retakeExam), icon: "arrow.clockwise") {
                            path = NavigationPath()
                        }
                        PrimaryButton(label: settings.t(.backToHome), variant: .secondary, icon: "house") {
                            path = NavigationPath()
                            router.selectedTab = .today
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .background(AppScreenBackground())
        .navigationBarHidden(true)
        .onAppear {
            guard let language = settings.languageCode else { return }
            let loadedResult = Queries.getExamResultById(Database.shared, examResultId)
            result = loadedResult
            answers = Queries.getExamResultAnswers(Database.shared, examResultId, language)
            if let result = loadedResult {
                AppFeedback.result(
                    correct: result.passed,
                    announcement: result.passed ? settings.t(.passed) : settings.t(.failed)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                resultFocused = true
            }
        }
    }
}
