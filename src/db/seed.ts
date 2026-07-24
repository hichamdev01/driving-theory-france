import type { SQLiteDatabase } from 'expo-sqlite';
import { CONTENT_VERSION } from './schema';
import type { CountryContentPack, LanguageCode } from '../types';
import portugalPack from '../content/portugal/pack.json';
import francePack from '../content/france/pack.json';
import spainPack from '../content/spain/pack.json';

const CONTENT_PACKS = [portugalPack, francePack, spainPack] as unknown as CountryContentPack[];

const LANGUAGE_NAMES: Record<LanguageCode, string> = {
  en: 'English',
  pt: 'Português',
  fr: 'Français',
  es: 'Español',
};

export async function seedContent(db: SQLiteDatabase): Promise<void> {
  await db.withTransactionAsync(async () => {
    await db.execAsync(`
      DELETE FROM road_sign_translations;
      DELETE FROM road_signs;
      DELETE FROM question_translations;
      DELETE FROM questions;
      DELETE FROM category_translations;
      DELETE FROM categories;
      DELETE FROM country_languages;
      DELETE FROM exam_configurations;
      DELETE FROM languages;
      DELETE FROM countries;
    `);

    const allLanguages = new Set<LanguageCode>();
    for (const pack of CONTENT_PACKS) {
      pack.languages.forEach((l) => allLanguages.add(l));
    }
    for (const code of allLanguages) {
      await db.runAsync('INSERT INTO languages (code, name) VALUES (?, ?)', code, LANGUAGE_NAMES[code]);
    }

    for (const pack of CONTENT_PACKS) {
      const countryResult = await db.runAsync(
        'INSERT INTO countries (code, name) VALUES (?, ?)',
        pack.country.code,
        pack.country.name
      );
      const countryId = countryResult.lastInsertRowId;

      for (const lang of pack.languages) {
        await db.runAsync(
          'INSERT INTO country_languages (country_id, language_code) VALUES (?, ?)',
          countryId,
          lang
        );
      }

      const categoryIdBySlug = new Map<string, number>();
      for (const cat of pack.categories) {
        const catResult = await db.runAsync(
          'INSERT INTO categories (country_id, slug) VALUES (?, ?)',
          countryId,
          cat.slug
        );
        const categoryId = catResult.lastInsertRowId;
        categoryIdBySlug.set(cat.slug, categoryId);
        for (const [langCode, name] of Object.entries(cat.translations)) {
          await db.runAsync(
            'INSERT INTO category_translations (category_id, language_code, name) VALUES (?, ?, ?)',
            categoryId,
            langCode,
            name as string
          );
        }
      }

      for (const q of pack.questions) {
        const categoryId = categoryIdBySlug.get(q.category_slug);
        if (categoryId === undefined) continue;
        const qResult = await db.runAsync(
          `INSERT INTO questions (country_id, category_id, correct_answer, difficulty, image_path, active, content_version)
           VALUES (?, ?, ?, ?, ?, 1, ?)`,
          countryId,
          categoryId,
          q.correct_answer,
          q.difficulty,
          q.image_path ?? null,
          CONTENT_VERSION
        );
        const questionId = qResult.lastInsertRowId;
        for (const [langCode, t] of Object.entries(q.translations)) {
          await db.runAsync(
            `INSERT INTO question_translations
              (question_id, language_code, question_text, answer_a, answer_b, answer_c, answer_d, explanation)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            questionId,
            langCode,
            t!.question_text,
            t!.answer_a,
            t!.answer_b,
            t!.answer_c,
            t!.answer_d,
            t!.explanation
          );
        }
      }

      for (const sign of pack.roadSigns) {
        const categoryId = categoryIdBySlug.get(sign.category_slug);
        if (categoryId === undefined) continue;
        const signResult = await db.runAsync(
          'INSERT INTO road_signs (country_id, category_id, image_path, shape, color, active) VALUES (?, ?, ?, ?, ?, 1)',
          countryId,
          categoryId,
          sign.image_path ?? null,
          sign.shape,
          sign.color
        );
        const signId = signResult.lastInsertRowId;
        for (const [langCode, t] of Object.entries(sign.translations)) {
          await db.runAsync(
            `INSERT INTO road_sign_translations (road_sign_id, language_code, name, meaning, explanation)
             VALUES (?, ?, ?, ?, ?)`,
            signId,
            langCode,
            t!.name,
            t!.meaning,
            t!.explanation
          );
        }
      }

      const cfg = pack.examConfiguration;
      await db.runAsync(
        `INSERT INTO exam_configurations
          (country_id, number_of_questions, time_limit_seconds, passing_score, allowed_mistakes)
         VALUES (?, ?, ?, ?, ?)`,
        countryId,
        cfg.number_of_questions,
        cfg.time_limit_seconds,
        cfg.passing_score,
        cfg.allowed_mistakes
      );
    }

    await db.runAsync(
      `INSERT INTO user_settings (id, selected_country_code, selected_language_code, content_version)
       VALUES (1, NULL, NULL, ?)
       ON CONFLICT(id) DO UPDATE SET content_version = excluded.content_version`,
      CONTENT_VERSION
    );
  });
}
