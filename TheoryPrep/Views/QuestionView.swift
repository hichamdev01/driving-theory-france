import SwiftUI

struct QuestionView: View {
    let mode: QuizMode
    var categoryId: Int64? = nil
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var selected: Set<AnswerKey> = []
    @State private var submitted = false
    @State private var correctCount = 0

    var body: some View {
        Group {
            if let questions {
                if questions.isEmpty {
                    VStack(spacing: 16) {
                        Text(settings.t(.noDataYet)).foregroundColor(Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
                } else {
                    questionBody(questions[index], total: questions.count)
                }
            } else {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ProgressView().tint(Theme.routeBlue)
                }
            }
        }
        .onAppear(perform: loadQuestions)
        // A question is a focused flow. Keeping the floating tab bar visible
        // consumes the space needed by the Validate button on smaller screens.
        .preference(key: TabBarHiddenPreferenceKey.self, value: true)
    }

    @ViewBuilder
    private func questionBody(_ question: QuestionWithTranslation, total: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header: question counter + progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(settings.t(.questionOf)) \(index + 1) / \(total)")
                            .font(.gauge(11.5, .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.buttonGradient)
                            .clipShape(Capsule())

                        Spacer()

                        Text(question.categoryName)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Theme.textMuted)
                            .textCase(.uppercase)
                            .lineLimit(1)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.border)
                            Capsule()
                                .fill(Theme.buttonGradient)
                                .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(total))
                                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: index)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.top, 8)

                // Image / video
                if question.imagePath != nil || question.videoPath != nil {
                    BundledQuestionMedia(imagePath: question.imagePath, videoPath: question.videoPath)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
                        .padding(.horizontal, -20)
                }

                // Question text
                Text(question.questionText)
                    .font(.display(24, .bold))
                    .foregroundColor(Theme.text)
                    .lineSpacing(3)

                // Instruction
                Text(settings.t(.selectAllAnswers))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                    .lineSpacing(1.5)

                // Answer choices
                VStack(spacing: 10) {
                    ForEach(AnswerKey.allCases, id: \.self) { key in
                        answerRow(key, question: question)
                    }
                }

                // Feedback card
                if submitted {
                    feedbackCard(question)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }

                // Action button
                PrimaryButton(
                    label: submitted
                        ? (index == total - 1 ? settings.t(.finishButton) : settings.t(.continueButton))
                        : settings.t(.submitAnswer),
                    disabled: !submitted && selected.isEmpty
                ) {
                    submitted ? handleContinue(total: total) : handleSubmit(question)
                }
            }
            .padding(20)
            .padding(
                .bottom,
                TabBarLayout.scrollContentBottomPadding - 20
            )
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: submitted)
    }

    // MARK: – Answer row

    private func answerRow(_ key: AnswerKey, question: QuestionWithTranslation) -> some View {
        let isSelected = selected.contains(key)
        let isCorrectAnswer = question.correctAnswers.contains(key)

        // Colours
        let accentColor: Color = {
            if submitted && isCorrectAnswer { return Theme.success }
            if submitted && isSelected && !isCorrectAnswer { return Theme.danger }
            if !submitted && isSelected { return Theme.routeBlue }
            return Theme.border
        }()
        let bgColor: Color = {
            if submitted && isCorrectAnswer { return Theme.success.opacity(0.08) }
            if submitted && isSelected && !isCorrectAnswer { return Theme.danger.opacity(0.08) }
            if !submitted && isSelected { return Theme.routeBlue.opacity(0.07) }
            return Theme.surface
        }()

        return Button(action: {
            if !submitted {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
                }
            }
        }) {
            HStack(spacing: 14) {
                // Letter badge
                ZStack {
                    Circle()
                        .fill(isSelected && !submitted
                              ? Theme.buttonGradient
                              : LinearGradient(colors: [Theme.surfaceAlt, Theme.surfaceAlt],
                                               startPoint: .top, endPoint: .bottom))
                        .frame(width: 32, height: 32)

                    Text(key.rawValue.uppercased())
                        .font(.gauge(11.5, .bold))
                        .foregroundColor(isSelected && !submitted ? .white : Theme.textMuted)
                }

                Text(question.answerText(for: key))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1.5)

                Spacer()

                if submitted && isCorrectAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.success)
                        .font(.system(size: 18))
                } else if submitted && isSelected && !isCorrectAnswer {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.danger)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(bgColor)
            .overlay(alignment: .leading) {
                // Left accent bar (replaces full border — cleaner look)
                RoundedRectangle(cornerRadius: 3)
                    .fill(accentColor)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius)
                    .stroke(accentColor.opacity(submitted ? 0.5 : 0.8), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .scaleEffect(isSelected && !submitted ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .disabled(submitted)
    }

    // MARK: – Feedback card

    private func feedbackCard(_ question: QuestionWithTranslation) -> some View {
        let isCorrect = selected == question.correctAnswers
        let accentColor = isCorrect ? Theme.success : Theme.danger
        let gradient = isCorrect ? Theme.successGradient : Theme.dangerGradient

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 32, height: 32)
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(isCorrect ? settings.t(.correct) : settings.t(.incorrect))
                    .font(.display(18, .heavy))
                    .foregroundColor(accentColor)
            }

            if !isCorrect {
                Text("\(settings.t(.correctAnswerWas)) \(question.correctAnswerText)")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(Theme.text)
            }

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.explanation).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textMuted)
                Text(question.explanation)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text)
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceAlt)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }

    // MARK: – Logic

    private func loadQuestions() {
        guard questions == nil, let country = settings.countryCode, let language = settings.languageCode else { return }
        switch mode {
        case .practice:
            questions = Queries.getPracticeQuestions(Database.shared, country, language, categoryId: categoryId)
        case .mistakes:
            questions = Queries.getMistakes(Database.shared, country, language).map(\.question)
        }
    }

    private func handleSubmit(_ question: QuestionWithTranslation) {
        guard !selected.isEmpty else { return }
        let isCorrect = selected == question.correctAnswers
        if isCorrect { correctCount += 1 }
        Queries.recordAnswer(Database.shared, question.id, isCorrect)
        submitted = true
    }

    private func handleContinue(total: Int) {
        if index == total - 1 {
            path.append(LearningRoute.summary(total: total, correct: correctCount))
            return
        }
        index += 1
        selected = []
        submitted = false
    }
}
