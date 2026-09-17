# Theory Prep (Prépa Code)

A native iOS app that helps people prepare for the French driving theory
test ("Code de la route"), studying in English or French. Built local-first:
all content and progress live in an on-device SQLite database, no backend
required.

## Documentation

Start with the [documentation index](docs/README.md). The
[image and question generation workflow](docs/SIGN_WORKFLOW.md) covers choosing
scenarios, avoiding duplicates, generating and reviewing images, and importing
questions into the app.

## Tech stack

- **Swift + SwiftUI**, targeting iOS 17+.
- **SQLite** (via `sqlite3`) — the local-first data store for content and
  user progress, accessed through a small hand-rolled query layer.
- No third-party dependencies, no backend, no accounts.

## Project structure

```
TheoryPrep/
  App/
    TheoryPrepApp.swift        Entry point (@main)
    RootView.swift              Splash → language selection → main app switch
    SplashView.swift            Launch screen
    Theme.swift                 "Quiet Wayfinding" design system: colors, spacing,
                                 radii, typography, motion, shared screen chrome
  Components/                   Shared UI primitives (CardView, PrimaryButton,
                                 GaugeRing, LaneDivider, RoadSignBadge, BundledImage)
  Views/                        One file per screen/flow (Home, Practice, Question,
                                 Exam intro/run/result, Mistakes, Progress, Road Signs)
  Views/Onboarding/             Language selection
  State/                        AppSettings (selected language) and TabRouter
                                 (tab navigation + deep-linkable learning routes)
  Database/                     Schema.swift, Seeder.swift, Queries.swift, Database.swift
  Models/                       DB row types (Models.swift) and JSON content pack
                                 shapes (ContentPack.swift)
  Localization/                 Strings.swift — UI chrome text in English + French
  Resources/Content/            Bundled JSON content packs + question/road-sign images
```

## Database (SQLite, local-first)

Schema in `TheoryPrep/Database/Schema.swift`: `countries`, `languages`,
`country_languages`, `categories`, `category_translations`, `questions`,
`question_translations`, `road_signs`, `road_sign_translations`,
`exam_configurations`, `user_question_progress`, `user_mistakes`,
`exam_results`, `exam_result_answers`, `user_settings`.

**Content vs. user data**: `Schema.contentVersion` controls re-seeding. On
launch, `Seeder.swift` checks the stored content version against this
constant; if it differs, content tables are wiped and re-imported from the
bundled JSON pack — but user data tables (`user_question_progress`,
`user_mistakes`, `exam_results`, `user_settings`) are never touched. Bump
`Schema.contentVersion` whenever the content pack changes.

## Content

Content lives in `TheoryPrep/Resources/Content/france/`, shaped by the
`ContentCountryPack` type in `Models/ContentPack.swift`: categories, road
sign categories, exam configuration, questions and road signs, each with
per-language (`en`/`fr`) translations. Currently only France is supported —
`CountryCode` is a single-case enum (`.FR`).

## Multi-language strategy

- **UI chrome** (buttons, nav labels, headings): `Localization/Strings.swift`,
  a flat dictionary keyed by `StringKey` with English/French values, resolved
  via `AppSettings.t(_:)`. Every key must provide both languages (enforced by
  a runtime precondition).
- **Content** (questions, answers, explanations, road signs, category names):
  stored per-language in SQLite translation tables, queried by the user's
  selected study language.

## Running the app

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```
xcodegen generate
open TheoryPrep.xcodeproj
```

Build and run the `TheoryPrep` scheme on an iPhone simulator or device
(iOS 17+).
