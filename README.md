# Theory Prep — Multilingual Driving Theory Preparation App

MVP mobile app that helps people prepare for driving theory tests in Portugal, France, and Spain, studying in the local language or in English. Built local-first: all content and progress live in an on-device SQLite database, no backend required.

## Tech stack

- **React Native + Expo (SDK 57), TypeScript** — single codebase for iOS and Android, fast iteration, large ecosystem.
- **expo-sqlite** — on-device SQLite database (async API), the local-first data store for content and user progress.
- **React Navigation** (native-stack + bottom-tabs) — app navigation.
- **@expo/vector-icons** — tab bar iconography.

No backend, no cloud database, no accounts — matching the MVP requirement to keep the product free to run and offline-capable.

## Project structure

```
App.tsx                     Entry point: providers (SQLite, navigation, settings) + suspense boundary
src/
  db/
    schema.ts                CREATE TABLE statements (SQLite schema)
    seed.ts                  Imports content/*.json packs into SQLite
    init.ts                  Runs schema + seed on first launch / content version bump
    queries.ts                All read/write query functions used by screens
  content/
    portugal/pack.json        Categories, questions, road signs, exam config (pt + en)
    france/pack.json          Categories, questions, road signs, exam config (fr + en)
    spain/pack.json           Categories, questions, road signs, exam config (es + en)
  context/
    AppSettingsContext.tsx    Selected country/language, UI translation helper t()
  i18n/
    strings.ts                UI chrome text (nav labels, buttons) in en/pt/fr/es
  navigation/
    RootNavigator.tsx         Onboarding vs. main app switch
    MainTabs.tsx               6-tab bottom navigator (Home, Practice, Exam, Signs, Mistakes, Progress)
    types.ts                   Typed navigation param lists
  screens/                    One file per screen (see below)
  components/                 Shared UI primitives (Card, PrimaryButton, ScreenContainer, RoadSignBadge)
  theme/colors.ts              Color palette
  types/index.ts               Shared TypeScript types (DB rows + content pack shapes)
```

## Database (SQLite, local-first)

Schema in `src/db/schema.ts`, matching the PRD's suggested structure with two additions:
- `category_translations` — category names are translated per study language (the PRD listed categories as a flat table, but names must localize).
- `country_languages` — join table mapping which languages are offered per country, so the language-selection screen is data-driven instead of hardcoded per country.

Tables: `countries`, `languages`, `country_languages`, `categories`, `category_translations`, `questions`, `question_translations`, `road_signs`, `road_sign_translations`, `exam_configurations`, `user_question_progress`, `user_mistakes`, `exam_results`, `exam_result_answers`, `user_settings`.

**Content vs. user data**: `CONTENT_VERSION` in `schema.ts` controls re-seeding. On launch, `init.ts` checks `user_settings.content_version` against the code constant; if it differs, all *content* tables (countries, categories, questions, road signs, exam config) are wiped and re-imported from the JSON packs — but user data tables (`user_question_progress`, `user_mistakes`, `exam_results`, `user_settings.selected_*`) are never touched. Bump `CONTENT_VERSION` whenever you edit the JSON content packs to ship the update.

## Content architecture — adding a country

Each country is one JSON file under `src/content/<country>/pack.json`, shaped by the `CountryContentPack` type in `src/types/index.ts`:

```json
{
  "country": { "code": "DE", "name": "Germany" },
  "languages": ["de", "en"],
  "categories": [{ "slug": "road_signs", "translations": { "en": "Road Signs", "de": "..." } }],
  "examConfiguration": { "number_of_questions": 30, "time_limit_seconds": 1800, "passing_score": 80, "allowed_mistakes": 6 },
  "questions": [ /* correct_answer, difficulty, translations per language */ ],
  "roadSigns": [ /* shape, color, translations per language */ ]
}
```

To add a new country: create the pack, import it in `src/db/seed.ts` (`CONTENT_PACKS` array), add its language(s) if new, bump `CONTENT_VERSION`. No screen or navigation code changes needed — country and language pickers, categories, practice, exam, and road signs are all data-driven from this file.

The logical question / translation split from the PRD (one question, many `question_translations` rows) is preserved so a question's correct answer and metadata are defined once, with per-language text alongside it.

## Multi-language strategy

- **UI chrome** (buttons, nav labels, headings): `src/i18n/strings.ts`, a flat dictionary keyed by string id with en/pt/fr/es values, resolved via `useAppSettings().t(key)`.
- **Content** (questions, answers, explanations, road signs, category names): stored per-language in the SQLite translation tables, queried by the user's selected study language — independent from the selected country, exactly as the PRD requires (e.g. Country: Portugal, Study Language: English).

## Image assets

The PRD calls for local image assets referenced by path (not stored as SQLite blobs). The schema already has `image_path` columns on `questions` and `road_signs` for this. For the MVP prototype, road signs are rendered as vector placeholder badges (`src/components/RoadSignBadge.tsx` — colored circle/triangle/diamond/rounded-octagon shapes) rather than shipping licensed sign artwork. To swap in real images: drop files under `assets/images/<country>/road_signs/` and `assets/images/<country>/questions/`, populate `image_path` in the content JSON packs, and render `<Image source={{ uri: ... }} />` where `image_path` is non-null (falling back to `RoadSignBadge` when it's null).

## Not yet implemented (flagged, not silently skipped)

- **Advertising (AdMob)**: requires a real AdMob account and app/ad-unit IDs, which can't be fabricated without breaking the build. The MVP UI has natural breakpoints ready for it (practice/exam completion screens) — wiring `react-native-google-mobile-ads` in is the next step once ad unit IDs exist.
- **Analytics**: no analytics SDK wired in yet; recommend Expo's `expo-application` + a privacy-conscious provider (e.g. PostHog or Amplitude) once decided.
- **App icons / splash**: using Expo's default placeholder icons.

## Running the app

```
npm install
npx expo start          # then press i (iOS), a (Android), or scan the QR code with Expo Go
```
