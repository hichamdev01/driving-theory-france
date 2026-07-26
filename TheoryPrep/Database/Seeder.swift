import Foundation

enum Seeder {
    static func seedIfNeeded(_ db: Database) {
        db.exec(Schema.createTablesSQL)

        let row = db.queryOne("SELECT content_version FROM user_settings WHERE id = 1") { r in
            r.int64("content_version")
        }

        if row == nil || row != Schema.contentVersion {
            seedContent(db)
        }
    }

    private static func seedContent(_ db: Database) {
        let packs = ContentLoader.loadAllPacks()

        db.transaction {
            db.exec("""
                DELETE FROM exam_result_answers;
                DELETE FROM exam_results;
                DELETE FROM user_mistakes;
                DELETE FROM user_question_progress;
                DELETE FROM road_sign_translations;
                DELETE FROM road_signs;
                DELETE FROM road_sign_category_translations;
                DELETE FROM road_sign_categories;
                DELETE FROM question_translations;
                DELETE FROM questions;
                DELETE FROM category_translations;
                DELETE FROM categories;
                DELETE FROM country_languages;
                DELETE FROM exam_configurations;
                DELETE FROM languages;
                DELETE FROM countries;
            """)

            var allLanguages: Set<LanguageCode> = []
            for pack in packs {
                pack.languages.forEach { allLanguages.insert($0) }
            }
            let languageNames: [LanguageCode: String] = [
                .en: "English", .fr: "Français",
            ]
            for code in allLanguages {
                db.run("INSERT INTO languages (code, name) VALUES (?, ?)", [code.rawValue, languageNames[code]!])
            }

            for pack in packs {
                let countryId = db.run(
                    "INSERT INTO countries (code, name) VALUES (?, ?)",
                    [pack.country.code.rawValue, pack.country.name]
                )

                for lang in pack.languages {
                    db.run(
                        "INSERT INTO country_languages (country_id, language_code) VALUES (?, ?)",
                        [countryId, lang.rawValue]
                    )
                }

                var categoryIdBySlug: [String: Int64] = [:]
                for category in pack.categories {
                    let categoryId = db.run(
                        "INSERT INTO categories (country_id, slug) VALUES (?, ?)",
                        [countryId, category.slug]
                    )
                    categoryIdBySlug[category.slug] = categoryId
                    for (languageCode, name) in category.translations {
                        db.run(
                            "INSERT INTO category_translations (category_id, language_code, name) VALUES (?, ?, ?)",
                            [categoryId, languageCode, name]
                        )
                    }
                }

                for question in pack.questions {
                    guard let categoryId = categoryIdBySlug[question.categorySlug] else { continue }
                    let questionId = db.run(
                        """
                        INSERT INTO questions (country_id, category_id, correct_answer, difficulty, image_path, active, content_version)
                        VALUES (?, ?, ?, ?, ?, 1, ?)
                        """,
                        [countryId, categoryId, question.correctAnswer.rawValue, question.difficulty, question.imagePath, Schema.contentVersion]
                    )
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

                var roadSignCategoryIdBySlug: [String: Int64] = [:]
                for category in pack.roadSignCategories {
                    let categoryId = db.run(
                        "INSERT INTO road_sign_categories (country_id, slug) VALUES (?, ?)",
                        [countryId, category.slug]
                    )
                    roadSignCategoryIdBySlug[category.slug] = categoryId
                    for (languageCode, name) in category.translations {
                        db.run(
                            "INSERT INTO road_sign_category_translations (road_sign_category_id, language_code, name) VALUES (?, ?, ?)",
                            [categoryId, languageCode, name]
                        )
                    }
                }

                for sign in pack.roadSigns {
                    guard let categoryId = roadSignCategoryIdBySlug[sign.roadSignCategorySlug] else { continue }
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

                let cfg = pack.examConfiguration
                db.run(
                    """
                    INSERT INTO exam_configurations
                      (country_id, number_of_questions, time_limit_seconds, passing_score, allowed_mistakes)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    [countryId, cfg.numberOfQuestions, cfg.timeLimitSeconds, cfg.passingScore, cfg.allowedMistakes]
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
}
