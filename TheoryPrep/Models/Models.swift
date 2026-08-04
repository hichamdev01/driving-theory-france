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

    var correctAnswer: AnswerKey {
        correctAnswers.sorted { $0.rawValue < $1.rawValue }.first ?? .a
    }

    var correctAnswerText: String {
        correctAnswers
            .sorted { $0.rawValue < $1.rawValue }
            .map { "\($0.rawValue.uppercased()). \(answerText(for: $0))" }
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
    let timeLimitSeconds: Int
    let passingScore: Int
    let allowedMistakes: Int
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

    var id: Int64 { question.id }
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
    let wasCorrect: Bool

    var id: Int64 { question.id }
}
