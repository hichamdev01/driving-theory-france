// SQLite schema for the local-first driving theory database.
// Static content tables (countries, languages, categories, questions, road_signs, exam_configurations)
// are re-seeded from bundled JSON content whenever CONTENT_VERSION changes.
// User data tables (user_question_progress, user_mistakes, exam_results, user_settings) are never wiped.

export const CONTENT_VERSION = 1;

export const CREATE_TABLES_SQL = `
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

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
  correct_answer TEXT NOT NULL CHECK (correct_answer IN ('a','b','c','d')),
  difficulty TEXT NOT NULL DEFAULT 'medium',
  image_path TEXT,
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

CREATE TABLE IF NOT EXISTS road_signs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country_id INTEGER NOT NULL REFERENCES countries(id),
  category_id INTEGER NOT NULL REFERENCES categories(id),
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
  meaning TEXT NOT NULL,
  explanation TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS exam_configurations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country_id INTEGER NOT NULL REFERENCES countries(id),
  number_of_questions INTEGER NOT NULL,
  time_limit_seconds INTEGER NOT NULL,
  passing_score INTEGER NOT NULL,
  allowed_mistakes INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS user_question_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id INTEGER NOT NULL UNIQUE REFERENCES questions(id),
  attempts INTEGER NOT NULL DEFAULT 0,
  correct_attempts INTEGER NOT NULL DEFAULT 0,
  incorrect_attempts INTEGER NOT NULL DEFAULT 0,
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
  correct INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS user_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  selected_country_code TEXT,
  selected_language_code TEXT,
  content_version INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_questions_country_category ON questions(country_id, category_id);
CREATE INDEX IF NOT EXISTS idx_question_translations_question ON question_translations(question_id, language_code);
CREATE INDEX IF NOT EXISTS idx_road_signs_country_category ON road_signs(country_id, category_id);
CREATE INDEX IF NOT EXISTS idx_road_sign_translations_sign ON road_sign_translations(road_sign_id, language_code);
CREATE INDEX IF NOT EXISTS idx_category_translations_category ON category_translations(category_id, language_code);
`;
