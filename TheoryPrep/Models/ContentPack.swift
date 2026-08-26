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
    let practiceSessionSeconds: Int
    let passingScore: Int
    let allowedMistakes: Int
    let practiceSecondsPerQuestion: Int?
}

struct ContentQuestion: Codable {
    /// Stable identity, independent of the question's position in the pack.
    /// Optional so a pack that predates the field still loads; `stableKey`
    /// derives the same value the database backfill uses.
    let key: String?
    let categorySlug: String
    let correctAnswers: Set<AnswerKey>
    let difficulty: String
    let imagePath: String?
    let videoPath: String?
    let translations: [String: ContentQuestionTranslation]

    private enum CodingKeys: String, CodingKey {
        case key, categorySlug, correctAnswer, correctAnswers, difficulty, imagePath, videoPath, translations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        categorySlug = try container.decode(String.self, forKey: .categorySlug)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        videoPath = try container.decodeIfPresent(String.self, forKey: .videoPath)
        translations = try container.decode([String: ContentQuestionTranslation].self, forKey: .translations)

        if let answers = try container.decodeIfPresent(Set<AnswerKey>.self, forKey: .correctAnswers), !answers.isEmpty {
            correctAnswers = answers
        } else {
            correctAnswers = [try container.decode(AnswerKey.self, forKey: .correctAnswer)]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categorySlug, forKey: .categorySlug)
        try container.encode(correctAnswers, forKey: .correctAnswers)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encodeIfPresent(videoPath, forKey: .videoPath)
        try container.encode(translations, forKey: .translations)
    }
}

extension ContentQuestion {
    /// The key used to match this question against rows already in the
    /// database. Falls back to the image file stem, which is how existing
    /// installs were backfilled.
    var stableKey: String? {
        if let key, !key.isEmpty { return key }
        guard let imagePath else { return nil }
        return ((imagePath as NSString).lastPathComponent as NSString).deletingPathExtension
    }
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

private struct ContentRoadSignCatalog: Codable {
    let categories: [ContentCategory]
    let signs: [ContentRoadSign]
}

enum ContentLoader {
    static func loadPack(named folderName: String) -> ContentCountryPack {
        guard let url = Bundle.main.url(forResource: "pack", withExtension: "json", subdirectory: "Content/\(folderName)") else {
            fatalError("Missing content pack: Content/\(folderName)/pack.json")
        }
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pack = try! decoder.decode(ContentCountryPack.self, from: data)
        guard let catalogURL = Bundle.main.url(
            forResource: "road-signs", withExtension: "json", subdirectory: "Content/\(folderName)"
        ) else {
            validateTranslations(in: pack)
            return pack
        }
        let catalogData = try! Data(contentsOf: catalogURL)
        let catalog = try! decoder.decode(ContentRoadSignCatalog.self, from: catalogData)
        // `road-signs.json` is the canonical catalogue, while pack.json may
        // contribute a category that the catalogue does not yet contain (for
        // France, the core priority signs). Only merge signs belonging to
        // those additional categories so legacy duplicate general signs do
        // not appear twice.
        let catalogCategorySlugs = Set(catalog.categories.map(\.slug))
        let additionalCategories = pack.roadSignCategories.filter {
            !catalogCategorySlugs.contains($0.slug)
        }
        let additionalCategorySlugs = Set(additionalCategories.map(\.slug))
        let catalogImagePaths = Set(catalog.signs.compactMap(\.imagePath))
        let additionalSigns = pack.roadSigns.filter { sign in
            guard additionalCategorySlugs.contains(sign.roadSignCategorySlug) else { return false }
            guard let imagePath = sign.imagePath else { return true }
            return !catalogImagePaths.contains(imagePath)
        }
        let completePack = ContentCountryPack(
            country: pack.country,
            languages: pack.languages,
            categories: pack.categories,
            roadSignCategories: catalog.categories + additionalCategories,
            examConfiguration: pack.examConfiguration,
            questions: pack.questions,
            roadSigns: catalog.signs + additionalSigns
        )
        validateTranslations(in: completePack)
        return completePack
    }

    static func loadAllPacks() -> [ContentCountryPack] {
        ["france"].map(loadPack)
    }

    private static func validateTranslations(in pack: ContentCountryPack) {
        let requiredLanguages = pack.languages.map(\.rawValue)

        for category in pack.categories + pack.roadSignCategories {
            precondition(
                requiredLanguages.allSatisfy { category.translations[$0]?.isEmpty == false },
                "Missing translation for category \(category.slug)"
            )
        }

        for (index, question) in pack.questions.enumerated() {
            for language in requiredLanguages {
                guard let translation = question.translations[language] else {
                    preconditionFailure("Missing \(language) translation for question \(index)")
                }
                let fields = [
                    translation.questionText,
                    translation.answerA,
                    translation.answerB,
                    translation.answerC,
                    translation.answerD,
                    translation.explanation,
                ]
                precondition(
                    fields.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                    "Empty \(language) field for question \(index)"
                )
            }
        }

        for (index, sign) in pack.roadSigns.enumerated() {
            precondition(
                pack.roadSignCategories.contains { $0.slug == sign.roadSignCategorySlug },
                "Unknown road-sign category \(sign.roadSignCategorySlug) for road sign \(index)"
            )
            for language in requiredLanguages {
                guard let translation = sign.translations[language] else {
                    preconditionFailure("Missing \(language) translation for road sign \(index)")
                }
                precondition(
                    !translation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && !translation.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Empty \(language) translation for road sign \(index)"
                )
            }
        }
    }
}
