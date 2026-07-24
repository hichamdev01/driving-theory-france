import type { SQLiteDatabase } from 'expo-sqlite';
import type {
  AnswerKey,
  CategoryProgress,
  CategoryWithName,
  Country,
  CountryCode,
  ExamConfiguration,
  Language,
  LanguageCode,
  MistakeRow,
  OverallProgress,
  QuestionWithTranslation,
  RoadSignWithTranslation,
  UserSettings,
} from '../types';

export async function getCountries(db: SQLiteDatabase): Promise<Country[]> {
  return db.getAllAsync<Country>('SELECT id, code, name FROM countries ORDER BY name');
}

export async function getLanguagesForCountry(
  db: SQLiteDatabase,
  countryCode: CountryCode
): Promise<Language[]> {
  return db.getAllAsync<Language>(
    `SELECT l.id, l.code, l.name
     FROM languages l
     JOIN country_languages cl ON cl.language_code = l.code
     JOIN countries c ON c.id = cl.country_id
     WHERE c.code = ?
     ORDER BY cl.id ASC`,
    countryCode
  );
}

export async function getUserSettings(db: SQLiteDatabase): Promise<UserSettings> {
  const row = await db.getFirstAsync<{
    selected_country_code: string | null;
    selected_language_code: string | null;
  }>('SELECT selected_country_code, selected_language_code FROM user_settings WHERE id = 1');
  return {
    selected_country_code: (row?.selected_country_code as CountryCode | null) ?? null,
    selected_language_code: (row?.selected_language_code as LanguageCode | null) ?? null,
  };
}

export async function setSelectedCountry(db: SQLiteDatabase, countryCode: CountryCode): Promise<void> {
  await db.runAsync(
    'UPDATE user_settings SET selected_country_code = ?, selected_language_code = NULL WHERE id = 1',
    countryCode
  );
}

export async function setSelectedLanguage(db: SQLiteDatabase, languageCode: LanguageCode): Promise<void> {
  await db.runAsync('UPDATE user_settings SET selected_language_code = ? WHERE id = 1', languageCode);
}

export async function getCategoriesForCountry(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode
): Promise<CategoryWithName[]> {
  return db.getAllAsync<CategoryWithName>(
    `SELECT cat.id as id, cat.slug as slug, ct.name as name
     FROM categories cat
     JOIN countries c ON c.id = cat.country_id
     JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
     WHERE c.code = ?
     ORDER BY cat.id ASC`,
    languageCode,
    countryCode
  );
}

const QUESTION_SELECT = `
  SELECT
    q.id as id, q.country_id as country_id, q.category_id as category_id,
    q.correct_answer as correct_answer, q.difficulty as difficulty, q.image_path as image_path,
    cat.slug as category_slug, ct.name as category_name,
    qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
    qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation
  FROM questions q
  JOIN countries c ON c.id = q.country_id
  JOIN categories cat ON cat.id = q.category_id
  JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
  JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
  WHERE c.code = ? AND q.active = 1
`;

export async function getPracticeQuestions(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode,
  options: { categoryId?: number; limit?: number } = {}
): Promise<QuestionWithTranslation[]> {
  let sql = QUESTION_SELECT;
  const params: (string | number)[] = [languageCode, languageCode, countryCode];
  if (options.categoryId !== undefined) {
    sql += ' AND q.category_id = ?';
    params.push(options.categoryId);
  }
  sql += ' ORDER BY RANDOM()';
  if (options.limit) {
    sql += ' LIMIT ?';
    params.push(options.limit);
  }
  return db.getAllAsync<QuestionWithTranslation>(sql, ...params);
}

export async function getQuestionById(
  db: SQLiteDatabase,
  questionId: number,
  languageCode: LanguageCode
): Promise<QuestionWithTranslation | null> {
  const row = await db.getFirstAsync<QuestionWithTranslation>(
    `SELECT
      q.id as id, q.country_id as country_id, q.category_id as category_id,
      q.correct_answer as correct_answer, q.difficulty as difficulty, q.image_path as image_path,
      cat.slug as category_slug, ct.name as category_name,
      qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
      qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation
    FROM questions q
    JOIN categories cat ON cat.id = q.category_id
    JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
    JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
    WHERE q.id = ?`,
    languageCode,
    languageCode,
    questionId
  );
  return row ?? null;
}

export async function getExamConfiguration(
  db: SQLiteDatabase,
  countryCode: CountryCode
): Promise<ExamConfiguration> {
  const row = await db.getFirstAsync<ExamConfiguration>(
    `SELECT ec.id as id, ec.country_id as country_id, ec.number_of_questions as number_of_questions,
            ec.time_limit_seconds as time_limit_seconds, ec.passing_score as passing_score,
            ec.allowed_mistakes as allowed_mistakes
     FROM exam_configurations ec
     JOIN countries c ON c.id = ec.country_id
     WHERE c.code = ?`,
    countryCode
  );
  if (!row) {
    throw new Error(`No exam configuration found for country ${countryCode}`);
  }
  return row;
}

export async function getExamQuestions(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode
): Promise<QuestionWithTranslation[]> {
  const config = await getExamConfiguration(db, countryCode);
  return getPracticeQuestions(db, countryCode, languageCode, { limit: config.number_of_questions });
}

export async function recordAnswer(
  db: SQLiteDatabase,
  questionId: number,
  isCorrect: boolean
): Promise<void> {
  const now = new Date().toISOString();
  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO user_question_progress (question_id, attempts, correct_attempts, incorrect_attempts, last_answered_at)
       VALUES (?, 1, ?, ?, ?)
       ON CONFLICT(question_id) DO UPDATE SET
         attempts = attempts + 1,
         correct_attempts = correct_attempts + excluded.correct_attempts,
         incorrect_attempts = incorrect_attempts + excluded.incorrect_attempts,
         last_answered_at = excluded.last_answered_at`,
      questionId,
      isCorrect ? 1 : 0,
      isCorrect ? 0 : 1,
      now
    );

    if (!isCorrect) {
      await db.runAsync(
        `INSERT INTO user_mistakes (question_id, incorrect_count, last_incorrect_at)
         VALUES (?, 1, ?)
         ON CONFLICT(question_id) DO UPDATE SET
           incorrect_count = incorrect_count + 1,
           last_incorrect_at = excluded.last_incorrect_at`,
        questionId,
        now
      );
    } else {
      await db.runAsync('DELETE FROM user_mistakes WHERE question_id = ?', questionId);
    }
  });
}

export async function getMistakes(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode
): Promise<MistakeRow[]> {
  return db.getAllAsync<MistakeRow>(
    `SELECT
      q.id as id, q.country_id as country_id, q.category_id as category_id,
      q.correct_answer as correct_answer, q.difficulty as difficulty, q.image_path as image_path,
      cat.slug as category_slug, ct.name as category_name,
      qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
      qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation,
      um.incorrect_count as incorrect_count, um.last_incorrect_at as last_incorrect_at
    FROM user_mistakes um
    JOIN questions q ON q.id = um.question_id
    JOIN countries c ON c.id = q.country_id
    JOIN categories cat ON cat.id = q.category_id
    JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
    JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
    WHERE c.code = ?
    ORDER BY um.last_incorrect_at DESC`,
    languageCode,
    languageCode,
    countryCode
  );
}

export async function getRoadSigns(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode,
  categoryId?: number
): Promise<RoadSignWithTranslation[]> {
  let sql = `
    SELECT
      rs.id as id, rs.category_id as category_id, ct.name as category_name,
      rs.image_path as image_path, rs.shape as shape, rs.color as color,
      rst.name as name, rst.meaning as meaning, rst.explanation as explanation
    FROM road_signs rs
    JOIN countries c ON c.id = rs.country_id
    JOIN categories cat ON cat.id = rs.category_id
    JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
    JOIN road_sign_translations rst ON rst.road_sign_id = rs.id AND rst.language_code = ?
    WHERE c.code = ? AND rs.active = 1
  `;
  const params: (string | number)[] = [languageCode, languageCode, countryCode];
  if (categoryId !== undefined) {
    sql += ' AND rs.category_id = ?';
    params.push(categoryId);
  }
  sql += ' ORDER BY rs.id ASC';
  return db.getAllAsync<RoadSignWithTranslation>(sql, ...params);
}

export async function getRoadSignById(
  db: SQLiteDatabase,
  signId: number,
  languageCode: LanguageCode
): Promise<RoadSignWithTranslation | null> {
  const row = await db.getFirstAsync<RoadSignWithTranslation>(
    `SELECT
      rs.id as id, rs.category_id as category_id, ct.name as category_name,
      rs.image_path as image_path, rs.shape as shape, rs.color as color,
      rst.name as name, rst.meaning as meaning, rst.explanation as explanation
    FROM road_signs rs
    JOIN categories cat ON cat.id = rs.category_id
    JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
    JOIN road_sign_translations rst ON rst.road_sign_id = rs.id AND rst.language_code = ?
    WHERE rs.id = ?`,
    languageCode,
    languageCode,
    signId
  );
  return row ?? null;
}

export interface SaveExamResultInput {
  countryCode: CountryCode;
  score: number;
  passed: boolean;
  totalQuestions: number;
  correctQuestions: number;
  answers: { questionId: number; selectedAnswer: AnswerKey | null; correct: boolean }[];
}

export async function saveExamResult(db: SQLiteDatabase, input: SaveExamResultInput): Promise<number> {
  const country = await db.getFirstAsync<{ id: number }>(
    'SELECT id FROM countries WHERE code = ?',
    input.countryCode
  );
  if (!country) throw new Error(`Unknown country ${input.countryCode}`);

  const now = new Date().toISOString();
  let examResultId = 0;
  await db.withTransactionAsync(async () => {
    const result = await db.runAsync(
      `INSERT INTO exam_results (country_id, score, passed, total_questions, correct_questions, completed_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      country.id,
      input.score,
      input.passed ? 1 : 0,
      input.totalQuestions,
      input.correctQuestions,
      now
    );
    examResultId = result.lastInsertRowId;
    for (const answer of input.answers) {
      await db.runAsync(
        `INSERT INTO exam_result_answers (exam_result_id, question_id, selected_answer, correct)
         VALUES (?, ?, ?, ?)`,
        examResultId,
        answer.questionId,
        answer.selectedAnswer,
        answer.correct ? 1 : 0
      );
    }
  });
  return examResultId;
}

export interface ExamResultRow {
  id: number;
  score: number;
  passed: number;
  total_questions: number;
  correct_questions: number;
  completed_at: string;
}

export async function getRecentExamResults(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  limit = 5
): Promise<ExamResultRow[]> {
  return db.getAllAsync<ExamResultRow>(
    `SELECT er.id as id, er.score as score, er.passed as passed, er.total_questions as total_questions,
            er.correct_questions as correct_questions, er.completed_at as completed_at
     FROM exam_results er
     JOIN countries c ON c.id = er.country_id
     WHERE c.code = ?
     ORDER BY er.completed_at DESC
     LIMIT ?`,
    countryCode,
    limit
  );
}

export async function getExamResultById(
  db: SQLiteDatabase,
  examResultId: number
): Promise<ExamResultRow | null> {
  const row = await db.getFirstAsync<ExamResultRow>(
    `SELECT id, score, passed, total_questions, correct_questions, completed_at
     FROM exam_results WHERE id = ?`,
    examResultId
  );
  return row ?? null;
}

export interface ExamResultAnswerRow extends QuestionWithTranslation {
  selected_answer: AnswerKey | null;
  was_correct: number;
}

export async function getExamResultAnswers(
  db: SQLiteDatabase,
  examResultId: number,
  languageCode: LanguageCode
): Promise<ExamResultAnswerRow[]> {
  return db.getAllAsync<ExamResultAnswerRow>(
    `SELECT
      q.id as id, q.country_id as country_id, q.category_id as category_id,
      q.correct_answer as correct_answer, q.difficulty as difficulty, q.image_path as image_path,
      cat.slug as category_slug, ct.name as category_name,
      qt.question_text as question_text, qt.answer_a as answer_a, qt.answer_b as answer_b,
      qt.answer_c as answer_c, qt.answer_d as answer_d, qt.explanation as explanation,
      era.selected_answer as selected_answer, era.correct as was_correct
    FROM exam_result_answers era
    JOIN questions q ON q.id = era.question_id
    JOIN categories cat ON cat.id = q.category_id
    JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
    JOIN question_translations qt ON qt.question_id = q.id AND qt.language_code = ?
    WHERE era.exam_result_id = ?
    ORDER BY era.id ASC`,
    languageCode,
    languageCode,
    examResultId
  );
}

export async function getOverallProgress(
  db: SQLiteDatabase,
  countryCode: CountryCode,
  languageCode: LanguageCode
): Promise<OverallProgress> {
  const categories = await db.getAllAsync<{
    category_id: number;
    category_name: string;
    attempts: number;
    correct: number;
  }>(
    `SELECT cat.id as category_id, ct.name as category_name,
            COALESCE(SUM(uqp.attempts), 0) as attempts,
            COALESCE(SUM(uqp.correct_attempts), 0) as correct
     FROM categories cat
     JOIN countries c ON c.id = cat.country_id
     JOIN category_translations ct ON ct.category_id = cat.id AND ct.language_code = ?
     LEFT JOIN questions q ON q.category_id = cat.id
     LEFT JOIN user_question_progress uqp ON uqp.question_id = q.id
     WHERE c.code = ?
     GROUP BY cat.id, ct.name
     ORDER BY cat.id ASC`,
    languageCode,
    countryCode
  );

  const categoryProgress: CategoryProgress[] = categories.map((c) => ({
    category_id: c.category_id,
    category_name: c.category_name,
    attempts: c.attempts,
    correct: c.correct,
    accuracy: c.attempts > 0 ? Math.round((c.correct / c.attempts) * 100) : 0,
  }));

  const totals = categoryProgress.reduce(
    (acc, c) => {
      acc.attempts += c.attempts;
      acc.correct += c.correct;
      return acc;
    },
    { attempts: 0, correct: 0 }
  );

  const attemptedCategories = categoryProgress.filter((c) => c.attempts > 0);
  const weakestCategory =
    attemptedCategories.length > 0
      ? attemptedCategories.reduce((min, c) => (c.accuracy < min.accuracy ? c : min))
      : null;

  return {
    questionsAnswered: totals.attempts,
    correctAnswers: totals.correct,
    incorrectAnswers: totals.attempts - totals.correct,
    accuracy: totals.attempts > 0 ? Math.round((totals.correct / totals.attempts) * 100) : 0,
    weakestCategory,
    categories: categoryProgress,
  };
}
