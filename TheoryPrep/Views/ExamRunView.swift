import SwiftUI

struct ExamRunView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var config: ExamConfiguration?
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var answers: [Int64: Set<AnswerKey>] = [:]
    @State private var remainingSeconds = 0
    @State private var finishing = false
    @State private var finished = false
    @State private var timer: Timer?
    @State private var deadline: Date?
    @State private var showFinishConfirmation = false
    @AccessibilityFocusState private var questionFocused: Bool

    var body: some View {
        Group {
            if let config, let questions {
                if questions.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.danger)
                            .accessibilityHidden(true)
                        Text(settings.t(.noDataYet))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.text)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppScreenBackground())
                } else {
                    examBody(config: config, questions: questions)
                }
            } else {
                ZStack {
                    AppScreenBackground()
                    ProgressView().tint(Theme.primary)
                        .accessibilityLabel(settings.t(.loading))
                }
            }
        }
        .onAppear(perform: load)
        .onDisappear { timer?.invalidate() }
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func examBody(config: ExamConfiguration, questions: [QuestionWithTranslation]) -> some View {
        let question = questions[index]
        let isLast = index == questions.count - 1
        let selected = answers[question.id] ?? []

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: remainingSeconds < 60 ? "exclamationmark.triangle.fill" : "timer")
                        .font(.subheadline.weight(.semibold))
                    Text(formatTime(remainingSeconds))
                        .font(.gauge(15, .bold))
                    Text(settings.t(.timeRemaining).uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.9)
                    Spacer()
                    Text("\(index + 1) / \(questions.count)")
                        .font(.gauge(13, .bold))
                }
                .foregroundColor(remainingSeconds < 60 ? Theme.danger : Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(remainingSeconds < 60 ? Theme.danger.opacity(0.09) : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.controlRadius)
                        .stroke(remainingSeconds < 60 ? Theme.danger.opacity(0.5) : Theme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(settings.t(.timeRemaining))
                .accessibilityValue("\(formatTime(remainingSeconds)), \(index + 1) / \(questions.count)")
                .accessibilityAddTraits(.updatesFrequently)
                .id("examQuestionTop")

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.border)
                        Capsule()
                            .fill(Theme.dangerGradient)
                            .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(questions.count))
                            .animation(
                                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85),
                                value: index
                            )
                    }
                }
                .frame(height: 5)
                .accessibilityHidden(true)

                if question.imagePath != nil || question.videoPath != nil {
                    BundledQuestionMedia(imagePath: question.imagePath, videoPath: question.videoPath)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: Theme.text.opacity(0.12), radius: 14, x: 0, y: 6)
                        .padding(.horizontal, -20)
                        .accessibilityLabel(question.questionText)
                }

                Text(question.questionText)
                    .font(.display(23, .bold))
                    .foregroundColor(Theme.text)
                    .lineSpacing(2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($questionFocused)

                Text(settings.t(.selectAllAnswers))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textMuted)

                VStack(spacing: 10) {
                    ForEach(AnswerKey.allCases, id: \.self) { key in
                        let isSelected = selected.contains(key)
                        Button(action: {
                            AppFeedback.selection()
                            withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.75)) {
                                var updated = selected
                                if updated.contains(key) { updated.remove(key) } else { updated.insert(key) }
                                answers[question.id] = updated
                            }
                        }) {
                            HStack(spacing: 14) {
                                // Letter badge
                                ZStack {
                                    Circle()
                                        .fill(isSelected
                                              ? Theme.buttonGradient
                                              : LinearGradient(colors: [Theme.surfaceAlt, Theme.surfaceAlt],
                                                               startPoint: .top, endPoint: .bottom))
                                        .frame(width: 32, height: 32)
                                    Text(key.rawValue.uppercased())
                                        .font(.gauge(11.5, .bold))
                                        .foregroundColor(isSelected ? .white : Theme.textMuted)
                                }

                                Text(question.answerText(for: key))
                                    .font(.body)
                                    .foregroundColor(Theme.text)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(1.5)
                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.routeBlue)
                                        .font(.system(size: 18))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .background(isSelected ? Theme.routeBlue.opacity(0.07) : Theme.surface)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isSelected ? Theme.routeBlue : Color.clear)
                                    .frame(width: 3)
                                    .padding(.vertical, 10)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.controlRadius)
                                    .stroke(isSelected ? Theme.routeBlue.opacity(0.8) : Theme.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                            .scaleEffect(isSelected ? 1.015 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(key.rawValue.uppercased()). \(question.answerText(for: key))")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                }
                .padding(20)
                .padding(.bottom, AppSpacing.standard)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(
                    label: isLast ? settings.t(.finishButton) : settings.t(.continueButton),
                    loading: finishing,
                    icon: isLast ? "checkmark.seal" : "arrow.right"
                ) {
                    if isLast {
                        showFinishConfirmation = true
                    } else {
                        index += 1
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(BottomBarBackground())
                .overlay(alignment: .top) { Divider() }
            }
            .background(AppScreenBackground())
            .navigationBarBackButtonHidden(true)
            .onAppear { questionFocused = true }
            .onChange(of: index) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                    proxy.scrollTo("examQuestionTop", anchor: .top)
                }
                questionFocused = true
            }
            .confirmationDialog(
                settings.t(.finishExamPrompt),
                isPresented: $showFinishConfirmation,
                titleVisibility: .visible
            ) {
                Button(settings.t(.finishExamConfirm)) {
                    finishExam(config: config, questions: questions)
                }
                Button(settings.t(.cancel), role: .cancel) {}
            } message: {
                Text(settings.t(.unansweredQuestionsFormat, unansweredCount(in: questions)))
            }
        }
    }

    private func load() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        let cfg = Queries.getExamConfiguration(Database.shared, country)
        config = cfg
        let loadedQuestions = Queries.getPracticeQuestions(
            Database.shared,
            country,
            language,
            limit: cfg.numberOfQuestions
        )
        questions = loadedQuestions
        remainingSeconds = cfg.timeLimitSeconds
        guard !loadedQuestions.isEmpty else { return }
        deadline = Date().addingTimeInterval(TimeInterval(cfg.timeLimitSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let updatedSeconds = max(0, Int((deadline?.timeIntervalSinceNow ?? 0).rounded(.up)))
            remainingSeconds = updatedSeconds
            if updatedSeconds == 0 {
                timer?.invalidate()
                if let cfg = config, let qs = questions {
                    finishExam(config: cfg, questions: qs)
                }
            }
        }
    }

    private func finishExam(config: ExamConfiguration, questions: [QuestionWithTranslation]) {
        guard !finished, let country = settings.countryCode else { return }
        finished = true
        finishing = true
        timer?.invalidate()

        var correctCount = 0
        var answerInputs: [Queries.ExamAnswerInput] = []
        for question in questions {
            let selected = answers[question.id] ?? []
            let isCorrect = selected == question.correctAnswers
            if isCorrect { correctCount += 1 }
            Queries.recordAnswer(Database.shared, question.id, isCorrect)
            answerInputs.append(Queries.ExamAnswerInput(questionId: question.id, selectedAnswers: selected, correct: isCorrect))
        }

        let score = questions.isEmpty ? 0 : Int((Double(correctCount) / Double(questions.count) * 100).rounded())
        let mistakes = questions.count - correctCount
        let passed = mistakes <= config.allowedMistakes
        let examResultId = Queries.saveExamResult(
            Database.shared, countryCode: country, score: score, passed: passed,
            totalQuestions: questions.count, correctQuestions: correctCount, answers: answerInputs
        )
        path.append(ExamRoute.result(examResultId: examResultId))
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func unansweredCount(in questions: [QuestionWithTranslation]) -> Int {
        questions.reduce(into: 0) { count, question in
            if answers[question.id]?.isEmpty ?? true { count += 1 }
        }
    }
}
