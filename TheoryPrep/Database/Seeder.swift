import Foundation

enum Seeder {
    static func seedIfNeeded(_ db: Database) {
        db.exec(Schema.createTablesSQL)
        Schema.migrate(db)

        let row = db.queryOne("SELECT content_version FROM user_settings WHERE id = 1") { r in
            r.int64("content_version")
        }

        if row == nil || row != Schema.contentVersion {
            seedContent(db)
        }
    }

    /// Brings bundled content up to date **without touching user data**.
    ///
    /// This used to delete every table, user progress included, so shipping a
    /// single new question reset everyone's history, mistakes and readiness.
    /// Content rows are now matched on stable keys and updated in place, so a
    /// question keeps its row id — and therefore everything attached to it —
    /// across content releases.
    private static func seedContent(_ db: Database) {
        let packs = ContentLoader.loadAllPacks()

        db.transaction {
            let languageNames: [LanguageCode: String] = [.en: "English", .fr: "Français"]
            for code in Set(packs.flatMap(\.languages)) {
                db.run(
                    """
                    INSERT INTO languages (code, name) VALUES (?, ?)
                    ON CONFLICT(code) DO UPDATE SET name = excluded.name
                    """,
                    [code.rawValue, languageNames[code] ?? code.rawValue]
                )
            }

            for pack in packs {
                let countryId = upsertCountry(db, pack.country)
                syncCountryLanguages(db, countryId: countryId, languages: pack.languages)

                var categoryIdBySlug: [String: Int64] = [:]
                for category in pack.categories {
                    categoryIdBySlug[category.slug] = upsertCategory(db, countryId: countryId, category: category)
                }

                syncQuestions(db, countryId: countryId, pack: pack, categoryIdBySlug: categoryIdBySlug)

                // Road signs carry no user progress, so they can be replaced
                // wholesale. Children first — foreign keys are enforced.
                replaceRoadSigns(db, countryId: countryId, pack: pack)

                let cfg = pack.examConfiguration
                db.run("DELETE FROM exam_configurations WHERE country_id = ?", [countryId])
                db.run(
                    """
                    INSERT INTO exam_configurations
                      (country_id, number_of_questions, time_limit_seconds, passing_score, allowed_mistakes, seconds_per_question)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    [countryId, cfg.numberOfQuestions, cfg.practiceSessionSeconds, cfg.passingScore,
                     cfg.allowedMistakes, cfg.practiceSecondsPerQuestion ?? 20]
                )
            }

            db.run(
                """
                INSERT INTO user_settings (id, selected_country_code, selected_language_code, content_version)
                VALUES (1, NULL, NULL, ?)
                ON CONFLICT(id) DO UPDATE SET content_version = excluded.content_version
                """,
                [Schema.contentVersion]
            )
        }
    }

    // MARK: - Upserts
    //
    // `db.run` returns `last_insert_rowid`, which is not updated when an
    // upsert takes the UPDATE branch, so each helper reads the id back rather
    // than trusting the return value.

    private static func upsertCountry(_ db: Database, _ country: ContentCountryInfo) -> Int64 {
        db.run(
            """
            INSERT INTO countries (code, name) VALUES (?, ?)
            ON CONFLICT(code) DO UPDATE SET name = excluded.name
            """,
            [country.code.rawValue, country.name]
        )
        return db.queryOne("SELECT id FROM countries WHERE code = ?", [country.code.rawValue]) {
            $0.int64("id")
        }!
    }

    private static func syncCountryLanguages(_ db: Database, countryId: Int64, languages: [LanguageCode]) {
        // Nothing references this table, so a straight replace is safe.
        db.run("DELETE FROM country_languages WHERE country_id = ?", [countryId])
        for lang in languages {
            db.run(
                "INSERT INTO country_languages (country_id, language_code) VALUES (?, ?)",
                [countryId, lang.rawValue]
            )
        }
    }

    private static func upsertCategory(_ db: Database, countryId: Int64, category: ContentCategory) -> Int64 {
        db.run(
            """
            INSERT INTO categories (country_id, slug) VALUES (?, ?)
            ON CONFLICT(country_id, slug) DO UPDATE SET slug = excluded.slug
            """,
            [countryId, category.slug]
        )
        let categoryId = db.queryOne(
            "SELECT id FROM categories WHERE country_id = ? AND slug = ?", [countryId, category.slug]
        ) { $0.int64("id") }!

        db.run("DELETE FROM category_translations WHERE category_id = ?", [categoryId])
        for (languageCode, name) in category.translations {
            db.run(
                "INSERT INTO category_translations (category_id, language_code, name) VALUES (?, ?, ?)",
                [categoryId, languageCode, name]
            )
        }
        return categoryId
    }

    private static func syncQuestions(
        _ db: Database, countryId: Int64, pack: ContentCountryPack, categoryIdBySlug: [String: Int64]
    ) {
        var seenKeys: [String] = []

        for question in pack.questions {
            guard let categoryId = categoryIdBySlug[question.categorySlug],
                  let key = question.stableKey,
                  let primaryAnswer = question.correctAnswers.sorted(by: { $0.rawValue < $1.rawValue }).first
            else { continue }
            seenKeys.append(key)

            db.run(
                """
                INSERT INTO questions
                  (country_id, category_id, question_key, correct_answer, correct_answers,
                   difficulty, image_path, video_path, active, content_version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
                ON CONFLICT(country_id, question_key) DO UPDATE SET
                  category_id = excluded.category_id,
                  correct_answer = excluded.correct_answer,
                  correct_answers = excluded.correct_answers,
                  difficulty = excluded.difficulty,
                  image_path = excluded.image_path,
                  video_path = excluded.video_path,
                  active = 1,
                  content_version = excluded.content_version
                """,
                [
                    countryId, categoryId, key, primaryAnswer.rawValue,
                    AnswerKey.encodeSet(question.correctAnswers), question.difficulty,
                    question.imagePath, question.videoPath, Schema.contentVersion,
                ]
            )

            let questionId = db.queryOne(
                "SELECT id FROM questions WHERE country_id = ? AND question_key = ?", [countryId, key]
            ) { $0.int64("id") }!

            db.run("DELETE FROM question_translations WHERE question_id = ?", [questionId])
            for (languageCode, t) in question.translations {
                db.run(
                    """
                    INSERT INTO question_translations
                      (question_id, language_code, question_text, answer_a, answer_b, answer_c, answer_d, explanation)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    [questionId, languageCode, t.questionText, t.answerA, t.answerB, t.answerC, t.answerD, t.explanation]
                )
            }
        }

        // Questions dropped from the pack are retired, not deleted: their rows
        // are still referenced by past exam results and mistake history.
        // `active = 0` already excludes them from every question query.
        let placeholders = seenKeys.isEmpty ? "''" : seenKeys.map { _ in "?" }.joined(separator: ", ")
        db.run(
            "UPDATE questions SET active = 0 WHERE country_id = ? AND question_key NOT IN (\(placeholders))",
            [countryId] + seenKeys
        )
    }

    private static func replaceRoadSigns(_ db: Database, countryId: Int64, pack: ContentCountryPack) {
        db.run(
            """
            DELETE FROM road_sign_translations WHERE road_sign_id IN
              (SELECT id FROM road_signs WHERE country_id = ?)
            """,
            [countryId]
        )
        db.run("DELETE FROM road_signs WHERE country_id = ?", [countryId])
        db.run(
            """
            DELETE FROM road_sign_category_translations WHERE road_sign_category_id IN
              (SELECT id FROM road_sign_categories WHERE country_id = ?)
            """,
            [countryId]
        )
        db.run("DELETE FROM road_sign_categories WHERE country_id = ?", [countryId])

        var categoryIdBySlug: [String: Int64] = [:]
        for category in pack.roadSignCategories {
            let categoryId = db.run(
                "INSERT INTO road_sign_categories (country_id, slug) VALUES (?, ?)",
                [countryId, category.slug]
            )
            categoryIdBySlug[category.slug] = categoryId
            for (languageCode, name) in category.translations {
                db.run(
                    "INSERT INTO road_sign_category_translations (road_sign_category_id, language_code, name) VALUES (?, ?, ?)",
                    [categoryId, languageCode, name]
                )
            }
        }

        for sign in pack.roadSigns {
            guard let categoryId = categoryIdBySlug[sign.roadSignCategorySlug] else { continue }
            let signId = db.run(
                "INSERT INTO road_signs (country_id, category_id, image_path, shape, color, active) VALUES (?, ?, ?, ?, ?, 1)",
                [countryId, categoryId, sign.imagePath, sign.shape, sign.color]
            )
            for (languageCode, t) in sign.translations {
                db.run(
                    """
                    INSERT INTO road_sign_translations (road_sign_id, language_code, name, meaning)
                    VALUES (?, ?, ?, ?)
                    """,
                    [signId, languageCode, t.name, t.meaning]
                )
            }
        }
    }
}
