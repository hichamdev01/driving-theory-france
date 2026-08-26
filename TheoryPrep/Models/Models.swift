import Foundation

enum LanguageCode: String, Codable, CaseIterable, Hashable {
    case en, fr
}

enum CountryCode: String, Codable, CaseIterable, Hashable {
    case FR
}

enum AnswerKey: String, Codable, CaseIterable, Hashable {
    case a, b, c, d

    static func decodeSet(_ value: String) -> Set<AnswerKey> {
        Set(value.split(separator: ",").compactMap { AnswerKey(rawValue: String($0)) })
    }

    static func encodeSet(_ answers: Set<AnswerKey>) -> String {
        answers.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue).joined(separator: ",")
    }
}

/// Keeps the answer text tied to its canonical key while allowing each quiz
/// session to present the four rows in a fresh order.
enum AnswerPresentation {
    static let canonicalOrder = AnswerKey.allCases

    static func shuffledOrder() -> [AnswerKey] {
        canonicalOrder.shuffled()
    }

    static func encode(_ order: [AnswerKey]) -> String {
        normalized(order).map(\.rawValue).joined(separator: ",")
    }

    static func decode(_ value: String?) -> [AnswerKey] {
        guard let value else { return canonicalOrder }
        return normalized(value.split(separator: ",").compactMap { AnswerKey(rawValue: String($0)) })
    }

    static func normalized(_ order: [AnswerKey]) -> [AnswerKey] {
        guard order.count == canonicalOrder.count, Set(order) == Set(canonicalOrder) else {
            return canonicalOrder
        }
        return order
    }

    static func displayKey(for canonicalKey: AnswerKey, in order: [AnswerKey]) -> AnswerKey {
        let order = normalized(order)
        guard let index = order.firstIndex(of: canonicalKey) else { return canonicalKey }
        return canonicalOrder[index]
    }
}

/// Whether the learner believed they knew the answer, captured at the moment
/// they commit to it.
///
/// This separates four states that a plain right/wrong counter collapses into
/// two. The one that matters is *confidently wrong*: the learner is not aware
/// of the gap, so it will not show up as something they think they need to
/// revise — and it is the state most likely to cost a mark on exam day.
enum Confidence: String, Codable, Hashable {
    case sure, unsure
}

struct Language: Identifiable, Hashable {
    let id: Int64
    let code: LanguageCode
    let name: String
}

struct CategoryWithName: Identifiable, Hashable {
    let id: Int64
    let slug: String
    let name: String
}

struct QuestionWithTranslation: Identifiable, Hashable {
    let id: Int64
    let countryId: Int64
    let categoryId: Int64
    let correctAnswers: Set<AnswerKey>
    let difficulty: String
    let imagePath: String?
    let videoPath: String?
    let categorySlug: String
    let categoryName: String
    let questionText: String
    let answerA: String
    let answerB: String
    let answerC: String
    let answerD: String
    let explanation: String

    var hasExamMedia: Bool {
        imagePath != nil || videoPath != nil
    }

    var correctAnswer: AnswerKey {
        correctAnswers.sorted { $0.rawValue < $1.rawValue }.first ?? .a
    }

    var correctAnswerText: String {
        correctAnswerText(displayOrder: AnswerPresentation.canonicalOrder)
    }

    func correctAnswerText(displayOrder: [AnswerKey]) -> String {
        let displayOrder = AnswerPresentation.normalized(displayOrder)
        return correctAnswers
            .sorted {
                (displayOrder.firstIndex(of: $0) ?? 0) < (displayOrder.firstIndex(of: $1) ?? 0)
            }
            .map { canonicalKey in
                let displayKey = AnswerPresentation.displayKey(for: canonicalKey, in: displayOrder)
                return "\(displayKey.rawValue.uppercased()). \(answerText(for: canonicalKey))"
            }
            .joined(separator: " • ")
    }

    func answerText(for key: AnswerKey) -> String {
        switch key {
        case .a: return answerA
        case .b: return answerB
        case .c: return answerC
        case .d: return answerD
        }
    }
}

struct RoadSignWithTranslation: Identifiable, Hashable {
    let id: Int64
    let categoryId: Int64
    let categoryName: String
    let imagePath: String?
    let shape: String
    let color: String
    let name: String
    let meaning: String
}

struct RoadSignCategorySummary: Identifiable, Hashable {
    let id: Int64
    let slug: String
    let name: String
    let signCount: Int
}

struct ExamConfiguration: Hashable {
    let id: Int64
    let countryId: Int64
    let numberOfQuestions: Int
    /// Internal practice-session ceiling; not an official ETG duration claim.
    let practiceSessionSeconds: Int
    let passingScore: Int
    let allowedMistakes: Int
    /// Optional per-question training timer. This is not presented as an
    /// official ETG timing rule.
    let practiceSecondsPerQuestion: Int
}

struct UserSettings {
    var selectedCountryCode: CountryCode?
    var selectedLanguageCode: LanguageCode?
}

struct CategoryProgress: Identifiable, Hashable {
    var id: Int64 { categoryId }
    let categoryId: Int64
    let categoryName: String
    let attempts: Int
    let correct: Int
    let accuracy: Int
}

struct OverallProgress {
    let questionsAnswered: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let accuracy: Int
    let weakestCategory: CategoryProgress?
    let categories: [CategoryProgress]

    static let empty = OverallProgress(
        questionsAnswered: 0, correctAnswers: 0, incorrectAnswers: 0,
        accuracy: 0, weakestCategory: nil, categories: []
    )
}

struct MistakeRow: Identifiable, Hashable {
    let question: QuestionWithTranslation
    let incorrectCount: Int
    let lastIncorrectAt: String
    /// Times this was answered wrongly while the learner marked themselves sure.
    let confidentlyWrongCount: Int

    var id: Int64 { question.id }
    var wasConfidentlyWrong: Bool { confidentlyWrongCount > 0 }
}

struct ExamResultRow: Identifiable, Hashable {
    let id: Int64
    let score: Int
    let passed: Bool
    let totalQuestions: Int
    let correctQuestions: Int
    let completedAt: String
}

struct ExamResultAnswerRow: Identifiable, Hashable {
    let question: QuestionWithTranslation
    let selectedAnswers: Set<AnswerKey>
    let answerOrder: [AnswerKey]
    let wasCorrect: Bool

    var id: Int64 { question.id }
}
