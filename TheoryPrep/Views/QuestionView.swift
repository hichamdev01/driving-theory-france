import SwiftUI

struct QuestionView: View {
    let mode: QuizMode
    var categoryId: Int64? = nil
    @Binding var path: NavigationPath

    @EnvironmentObject var settings: AppSettings
    @State private var questions: [QuestionWithTranslation]?
    @State private var index = 0
    @State private var selected: AnswerKey?
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
    }

    @ViewBuilder
    private func questionBody(_ question: QuestionWithTranslation, total: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(settings.t(.questionOf)) \(index + 1) / \(total)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        Text(question.categoryName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.routeBlue)
                            .textCase(.uppercase)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.border)
                            Capsule()
                                .fill(Theme.buttonGradient)
                                .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(total))
                                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: index)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 8)

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
                        answerRow(key, question: question)
                    }
                }

                if submitted {
                    feedbackCard(question)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }

                PrimaryButton(
                    label: submitted ? (index == total - 1 ? settings.t(.finishButton) : settings.t(.continueButton)) : settings.t(.submitAnswer),
                    disabled: !submitted && selected == nil
                ) {
                    submitted ? handleContinue(total: total) : handleSubmit(question)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: submitted)
    }

    private func answerRow(_ key: AnswerKey, question: QuestionWithTranslation) -> some View {
        let isSelected = selected == key
        let isCorrectAnswer = key == question.correctAnswer
        var borderColor = Theme.border
        var backgroundColor = Theme.surface
        if submitted && isCorrectAnswer {
            borderColor = Theme.success
            backgroundColor = Theme.success.opacity(0.1)
        } else if submitted && isSelected && !isCorrectAnswer {
            borderColor = Theme.danger
            backgroundColor = Theme.danger.opacity(0.1)
        } else if !submitted && isSelected {
            borderColor = Theme.routeBlue
            backgroundColor = Theme.routeBlue.opacity(0.08)
        }

        return Button(action: {
            if !submitted {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { selected = key }
            }
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
                if submitted && isCorrectAnswer {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                } else if submitted && isSelected && !isCorrectAnswer {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.danger)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(borderColor, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .scaleEffect(isSelected && !submitted ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .disabled(submitted)
    }

    private func feedbackCard(_ question: QuestionWithTranslation) -> some View {
        let isCorrect = selected == question.correctAnswer
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundColor(isCorrect ? Theme.success : Theme.danger)
                Text(isCorrect ? settings.t(.correct) : settings.t(.incorrect))
                    .font(.display(17, .heavy))
                    .foregroundColor(isCorrect ? Theme.success : Theme.danger)
            }
            if !isCorrect {
                Text("\(settings.t(.correctAnswerWas)) \(question.answerText(for: question.correctAnswer))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text)
            }
            Text(settings.t(.explanation))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .padding(.top, 4)
            Text(question.explanation)
                .font(.system(size: 14))
                .foregroundColor(Theme.text)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }

    private func loadQuestions() {
        guard questions == nil, let country = settings.countryCode, let language = settings.languageCode else { return }
        switch mode {
        case .practice:
            questions = Queries.getPracticeQuestions(Database.shared, country, language, categoryId: categoryId, limit: 10)
        case .mistakes:
            questions = Queries.getMistakes(Database.shared, country, language).map(\.question)
        }
    }

    private func handleSubmit(_ question: QuestionWithTranslation) {
        guard let selected else { return }
        let isCorrect = selected == question.correctAnswer
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
        selected = nil
        submitted = false
    }
}
