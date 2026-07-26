# Content Authoring Guide — Theory Prep

This is what you hand to another AI (or a human researcher) to generate driving-theory content for a country. Each country is one JSON file at `TheoryPrep/Resources/Content/<country>/pack.json`. The app currently targets France only — see `TheoryPrep/Resources/Content/france/pack.json` as the reference example (languages: `fr`, `en`).

## Shape (this is the exact contract — field names matter)

```jsonc
{
  "country": { "code": "DE", "name": "Germany" },     // ISO-ish 2-letter code you choose, must be unique
  "languages": ["de", "en"],                            // local language first, then "en"
  "categories": [
    {
      "slug": "road_signs",                             // must match one of the fixed slugs below
      "translations": { "en": "Road Signs", "de": "Verkehrszeichen" }
    }
    // ... one entry per category, all 8 slugs below, translated into every language in "languages"
  ],
  "examConfiguration": {
    "number_of_questions": 30,      // real official exam question count
    "time_limit_seconds": 1800,     // real official time limit, in seconds
    "passing_score": 80,            // percentage needed to pass (0-100)
    "allowed_mistakes": 6           // real official max wrong answers allowed
  },
  "questions": [
    {
      "category_slug": "road_signs",             // must be one of the 8 fixed slugs
      "correct_answer": "b",                       // "a" | "b" | "c" | "d"
      "difficulty": "easy",                         // "easy" | "medium" | "hard"
      "translations": {
        "en": {
          "question_text": "...",
          "answer_a": "...", "answer_b": "...", "answer_c": "...", "answer_d": "...",
          "explanation": "..."   // must explain WHY, not just state the answer
        },
        "de": { "question_text": "...", "answer_a": "...", "answer_b": "...", "answer_c": "...", "answer_d": "...", "explanation": "..." }
      }
    }
    // repeat for every question — aim for 3+ per category, real accurate facts only
  ],
  "roadSigns": [
    {
      "category_slug": "road_signs",
      "shape": "circle",     // "circle" | "triangle" | "square" | "octagon" (used for the placeholder badge — see note below)
      "color": "#C8102E",     // hex color of the sign's dominant color
      "translations": {
        "en": { "name": "Stop", "meaning": "Come to a complete stop", "explanation": "..." },
        "de": { "name": "...", "meaning": "...", "explanation": "..." }
      }
    }
  ]
}
```

## The 8 fixed category slugs

Every country pack must use exactly these `category_slug` values (translated names differ, slugs don't):

`road_signs`, `priority_rules`, `speed_limits`, `parking_stopping`, `overtaking`, `motorways`, `alcohol_drugs`, `safety`

## Instructions for whatever AI/researcher builds the content

> "Research the official driving theory test for `<country>`. Produce a JSON file matching the schema in CONTENT_GUIDE.md exactly (same field names, same category slugs). Use only verified, current facts (speed limits, blood alcohol limits, exam question count/time limit/passing score) — cite where you're not fully certain rather than guessing. Write natural, accurate explanations for every question, not just 'because that's the rule.' Provide translations for every language listed in `languages`, including English."

## Adding a new country to the app once you have the JSON

1. Drop the file at `TheoryPrep/Resources/Content/<country>/pack.json`
2. Add `"<country>"` to the list in `TheoryPrep/Models/ContentPack.swift`, function `loadAllPacks()` (currently just `["france"]`)
3. Bump `contentVersion` in `TheoryPrep/Database/Schema.swift` by 1 (this forces the app to re-seed on next launch — otherwise your new content won't show up on a device that's already run the app once)
4. Rebuild (`xcodegen generate && xcodebuild ...` or just hit Run in Xcode)

## Images — the open question

The `image_path` field exists on both `questions` and `road_signs` but nothing populates it right now. Instead, road signs render as vector placeholder badges (colored shape from `shape`/`color`) via `RoadSignBadge.swift` — that's what you're seeing in the app today. That works fine as a placeholder but isn't the real sign artwork.

To wire in real images: drop image files under `TheoryPrep/Resources/Content/<country>/images/`, set `image_path` in the JSON to that relative path, and I'd add a check in the UI to show the real image when `image_path` is set, falling back to the badge when it's `null`.
