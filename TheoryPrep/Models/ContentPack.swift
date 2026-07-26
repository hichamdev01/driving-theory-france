import Foundation

struct ContentCountryPack: Codable {
    let country: ContentCountryInfo
    let languages: [LanguageCode]
    let categories: [ContentCategory]
    let roadSignCategories: [ContentCategory]
    let examConfiguration: ContentExamConfiguration
    let questions: [ContentQuestion]
    let roadSigns: [ContentRoadSign]
}

struct ContentCountryInfo: Codable {
    let code: CountryCode
    let name: String
}

struct ContentCategory: Codable {
    let slug: String
    let translations: [String: String]
}

struct ContentExamConfiguration: Codable {
    let numberOfQuestions: Int
    let timeLimitSeconds: Int
    let passingScore: Int
    let allowedMistakes: Int
}

struct ContentQuestion: Codable {
    let categorySlug: String
    let correctAnswer: AnswerKey
    let difficulty: String
    let imagePath: String?
    let translations: [String: ContentQuestionTranslation]
}

struct ContentQuestionTranslation: Codable {
    let questionText: String
    let answerA: String
    let answerB: String
    let answerC: String
    let answerD: String
    let explanation: String
}

struct ContentRoadSign: Codable {
    let roadSignCategorySlug: String
    let imagePath: String?
    let shape: String
    let color: String
    let translations: [String: ContentRoadSignTranslation]
}

struct ContentRoadSignTranslation: Codable {
    let name: String
    let meaning: String
}

enum ContentLoader {
    static func loadPack(named folderName: String) -> ContentCountryPack {
        guard let url = Bundle.main.url(forResource: "pack", withExtension: "json", subdirectory: "Content/\(folderName)") else {
            fatalError("Missing content pack: Content/\(folderName)/pack.json")
        }
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(ContentCountryPack.self, from: data)
    }

    static func loadAllPacks() -> [ContentCountryPack] {
        ["france"].map(loadPack)
    }
}
