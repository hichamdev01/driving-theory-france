import XCTest
@testable import TheoryPrep

final class RandomPracticeTests: XCTestCase {
    private var db: Database!

    override func setUp() {
        super.setUp()
        db = Database(path: ":memory:")
        Seeder.seedIfNeeded(db)
    }

    override func tearDown() {
        db = nil
        super.tearDown()
    }

    func testRandomSessionHasThirtyUniqueQuestionsFromTheFullLocalizedPool() {
        for language in [LanguageCode.en, .fr] {
            let pool = Queries.getPracticeQuestions(db, .FR, language)
            let poolIDs = Set(pool.map(\.id))
            XCTAssertGreaterThan(pool.count, 30)
            let session = Queries.getRandomPracticeQuestions(db, .FR, language)
            XCTAssertEqual(session.count, 30)
            XCTAssertEqual(Set(session.map(\.id)).count, 30)
            XCTAssertTrue(Set(session.map(\.id)).isSubset(of: poolIDs))
            XCTAssertTrue(session.allSatisfy { !$0.questionText.isEmpty })
        }
    }

    func testShortExactAndEmptyPoolsUseEveryAvailableQuestionOnce() {
        for count in [30, 7, 1, 0] {
            db.run("""
                UPDATE questions SET active = CASE WHEN id IN
                (SELECT id FROM questions ORDER BY id LIMIT ?) THEN 1 ELSE 0 END
                """, [count])
            let pool = Queries.getPracticeQuestions(db, .FR, .fr)
            let session = Queries.getRandomPracticeQuestions(db, .FR, .fr)
            XCTAssertEqual(session.count, count)
            XCTAssertEqual(Set(session.map(\.id)), Set(pool.map(\.id)))
        }
    }

    func testDuplicateTranslationsCannotRepeatQuestionsOrShortenTheSession() {
        db.exec("""
            INSERT INTO question_translations
                (question_id, language_code, question_text, answer_a, answer_b, answer_c, answer_d, explanation)
            SELECT question_id, language_code, question_text, answer_a, answer_b, answer_c, answer_d, explanation
            FROM question_translations WHERE language_code = 'fr';
            INSERT INTO category_translations (category_id, language_code, name)
            SELECT category_id, language_code, name FROM category_translations WHERE language_code = 'fr';
            """)
        let session = Queries.getRandomPracticeQuestions(db, .FR, .fr)
        XCTAssertEqual(session.count, 30)
        XCTAssertEqual(Set(session.map(\.id)).count, 30)
    }

    func testShuffleHappensBeforeLimitingAndSessionsAreFresh() {
        // Across several draws, reach beyond any fixed prefix and observe new
        // orders. This catches LIMIT-before-shuffle and a cached session list.
        let firstIDs = db.query("SELECT id FROM questions WHERE active = 1 ORDER BY id LIMIT 30") { $0.int64("id") }
        let sessions = (0..<8).map { _ in Queries.getRandomPracticeQuestions(db, .FR, .fr).map(\.id) }
        XCTAssertGreaterThan(Set(sessions.flatMap { $0 }).count, 30)
        XCTAssertTrue(sessions.contains { !Set($0).isSubset(of: Set(firstIDs)) })
        XCTAssertGreaterThan(Set(sessions).count, 1)
    }

    func testSelectionDoesNotWriteProgressAndAnswersKeepTheirExistingBehavior() throws {
        let before = Queries.getReadinessReport(db, .FR, .fr)
        let session = Queries.getRandomPracticeQuestions(db, .FR, .fr)
        XCTAssertEqual(Queries.getReadinessReport(db, .FR, .fr), before)
        let question = try XCTUnwrap(session.first)

        Queries.recordAnswer(db, question.id, false, confidence: .sure)
        XCTAssertEqual(Queries.getMistakes(db, .FR, .fr).map(\.id), [question.id])
        Queries.recordAnswer(db, question.id, true, confidence: .unsure)
        XCTAssertTrue(Queries.getMistakes(db, .FR, .fr).isEmpty)

        let progress = try XCTUnwrap(db.queryOne(
            "SELECT attempts, correct_attempts, incorrect_attempts, confident_attempts FROM user_question_progress WHERE question_id = ?",
            [question.id]
        ) { ($0.int("attempts"), $0.int("correct_attempts"), $0.int("incorrect_attempts"), $0.int("confident_attempts")) })
        XCTAssertEqual(progress.0, 2)
        XCTAssertEqual(progress.1, 1)
        XCTAssertEqual(progress.2, 1)
        XCTAssertEqual(progress.3, 1)
        XCTAssertEqual(Queries.getReadinessReport(db, .FR, .fr).themes.reduce(0) { $0 + $1.seenQuestions }, 1)
    }

    func testCategoryPracticeStillUsesItsOwnTenQuestionLimit() throws {
        let category = try XCTUnwrap(Queries.getCategoriesForCountry(db, .FR, .fr).first)
        let session = Queries.getPracticeQuestions(db, .FR, .fr, categoryId: category.id, limit: 10)
        XCTAssertEqual(session.count, 10)
        XCTAssertTrue(session.allSatisfy { $0.categoryId == category.id })
    }
}
