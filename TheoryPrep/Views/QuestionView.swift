import SwiftUI

struct QuestionView: View {
    private let sessionLength = 10
    let mode: QuizMode
    var categoryId: Int64? = nil
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var selected: Set<AnswerKey> = []
    @State private var answerOrders: [Int64: [AnswerKey]] = [:]
    @State private var submitted = false
    @State private var correctCount = 0
    @AccessibilityFocusState private var questionFocused: Bool
    @AccessibilityFocusState private var feedbackFocused: Bool

    var body: some View {
        Group {
            if let questions {
                if questions.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "road.lanes")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.routeBlue)
                            .accessibilityHidden(true)
                        Text(settings.t(.noDataYet))
                            .font(.headline)
                            .foregroundColor(Theme.text)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppScreenBackground())
                } else {
                    questionBody(questions[index], total: questions.count)
                }
            } else {
                ZStack {
                    AppScreenBackground()
                    ProgressView().tint(Theme.routeBlue)
                        .accessibilityLabel(settings.t(.loading))
                }
            }
        }
        .onAppear(perform: loadQuestions)
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func questionBody(_ question: QuestionWithTranslation, total: Int) -> some View {
        let answerOrder = answerOrders[question.id] ?? AnswerPresentation.canonicalOrder
        ScrollViewReader { proxy in
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
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundColor(Theme.textMuted)
                            .textCase(.uppercase)
                            .multilineTextAlignment(.trailing)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.border)
                            Capsule()
                                .fill(Theme.buttonGradient)
                                .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(total))
                                .animation(
                                    reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85),
                                    value: index
                                )
                        }
                    }
                    .frame(height: 5)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(settings.t(.questionOf))
                    .accessibilityValue("\(index + 1) / \(total)")
                }
                .padding(.top, 8)
                .id("questionTop")

                // Image / video
                if question.imagePath != nil || question.videoPath != nil {
                    BundledQuestionMedia(imagePath: question.imagePath, videoPath: question.videoPath)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
                        .padding(.horizontal, -20)
                        .accessibilityLabel(question.questionText)
                }

                if !question.hasExamMedia {
                    Label(settings.t(.knowledgeDrill), systemImage: "book.closed")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.routeBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.routeBlue.opacity(0.09))
                        .clipShape(Capsule())
                }

                // Question text
                Text(question.questionText)
                    .font(.display(24, .bold))
                    .foregroundColor(Theme.text)
                    .lineSpacing(3)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($questionFocused)

                // Instruction
                Text(settings.t(question.correctAnswers.count > 1 ? .selectAllAnswers : .selectOneAnswer))
                    .font(.subheadline)
                    .foregroundColor(Theme.textMuted)
                    .lineSpacing(1.5)

                // Answer choices
                VStack(spacing: 10) {
                    ForEach(answerOrder.indices, id: \.self) { index in
                        answerRow(
                            answerOrder[index],
                            displayKey: AnswerPresentation.canonicalOrder[index],
                            question: question
                        )
                    }
                }

                // Feedback card
                if submitted {
                        feedbackCard(question, answerOrder: answerOrder)
                        .id("feedbackCard")
                        .accessibilityFocused($feedbackFocused)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }

                }
                .padding(20)
                .padding(.bottom, AppSpacing.standard)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Group {
                    if submitted {
                        PrimaryButton(
                            label: index == total - 1 ? settings.t(.finishButton) : settings.t(.continueButton),
                            icon: "arrow.right"
                        ) {
                            handleContinue(total: total)
                        }
                    } else {
                        confidenceSubmitBar(question)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(BottomBarBackground())
                .overlay(alignment: .top) { Divider() }
            }
            .background(AppScreenBackground())
            .navigationBarTitleDisplayMode(.inline)
            .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.85), value: submitted)
            .onAppear { questionFocused = true }
            .onChange(of: index) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                    proxy.scrollTo("questionTop", anchor: .top)
                }
                questionFocused = true
            }
            .onChange(of: submitted) { _, isSubmitted in
                guard isSubmitted else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                    proxy.scrollTo("feedbackCard", anchor: .top)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    feedbackFocused = true
                }
            }
        }
    }

    // MARK: – Answer row

    private func answerRow(
        _ key: AnswerKey, displayKey: AnswerKey, question: QuestionWithTranslation
    ) -> some View {
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
                AppFeedback.selection()
                withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.75)) {
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

                    Text(displayKey.rawValue.uppercased())
                        .font(.gauge(11.5, .bold))
                        .foregroundColor(isSelected && !submitted ? .white : Theme.textMuted)
                }

                Text(question.answerText(for: key))
                    .font(.body)
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
                } else if !submitted && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.routeBlue)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayKey.rawValue.uppercased()). \(question.answerText(for: key))")
        .accessibilityValue(submitted && isCorrectAnswer ? settings.t(.correct) : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: – Feedback card

    private func feedbackCard(
        _ question: QuestionWithTranslation, answerOrder: [AnswerKey]
    ) -> some View {
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
                    .font(.headline)
                    .foregroundColor(accentColor)
            }

            if !isCorrect {
                Text("\(settings.t(.correctAnswerWas)) \(question.correctAnswerText(displayOrder: answerOrder))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
            }

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.explanation).uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundColor(Theme.textMuted)
                Text(question.explanation)
                    .font(.body)
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
        .accessibilityElement(children: .combine)
    }

    // MARK: – Logic

    private func loadQuestions() {
        guard questions == nil, let country = settings.countryCode, let language = settings.languageCode else { return }
        let loaded: [QuestionWithTranslation]
        switch mode {
        case .practice:
            loaded = Queries.getPracticeQuestions(
                Database.shared,
                country,
                language,
                categoryId: categoryId,
                // Random practice covers the complete bank. Category and
                // mistake sessions stay intentionally shorter.
                limit: categoryId == nil ? nil : sessionLength
            )
        case .mistakes:
            loaded = Array(
                Queries.getMistakes(Database.shared, country, language)
                    .prefix(sessionLength)
                    .map(\.question)
            )
        }
        questions = loaded
        answerOrders = Dictionary(uniqueKeysWithValues: loaded.map {
            ($0.id, AnswerPresentation.shuffledOrder())
        })
    }

    /// Submitting *is* the confidence answer, so tagging costs no extra tap and
    /// is captured every time rather than only when the learner opts in.
    @ViewBuilder
    private func confidenceSubmitBar(_ question: QuestionWithTranslation) -> some View {
        let disabled = selected.isEmpty

        VStack(spacing: 8) {
            Text(settings.t(.confidencePrompt))
                .font(.caption)
                .foregroundColor(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            // Equal visual weight on both options: making one the obvious
            // default would bias the very signal being collected.
            let buttons = Group {
                PrimaryButton(
                    label: settings.t(.confidenceSure),
                    variant: .primary,
                    disabled: disabled,
                    icon: "checkmark"
                ) {
                    handleSubmit(question, confidence: .sure)
                }
                .accessibilityHint(settings.t(.confidenceSureHint))

                PrimaryButton(
                    label: settings.t(.confidenceUnsure),
                    variant: .secondary,
                    disabled: disabled,
                    icon: "questionmark"
                ) {
                    handleSubmit(question, confidence: .unsure)
                }
                .accessibilityHint(settings.t(.confidenceUnsureHint))
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { buttons }
            } else {
                HStack(spacing: 10) { buttons }
            }
        }
    }

    private func handleSubmit(_ question: QuestionWithTranslation, confidence: Confidence) {
        guard !selected.isEmpty else { return }
        let isCorrect = selected == question.correctAnswers
        if isCorrect { correctCount += 1 }
        Queries.recordAnswer(Database.shared, question.id, isCorrect, confidence: confidence)
        submitted = true
        AppFeedback.result(
            correct: isCorrect,
            announcement: isCorrect ? settings.t(.correct) : settings.t(.incorrect)
        )
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
