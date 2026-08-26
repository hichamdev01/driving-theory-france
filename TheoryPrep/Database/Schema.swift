import Foundation

enum Schema {
    static let contentVersion: Int64 = 24

    static let createTablesSQL = """
    CREATE TABLE IF NOT EXISTS countries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS languages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS country_languages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      language_code TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      slug TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS category_translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL REFERENCES categories(id),
      language_code TEXT NOT NULL,
      name TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      category_id INTEGER NOT NULL REFERENCES categories(id),
      question_key TEXT,
      correct_answer TEXT NOT NULL CHECK (correct_answer IN ('a','b','c','d')),
      correct_answers TEXT NOT NULL DEFAULT '',
      difficulty TEXT NOT NULL DEFAULT 'medium',
      image_path TEXT,
      video_path TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      content_version INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS question_translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL REFERENCES questions(id),
      language_code TEXT NOT NULL,
      question_text TEXT NOT NULL,
      answer_a TEXT NOT NULL,
      answer_b TEXT NOT NULL,
      answer_c TEXT NOT NULL,
      answer_d TEXT NOT NULL,
      explanation TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS road_sign_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      slug TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS road_sign_category_translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      road_sign_category_id INTEGER NOT NULL REFERENCES road_sign_categories(id),
      language_code TEXT NOT NULL,
      name TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS road_signs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      category_id INTEGER NOT NULL REFERENCES road_sign_categories(id),
      image_path TEXT,
      shape TEXT NOT NULL DEFAULT 'circle',
      color TEXT NOT NULL DEFAULT '#1E5AA8',
      active INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS road_sign_translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      road_sign_id INTEGER NOT NULL REFERENCES road_signs(id),
      language_code TEXT NOT NULL,
      name TEXT NOT NULL,
      meaning TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS exam_configurations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      number_of_questions INTEGER NOT NULL,
      time_limit_seconds INTEGER NOT NULL,
      passing_score INTEGER NOT NULL,
      allowed_mistakes INTEGER NOT NULL,
      seconds_per_question INTEGER NOT NULL DEFAULT 20
    );

    CREATE TABLE IF NOT EXISTS user_question_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL UNIQUE REFERENCES questions(id),
      attempts INTEGER NOT NULL DEFAULT 0,
      correct_attempts INTEGER NOT NULL DEFAULT 0,
      incorrect_attempts INTEGER NOT NULL DEFAULT 0,
      confident_attempts INTEGER NOT NULL DEFAULT 0,
      confident_correct INTEGER NOT NULL DEFAULT 0,
      last_answered_at TEXT
    );

    CREATE TABLE IF NOT EXISTS user_mistakes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL UNIQUE REFERENCES questions(id),
      incorrect_count INTEGER NOT NULL DEFAULT 0,
      last_incorrect_at TEXT
    );

    CREATE TABLE IF NOT EXISTS exam_results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      country_id INTEGER NOT NULL REFERENCES countries(id),
      score INTEGER NOT NULL,
      passed INTEGER NOT NULL,
      total_questions INTEGER NOT NULL,
      correct_questions INTEGER NOT NULL,
      completed_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS exam_result_answers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exam_result_id INTEGER NOT NULL REFERENCES exam_results(id),
      question_id INTEGER NOT NULL REFERENCES questions(id),
      selected_answer TEXT,
      selected_answers TEXT,
      answer_order TEXT,
      correct INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS user_settings (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      selected_country_code TEXT,
      selected_language_code TEXT,
      content_version INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_questions_country_category ON questions(country_id, category_id);
    -- The unique indexes backing content upserts are created in `migrate()`,
    -- after the columns they cover are guaranteed to exist on older installs.
    CREATE INDEX IF NOT EXISTS idx_question_translations_question ON question_translations(question_id, language_code);
    CREATE INDEX IF NOT EXISTS idx_road_signs_country_category ON road_signs(country_id, category_id);
    CREATE INDEX IF NOT EXISTS idx_road_sign_translations_sign ON road_sign_translations(road_sign_id, language_code);
    CREATE INDEX IF NOT EXISTS idx_category_translations_category ON category_translations(category_id, language_code);
    CREATE INDEX IF NOT EXISTS idx_road_sign_category_translations ON road_sign_category_translations(road_sign_category_id, language_code);
    """

    static func migrate(_ db: Database) {
        addColumnIfNeeded(db, table: "questions", column: "correct_answers", definition: "TEXT NOT NULL DEFAULT ''")
        addColumnIfNeeded(db, table: "questions", column: "video_path", definition: "TEXT")
        addColumnIfNeeded(db, table: "exam_result_answers", column: "selected_answers", definition: "TEXT")
        addColumnIfNeeded(db, table: "exam_result_answers", column: "answer_order", definition: "TEXT")
        // Optional practice timer. This is a training setting rather than a
        // claim about the timing used by every official ETG provider.
        addColumnIfNeeded(db, table: "exam_configurations", column: "seconds_per_question", definition: "INTEGER NOT NULL DEFAULT 20")
        // Confidence is only captured in practice, so these stay at 0 for
        // answers given before the feature existed and during exams.
        addColumnIfNeeded(db, table: "user_question_progress", column: "confident_attempts", definition: "INTEGER NOT NULL DEFAULT 0")
        addColumnIfNeeded(db, table: "user_question_progress", column: "confident_correct", definition: "INTEGER NOT NULL DEFAULT 0")

        addColumnIfNeeded(db, table: "questions", column: "question_key", definition: "TEXT")
        backfillQuestionKeys(db)

        // Created after the backfill: the index is UNIQUE, so it can only be
        // built once every existing row has its key.
        db.exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_questions_key ON questions(country_id, question_key)")
        db.exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_slug ON categories(country_id, slug)")
    }

    /// Gives already-installed questions the same stable key the content pack
    /// now carries, derived the same way (image file name without extension).
    ///
    /// Without this an upgrade would see every question as new, insert
    /// duplicates, and strand the progress attached to the old rows.
    private static func backfillQuestionKeys(_ db: Database) {
        let rows = db.query(
            "SELECT id, image_path FROM questions WHERE question_key IS NULL AND image_path IS NOT NULL"
        ) { ($0.int64("id"), $0.text("image_path")) }
        guard !rows.isEmpty else { return }
        db.transaction {
            for (id, imagePath) in rows {
                let key = (imagePath as NSString).lastPathComponent
                let stem = (key as NSString).deletingPathExtension
                db.run("UPDATE questions SET question_key = ? WHERE id = ?", [stem, id])
            }
        }
    }

    private static func addColumnIfNeeded(_ db: Database, table: String, column: String, definition: String) {
        let columns = db.query("PRAGMA table_info(\(table))") { $0.text("name") }
        guard !columns.contains(column) else { return }
        db.exec("ALTER TABLE \(table) ADD COLUMN \(column) \(definition)")
    }
}
