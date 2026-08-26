import Foundation

enum Queries {
    static func getLanguagesForCountry(_ db: Database, _ countryCode: CountryCode) -> [Language] {
        db.query(
            """
            SELECT l.id as id, l.code as code, l.name as name
            FROM languages l
            JOIN country_languages cl ON cl.language_code = l.code
            JOIN countries c ON c.id = cl.country_id
            WHERE c.code = ?
            ORDER BY cl.id ASC
            """,
            [countryCode.rawValue]
        ) { r in
            Language(id: r.int64("id"), code: LanguageCode(rawValue: r.text("code"))!, name: r.text("name"))
        }
    }

    static func getUserSettings(_ db: Database) -> UserSettings {
        let row = db.queryOne(
            "SELECT selected_country_code, selected_language_code FROM user_settings WHERE id = 1"
        ) { r in
            (r.textOrNil("selected_country_code"), r.textOrNil("selected_language_code"))
        }
        return UserSettings(
            selectedCountryCode: row?.0.flatMap(CountryCode.init(rawValue:)),
            selectedLanguageCode: row?.1.flatMap(LanguageCode.init(rawValue:))
        )
    }

    static func setSelectedLanguage(_ db: Database, _ languageCode: LanguageCode) {
        db.run("UPDATE user_settings SET selected_language_code = ? WHERE id = 1", [languageCode.rawValue])
    }

    static func getCategoriesForCountry(_ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode) -> [CategoryWithName] {
        db.query(
            """
            SELECT cat.id as id, cat.slug as slug, ct.name as name
            FROM categories cat
            JOIN countries c ON c.id = cat.country_id
            JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
            JOIN questions q ON q.category_id = cat.id AND q.active = 1
            WHERE c.code = ?
            GROUP BY cat.id, cat.slug, ct.name
            ORDER BY cat.id ASC
            """,
            [languageCode.rawValue, countryCode.rawValue]
        ) { r in
            CategoryWithName(id: r.int64("id"), slug: r.text("slug"), name: r.text("name"))
        }
    }

    private static let questionSelect = """
        SELECT
          q.id as id, q.country_id as country_id, q.category_id as category_id,
          q.correct_answers as correct_answers, q.difficulty as difficulty,
          q.image_path as image_path, q.video_path as video_path,
          cat.slug as category_slug, ct.name as category_name,
          qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
          qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation
        FROM questions q
        JOIN countries c ON c.id = q.country_id
        JOIN categories cat ON cat.id = q.category_id
        JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
        JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
        WHERE c.code = ? AND q.active = 1
        """

    private static func mapQuestion(_ r: Row) -> QuestionWithTranslation {
        QuestionWithTranslation(
            id: r.int64("id"),
            countryId: r.int64("country_id"),
            categoryId: r.int64("category_id"),
            correctAnswers: AnswerKey.decodeSet(r.text("correct_answers")),
            difficulty: r.text("difficulty"),
            imagePath: r.textOrNil("image_path"),
            videoPath: r.textOrNil("video_path"),
            categorySlug: r.text("category_slug"),
            categoryName: r.text("category_name"),
            questionText: r.text("question_text"),
            answerA: r.text("answer_a"),
            answerB: r.text("answer_b"),
            answerC: r.text("answer_c"),
            answerD: r.text("answer_d"),
            explanation: r.text("explanation")
        )
    }

    static func getPracticeQuestions(
        _ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode,
        categoryId: Int64? = nil, limit: Int? = nil
    ) -> [QuestionWithTranslation] {
        var sql = questionSelect
        var params: [Any?] = [languageCode.rawValue, languageCode.rawValue, countryCode.rawValue]
        if let categoryId {
            sql += " AND q.category_id = ?"
            params.append(categoryId)
        }
        sql += " ORDER BY RANDOM()"
        if let limit {
            sql += " LIMIT ?"
            params.append(limit)
        }
        return db.query(sql, params, map: mapQuestion)
    }

    static func getExamConfiguration(_ db: Database, _ countryCode: CountryCode) -> ExamConfiguration {
        let row = db.queryOne(
            """
            SELECT ec.id as id, ec.country_id as country_id, ec.number_of_questions as number_of_questions,
                   ec.time_limit_seconds as practice_session_seconds, ec.passing_score as passing_score,
                   ec.allowed_mistakes as allowed_mistakes,
                   ec.seconds_per_question as practice_seconds_per_question
            FROM exam_configurations ec
            JOIN countries c ON c.id = ec.country_id
            WHERE c.code = ?
            """,
            [countryCode.rawValue]
        ) { r in
            ExamConfiguration(
                id: r.int64("id"), countryId: r.int64("country_id"),
                numberOfQuestions: r.int("number_of_questions"),
                practiceSessionSeconds: r.int("practice_session_seconds"),
                passingScore: r.int("passing_score"),
                allowedMistakes: r.int("allowed_mistakes"),
                practiceSecondsPerQuestion: r.int("practice_seconds_per_question")
            )
        }
        guard let row else { fatalError("No exam configuration for \(countryCode)") }
        return row
    }

    static func getExamQuestions(_ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode) -> [QuestionWithTranslation] {
        let config = getExamConfiguration(db, countryCode)
        let bank = getPracticeQuestions(db, countryCode, languageCode)
        return ExamQuestionSelector.select(from: bank, count: config.numberOfQuestions)
    }

    /// Records an answer. `confidence` is nil when it was not asked — during a
    /// timed exam, where a third tap would be both unrealistic and unfair.
    static func recordAnswer(
        _ db: Database, _ questionId: Int64, _ isCorrect: Bool, confidence: Confidence? = nil
    ) {
        let now = ISO8601DateFormatter().string(from: Date())
        let wasSure = confidence == .sure
        db.transaction {
            db.run(
                """
                INSERT INTO user_question_progress
                  (question_id, attempts, correct_attempts, incorrect_attempts,
                   confident_attempts, confident_correct, last_answered_at)
                VALUES (?, 1, ?, ?, ?, ?, ?)
                ON CONFLICT(question_id) DO UPDATE SET
                  attempts = attempts + 1,
                  correct_attempts = correct_attempts + excluded.correct_attempts,
                  incorrect_attempts = incorrect_attempts + excluded.incorrect_attempts,
                  confident_attempts = confident_attempts + excluded.confident_attempts,
                  confident_correct = confident_correct + excluded.confident_correct,
                  last_answered_at = excluded.last_answered_at
                """,
                [questionId, isCorrect ? 1 : 0, isCorrect ? 0 : 1,
                 wasSure ? 1 : 0, (wasSure && isCorrect) ? 1 : 0, now]
            )

            if !isCorrect {
                db.run(
                    """
                    INSERT INTO user_mistakes (question_id, incorrect_count, last_incorrect_at)
                    VALUES (?, 1, ?)
                    ON CONFLICT(question_id) DO UPDATE SET
                      incorrect_count = incorrect_count + 1,
                      last_incorrect_at = excluded.last_incorrect_at
                    """,
                    [questionId, now]
                )
            } else {
                db.run("DELETE FROM user_mistakes WHERE question_id = ?", [questionId])
            }
        }
    }

    static func getMistakes(_ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode) -> [MistakeRow] {
        db.query(
            """
            SELECT
              q.id as id, q.country_id as country_id, q.category_id as category_id,
              q.correct_answers as correct_answers, q.difficulty as difficulty,
              q.image_path as image_path, q.video_path as video_path,
              cat.slug as category_slug, ct.name as category_name,
              qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
              qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation,
              um.incorrect_count as incorrect_count, um.last_incorrect_at as last_incorrect_at,
              COALESCE(uqp.confident_attempts, 0) - COALESCE(uqp.confident_correct, 0) as confidently_wrong
            FROM user_mistakes um
            JOIN questions q ON q.id = um.question_id
            JOIN countries c ON c.id = q.country_id
            JOIN categories cat ON cat.id = q.category_id
            JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
            JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
            LEFT JOIN user_question_progress uqp ON uqp.question_id = q.id
            WHERE c.code = ?
            -- Confidently-wrong questions first: the learner does not know
            -- they have a gap, so they are the least likely to self-select.
            ORDER BY confidently_wrong DESC, um.last_incorrect_at DESC
            """,
            [languageCode.rawValue, languageCode.rawValue, countryCode.rawValue]
        ) { r in
            MistakeRow(
                question: mapQuestion(r),
                incorrectCount: r.int("incorrect_count"),
                lastIncorrectAt: r.text("last_incorrect_at"),
                confidentlyWrongCount: max(0, r.int("confidently_wrong"))
            )
        }
    }

    static func getRoadSignCategories(
        _ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode
    ) -> [RoadSignCategorySummary] {
        db.query(
            """
            SELECT
              cat.id as id, cat.slug as slug, ct.name as name, COUNT(rs.id) as sign_count
            FROM road_sign_categories cat
            JOIN countries c ON c.id = cat.country_id
            JOIN road_sign_category_translations ct
              ON ct.road_sign_category_id = cat.id AND ct.language_code = ?
            LEFT JOIN road_signs rs ON rs.category_id = cat.id AND rs.active = 1
            WHERE c.code = ?
            GROUP BY cat.id, cat.slug, ct.name
            ORDER BY cat.id ASC
            """,
            [languageCode.rawValue, countryCode.rawValue]
        ) { row in
            RoadSignCategorySummary(
                id: row.int64("id"),
                slug: row.text("slug"),
                name: row.text("name"),
                signCount: row.int("sign_count")
            )
        }
    }

    static func getRoadSigns(
        _ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode, categoryId: Int64? = nil
    ) -> [RoadSignWithTranslation] {
        var sql = """
            SELECT
              rs.id as id, rs.category_id as category_id, ct.name as category_name,
              rs.image_path as image_path, rs.shape as shape, rs.color as color,
              rst.name as name, rst.meaning as meaning
            FROM road_signs rs
            JOIN countries c ON c.id = rs.country_id
            JOIN road_sign_categories cat ON cat.id = rs.category_id
            JOIN road_sign_category_translations ct ON ct.road_sign_category_id = cat.id AND ct.language_code = ?
            JOIN road_sign_translations rst ON rst.road_sign_id = rs.id AND rst.language_code = ?
            WHERE c.code = ? AND rs.active = 1
            """
        var params: [Any?] = [languageCode.rawValue, languageCode.rawValue, countryCode.rawValue]
        if let categoryId {
            sql += " AND rs.category_id = ?"
            params.append(categoryId)
        }
        sql += " ORDER BY cat.id ASC, rst.name COLLATE NOCASE ASC"
        return db.query(sql, params) { r in
            RoadSignWithTranslation(
                id: r.int64("id"), categoryId: r.int64("category_id"), categoryName: r.text("category_name"),
                imagePath: r.textOrNil("image_path"), shape: r.text("shape"), color: r.text("color"),
                name: r.text("name"), meaning: r.text("meaning")
            )
        }
    }

    static func getRoadSignById(_ db: Database, _ signId: Int64, _ languageCode: LanguageCode) -> RoadSignWithTranslation? {
        db.queryOne(
            """
            SELECT
              rs.id as id, rs.category_id as category_id, ct.name as category_name,
              rs.image_path as image_path, rs.shape as shape, rs.color as color,
              rst.name as name, rst.meaning as meaning
            FROM road_signs rs
            JOIN road_sign_categories cat ON cat.id = rs.category_id
            JOIN road_sign_category_translations ct ON ct.road_sign_category_id = cat.id AND ct.language_code = ?
            JOIN road_sign_translations rst ON rst.road_sign_id = rs.id AND rst.language_code = ?
            WHERE rs.id = ?
            """,
            [languageCode.rawValue, languageCode.rawValue, signId]
        ) { r in
            RoadSignWithTranslation(
                id: r.int64("id"), categoryId: r.int64("category_id"), categoryName: r.text("category_name"),
                imagePath: r.textOrNil("image_path"), shape: r.text("shape"), color: r.text("color"),
                name: r.text("name"), meaning: r.text("meaning")
            )
        }
    }

    struct ExamAnswerInput {
        let questionId: Int64
        let selectedAnswers: Set<AnswerKey>
        let answerOrder: [AnswerKey]
        let correct: Bool
    }

    @discardableResult
    static func saveExamResult(
        _ db: Database, countryCode: CountryCode, score: Int, passed: Bool,
        totalQuestions: Int, correctQuestions: Int, answers: [ExamAnswerInput]
    ) -> Int64 {
        let country = db.queryOne("SELECT id FROM countries WHERE code = ?", [countryCode.rawValue]) { r in r.int64("id") }
        guard let countryId = country else { fatalError("Unknown country \(countryCode)") }

        let now = ISO8601DateFormatter().string(from: Date())
        var examResultId: Int64 = 0
        db.transaction {
            examResultId = db.run(
                """
                INSERT INTO exam_results (country_id, score, passed, total_questions, correct_questions, completed_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                [countryId, score, passed, totalQuestions, correctQuestions, now]
            )
            for answer in answers {
                db.run(
                    """
                    INSERT INTO exam_result_answers
                      (exam_result_id, question_id, selected_answer, selected_answers, answer_order, correct)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    [
                        examResultId, answer.questionId,
                        answer.selectedAnswers.sorted { $0.rawValue < $1.rawValue }.first?.rawValue,
                        AnswerKey.encodeSet(answer.selectedAnswers),
                        AnswerPresentation.encode(answer.answerOrder), answer.correct,
                    ]
                )
            }
        }
        return examResultId
    }

    static func getExamResultById(_ db: Database, _ examResultId: Int64) -> ExamResultRow? {
        db.queryOne(
            "SELECT id, score, passed, total_questions, correct_questions, completed_at FROM exam_results WHERE id = ?",
            [examResultId]
        ) { r in
            ExamResultRow(
                id: r.int64("id"), score: r.int("score"), passed: r.bool("passed"),
                totalQuestions: r.int("total_questions"), correctQuestions: r.int("correct_questions"),
                completedAt: r.text("completed_at")
            )
        }
    }

    static func getExamResultAnswers(_ db: Database, _ examResultId: Int64, _ languageCode: LanguageCode) -> [ExamResultAnswerRow] {
        db.query(
            """
            SELECT
              q.id as id, q.country_id as country_id, q.category_id as category_id,
              q.correct_answers as correct_answers, q.difficulty as difficulty,
              q.image_path as image_path, q.video_path as video_path,
              cat.slug as category_slug, ct.name as category_name,
              qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
              qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation,
              era.selected_answers as selected_answers, era.answer_order as answer_order,
              era.correct as was_correct
            FROM exam_result_answers era
            JOIN questions q ON q.id = era.question_id
            JOIN categories cat ON cat.id = q.category_id
            JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
            JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
            WHERE era.exam_result_id = ?
            ORDER BY era.id ASC
            """,
            [languageCode.rawValue, languageCode.rawValue, examResultId]
        ) { r in
            ExamResultAnswerRow(
                question: mapQuestion(r),
                selectedAnswers: AnswerKey.decodeSet(r.textOrNil("selected_answers") ?? ""),
                answerOrder: AnswerPresentation.decode(r.textOrNil("answer_order")),
                wasCorrect: r.bool("was_correct")
            )
        }
    }

    static func getRecentExamResults(_ db: Database, _ countryCode: CountryCode, limit: Int = 5) -> [ExamResultRow] {
        db.query(
            """
            SELECT er.id as id, er.score as score, er.passed as passed, er.total_questions as total_questions,
                   er.correct_questions as correct_questions, er.completed_at as completed_at
            FROM exam_results er
            JOIN countries c ON c.id = er.country_id
            WHERE c.code = ?
            ORDER BY er.completed_at DESC
            LIMIT ?
            """,
            [countryCode.rawValue, limit]
        ) { r in
            ExamResultRow(
                id: r.int64("id"), score: r.int("score"), passed: r.bool("passed"),
                totalQuestions: r.int("total_questions"), correctQuestions: r.int("correct_questions"),
                completedAt: r.text("completed_at")
            )
        }
    }

    /// Per-theme facts behind the readiness report.
    ///
    /// Unlike `getOverallProgress`, this counts *distinct questions seen* as
    /// well as raw attempts, and reports how many questions each theme actually
    /// holds — both are needed to tell "knows the theme" apart from "answered
    /// the same three questions twenty times".
    static func getReadinessReport(_ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode) -> ReadinessReport {
        let parser = ISO8601DateFormatter()
        let inputs = db.query(
            """
            SELECT cat.id as category_id, ct.name as category_name,
                   COUNT(DISTINCT q.id) as available,
                   COUNT(DISTINCT CASE WHEN uqp.attempts > 0 THEN q.id END) as seen,
                   COALESCE(SUM(uqp.attempts), 0) as attempts,
                   COALESCE(SUM(uqp.correct_attempts), 0) as correct,
                   MAX(uqp.last_answered_at) as last_answered_at
            FROM categories cat
            JOIN countries c ON c.id = cat.country_id
            JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
            LEFT JOIN questions q ON q.category_id = cat.id AND q.active = 1
            LEFT JOIN user_question_progress uqp ON uqp.question_id = q.id
            WHERE c.code = ?
            GROUP BY cat.id, ct.name
            ORDER BY cat.id ASC
            """,
            [languageCode.rawValue, countryCode.rawValue]
        ) { r -> ReadinessReport.ThemeInput in
            ReadinessReport.ThemeInput(
                categoryId: r.int64("category_id"),
                name: r.text("category_name"),
                availableQuestions: r.int("available"),
                seenQuestions: r.int("seen"),
                attempts: r.int("attempts"),
                correctAttempts: r.int("correct"),
                lastAnsweredAt: r.textOrNil("last_answered_at").flatMap { parser.date(from: $0) }
            )
        }
        return ReadinessReport.make(from: inputs)
    }

    static func getOverallProgress(_ db: Database, _ countryCode: CountryCode, _ languageCode: LanguageCode) -> OverallProgress {
        let categories = db.query(
            """
            SELECT cat.id as category_id, ct.name as category_name,
                   COALESCE(SUM(uqp.attempts), 0) as attempts,
                   COALESCE(SUM(uqp.correct_attempts), 0) as correct
            FROM categories cat
            JOIN countries c ON c.id = cat.country_id
            JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
            LEFT JOIN questions q ON q.category_id = cat.id
            LEFT JOIN user_question_progress uqp ON uqp.question_id = q.id
            WHERE c.code = ?
            GROUP BY cat.id, ct.name
            ORDER BY cat.id ASC
            """,
            [languageCode.rawValue, countryCode.rawValue]
        ) { r -> CategoryProgress in
            let attempts = r.int("attempts")
            let correct = r.int("correct")
            let accuracy = attempts > 0 ? Int((Double(correct) / Double(attempts) * 100).rounded()) : 0
            return CategoryProgress(
                categoryId: r.int64("category_id"), categoryName: r.text("category_name"),
                attempts: attempts, correct: correct, accuracy: accuracy
            )
        }

        let totalAttempts = categories.reduce(0) { $0 + $1.attempts }
        let totalCorrect = categories.reduce(0) { $0 + $1.correct }
        let attempted = categories.filter { $0.attempts > 0 }
        let weakest = attempted.min(by: { $0.accuracy < $1.accuracy })

        return OverallProgress(
            questionsAnswered: totalAttempts,
            correctAnswers: totalCorrect,
            incorrectAnswers: totalAttempts - totalCorrect,
            accuracy: totalAttempts > 0 ? Int((Double(totalCorrect) / Double(totalAttempts) * 100).rounded()) : 0,
            weakestCategory: weakest,
            categories: categories
        )
    }
}
