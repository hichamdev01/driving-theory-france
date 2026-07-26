import SwiftUI

struct ExamRunView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var settings: AppSettings

    @State private var config: ExamConfiguration?
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var answers: [Int64: AnswerKey] = [:]
    @State private var remainingSeconds = 0
    @State private var finishing = false
    @State private var finished = false
    @State private var timer: Timer?

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
    }

    @ViewBuilder
    private func examBody(config: ExamConfiguration, questions: [QuestionWithTranslation]) -> some View {
        let question = questions[index]
        let isLast = index == questions.count - 1
        let selected = answers[question.id]

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "timer")
                    Text("\(settings.t(.timeRemaining)): \(formatTime(remainingSeconds))")
                        .font(.gauge(14, .bold))
                }
                .foregroundColor(remainingSeconds < 60 ? Theme.danger : Theme.textMuted)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(settings.t(.questionOf)) \(index + 1) / \(questions.count)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.border)
                            Capsule()
                                .fill(Theme.buttonGradient)
                                .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(questions.count))
                                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: index)
                        }
                    }
                    .frame(height: 6)
                }

                if let imagePath = question.imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: Theme.text.opacity(0.12), radius: 14, x: 0, y: 6)
                        .padding(.horizontal, -20)
                }

                Text(question.questionText)
                    .font(.display(20, .bold))
                    .foregroundColor(Theme.text)

                VStack(spacing: 10) {
                    ForEach(AnswerKey.allCases, id: \.self) { key in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { answers[question.id] = key }
                        }) {
                            HStack(spacing: 12) {
                                Text(key.rawValue.uppercased())
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Theme.textMuted)
                                    .frame(width: 20, alignment: .leading)
                                Text(question.answerText(for: key))
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.text)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(16)
                            .background(selected == key ? Theme.routeBlue.opacity(0.08) : Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(selected == key ? Theme.routeBlue : Theme.border, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                            .scaleEffect(selected == key ? 1.02 : 1)
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds <= 1 {
                timer?.invalidate()
                if let cfg = config, let qs = questions {
                    finishExam(config: cfg, questions: qs)
                }
            } else {
                remainingSeconds -= 1
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
            let selected = answers[question.id]
            let isCorrect = selected == question.correctAnswer
            if isCorrect { correctCount += 1 }
            Queries.recordAnswer(Database.shared, question.id, isCorrect)
            answerInputs.append(Queries.ExamAnswerInput(questionId: question.id, selectedAnswer: selected, correct: isCorrect))
        }

        let score = questions.isEmpty ? 0 : Int((Double(correctCount) / Double(questions.count) * 100).rounded())
        let passed = score >= config.passingScore
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
