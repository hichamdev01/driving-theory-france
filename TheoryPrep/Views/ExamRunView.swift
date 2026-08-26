import SwiftUI

struct ExamRunView: View {
    @Binding var path: NavigationPath
    /// When false the optional practice countdown is disabled. The public ETG
    /// specification does not establish a universal per-question duration, so
    /// this timer is deliberately presented as a training setting.
    var timed: Bool = true

    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var config: ExamConfiguration?
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var answers: [Int64: Set<AnswerKey>] = [:]
    @State private var answerOrders: [Int64: [AnswerKey]] = [:]
    @State private var remainingSeconds = 0
    @State private var finishing = false
    @State private var finished = false
    @State private var timer: Timer?
    @State private var deadline: Date?
    @State private var showFinishConfirmation = false
    @State private var showExitConfirmation = false
    @AccessibilityFocusState private var questionFocused: Bool

    /// Warn only in the final third of the question's time, so the exam reads
    /// as focused rather than panicked.
    private var isRunningOut: Bool {
        guard timed, let config else { return false }
        return remainingSeconds <= max(3, config.practiceSecondsPerQuestion / 3)
    }

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
        let answerOrder = answerOrders[question.id] ?? AnswerPresentation.canonicalOrder

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                exitButton

                HStack(spacing: 10) {
                    if timed {
                        Image(systemName: isRunningOut ? "exclamationmark.triangle.fill" : "timer")
                            .font(.subheadline.weight(.semibold))
                        Text("\(remainingSeconds) s")
                            .font(.gauge(15, .bold))
                            .monospacedDigit()
                        Text(settings.t(.perQuestion).uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.9)
                    } else {
                        Image(systemName: "infinity")
                            .font(.subheadline.weight(.semibold))
                        Text(settings.t(.examUntimedBadge).uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.9)
                    }
                    Spacer()
                    Text("\(index + 1) / \(questions.count)")
                        .font(.gauge(13, .bold))
                }
                .foregroundColor(isRunningOut ? Theme.danger : Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(isRunningOut ? Theme.danger.opacity(0.09) : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.controlRadius)
                        .stroke(isRunningOut ? Theme.danger.opacity(0.5) : Theme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(timed ? settings.t(.timeRemaining) : settings.t(.examUntimedBadge))
                .accessibilityValue(
                    timed
                        ? "\(remainingSeconds) s, \(index + 1) / \(questions.count)"
                        : "\(index + 1) / \(questions.count)"
                )
                .accessibilityAddTraits(.updatesFrequently)
                }
                .padding(.top, 8)
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

                Text(settings.t(question.correctAnswers.count > 1 ? .selectAllAnswers : .selectOneAnswer))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textMuted)

                VStack(spacing: 10) {
                    ForEach(answerOrder.indices, id: \.self) { answerIndex in
                        let key = answerOrder[answerIndex]
                        let displayKey = AnswerPresentation.canonicalOrder[answerIndex]
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
                                    Text(displayKey.rawValue.uppercased())
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
                        .accessibilityLabel("\(displayKey.rawValue.uppercased()). \(question.answerText(for: key))")
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
                startQuestionTimer(config)
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

    /// Leaves the exam without recording anything.
    ///
    /// The alternative — saving a part-finished attempt — would put a failing
    /// score and a pile of never-answered questions into the mistake list,
    /// which would misrepresent what the learner actually got wrong.
    private var exitButton: some View {
        Button {
            showExitConfirmation = true
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(settings.t(.exitExamLabel))
        .accessibilityHint(settings.t(.exitExamMessage))
        .confirmationDialog(
            settings.t(.exitExamTitle),
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t(.exitExamConfirm), role: .destructive) { exitExam() }
            Button(settings.t(.cancel), role: .cancel) {}
        } message: {
            Text(settings.t(.exitExamMessage))
        }
    }

    private func exitExam() {
        // Mark finished first so an in-flight timer tick cannot save a result
        // on the way out.
        finished = true
        timer?.invalidate()
        if !path.isEmpty { path.removeLast() }
    }

    private func load() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        let cfg = Queries.getExamConfiguration(Database.shared, country)
        config = cfg
        let loadedQuestions = Queries.getExamQuestions(Database.shared, country, language)
        questions = loadedQuestions
        answerOrders = Dictionary(uniqueKeysWithValues: loadedQuestions.map {
            ($0.id, AnswerPresentation.shuffledOrder())
        })
        guard !loadedQuestions.isEmpty else { return }
        startQuestionTimer(cfg)
    }

    /// Starts the optional practice countdown for the current question.
    private func startQuestionTimer(_ cfg: ExamConfiguration) {
        timer?.invalidate()
        guard timed else { return }
        remainingSeconds = cfg.practiceSecondsPerQuestion
        deadline = Date().addingTimeInterval(TimeInterval(cfg.practiceSecondsPerQuestion))
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let left = max(0, Int((deadline?.timeIntervalSinceNow ?? 0).rounded(.up)))
            if left != remainingSeconds { remainingSeconds = left }
            if left == 0 { advanceOnTimeout() }
        }
    }

    /// Time ran out: lock the current selection and move to the next practice
    /// item without making a claim about a provider's official slide timing.
    private func advanceOnTimeout() {
        timer?.invalidate()
        guard let cfg = config, let qs = questions, !finished else { return }
        if index == qs.count - 1 {
            finishExam(config: cfg, questions: qs)
        } else {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { index += 1 }
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
            answerInputs.append(Queries.ExamAnswerInput(
                questionId: question.id,
                selectedAnswers: selected,
                answerOrder: answerOrders[question.id] ?? AnswerPresentation.canonicalOrder,
                correct: isCorrect
            ))
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

    private func unansweredCount(in questions: [QuestionWithTranslation]) -> Int {
        questions.reduce(into: 0) { count, question in
            if answers[question.id]?.isEmpty ?? true { count += 1 }
        }
    }
}
