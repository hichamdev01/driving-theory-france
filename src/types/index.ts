export type LanguageCode = 'en' | 'pt' | 'fr' | 'es';
export type CountryCode = 'PT' | 'FR' | 'ES';
export type AnswerKey = 'a' | 'b' | 'c' | 'd';

export interface Country {
  id: number;
  code: CountryCode;
  name: string;
}

export interface Language {
  id: number;
  code: LanguageCode;
  name: string;
}

export interface CategoryWithName {
  id: number;
  slug: string;
  name: string;
}

export interface QuestionRow {
  id: number;
  country_id: number;
  category_id: number;
  correct_answer: AnswerKey;
  difficulty: string;
  image_path: string | null;
}

export interface QuestionWithTranslation extends QuestionRow {
  category_slug: string;
  category_name: string;
  question_text: string;
  answer_a: string;
  answer_b: string;
  answer_c: string;
  answer_d: string;
  explanation: string;
}

export interface RoadSignWithTranslation {
  id: number;
  category_id: number;
  category_name: string;
  image_path: string | null;
  shape: string;
  color: string;
  name: string;
  meaning: string;
  explanation: string;
}

export interface ExamConfiguration {
  id: number;
  country_id: number;
  number_of_questions: number;
  time_limit_seconds: number;
  passing_score: number;
  allowed_mistakes: number;
}

export interface UserSettings {
  selected_country_code: CountryCode | null;
  selected_language_code: LanguageCode | null;
}

export interface CategoryProgress {
  category_id: number;
  category_name: string;
  attempts: number;
  correct: number;
  accuracy: number;
}

export interface OverallProgress {
  questionsAnswered: number;
  correctAnswers: number;
  incorrectAnswers: number;
  accuracy: number;
  weakestCategory: CategoryProgress | null;
  categories: CategoryProgress[];
}

export interface MistakeRow extends QuestionWithTranslation {
  incorrect_count: number;
  last_incorrect_at: string;
}

// ---- Content JSON shapes (bundled per-country content, imported into SQLite) ----

export interface ContentCategory {
  slug: string;
  translations: Partial<Record<LanguageCode, string>>;
}

export interface ContentQuestion {
  category_slug: string;
  correct_answer: AnswerKey;
  difficulty: 'easy' | 'medium' | 'hard';
  image_path?: string | null;
  translations: Partial<Record<LanguageCode, {
    question_text: string;
    answer_a: string;
    answer_b: string;
    answer_c: string;
    answer_d: string;
    explanation: string;
  }>>;
}

export interface ContentRoadSign {
  category_slug: string;
  image_path?: string | null;
  shape: 'circle' | 'triangle' | 'square' | 'octagon';
  color: string;
  translations: Partial<Record<LanguageCode, {
    name: string;
    meaning: string;
    explanation: string;
  }>>;
}

export interface ContentExamConfiguration {
  number_of_questions: number;
  time_limit_seconds: number;
  passing_score: number;
  allowed_mistakes: number;
}

export interface CountryContentPack {
  country: { code: CountryCode; name: string };
  languages: LanguageCode[];
  categories: ContentCategory[];
  questions: ContentQuestion[];
  roadSigns: ContentRoadSign[];
  examConfiguration: ContentExamConfiguration;
}
