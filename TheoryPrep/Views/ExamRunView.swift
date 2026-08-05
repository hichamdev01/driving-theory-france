import SwiftUI

struct ExamRunView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var settings: AppSettings

    @State private var config: ExamConfiguration?
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var answers: [Int64: Set<AnswerKey>] = [:]
    @State private var remainingSeconds = 0
    @State private var finishing = false
    @State private var finished = false
    @State private var timer: Timer?
    @State private var deadline: Date?

    var body: some View {
        Group {
            if let config, let questions {
                examBody(config: config, questions: questions)
            } else {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ProgressView().tint(Theme.primary)
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

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: remainingSeconds < 60 ? "exclamationmark.triangle.fill" : "timer")
                        .font(.system(size: 14, weight: .semibold))
                    Text(formatTime(remainingSeconds))
                        .font(.gauge(15, .bold))
                    Text(settings.t(.timeRemaining).uppercased())
                        .font(.system(size: 9, weight: .bold))
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

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.border)
                        Capsule()
                            .fill(Theme.dangerGradient)
                            .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(questions.count))
                            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: index)
                    }
                }
                .frame(height: 5)

                if question.imagePath != nil || question.videoPath != nil {
                    BundledQuestionMedia(imagePath: question.imagePath, videoPath: question.videoPath)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: Theme.text.opacity(0.12), radius: 14, x: 0, y: 6)
                        .padding(.horizontal, -20)
                }

                Text(question.questionText)
                    .font(.display(23, .bold))
                    .foregroundColor(Theme.text)
                    .lineSpacing(2)

                Text(settings.t(.selectAllAnswers))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textMuted)

                VStack(spacing: 10) {
                    ForEach(AnswerKey.allCases, id: \.self) { key in
                        let isSelected = selected.contains(key)
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
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
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.text)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(1.5)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
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
                    }
                }

                PrimaryButton(label: isLast ? settings.t(.finishButton) : settings.t(.continueButton), loading: finishing) {
                    if isLast {
                        finishExam(config: config, questions: questions)
                    } else {
                        index += 1
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private func load() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        let cfg = Queries.getExamConfiguration(Database.shared, country)
        config = cfg
        questions = Queries.getPracticeQuestions(Database.shared, country, language, limit: cfg.numberOfQuestions)
        remainingSeconds = cfg.timeLimitSeconds
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
}
