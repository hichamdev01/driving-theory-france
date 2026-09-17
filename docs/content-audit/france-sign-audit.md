# France sign-code audit

Audited 2026-09-13.

378 bundled questions (349 with images), 180 active catalogue entries, 179 observed/candidate codes. 133 codes have primary question mappings.

Scope: the current bundled France pack, the catalogue merged as ContentLoader merges it, and registered local quiz-card drafts. This does not query installed-device SQLite or retired questions. The app imports this content into local SQLite; the registry does not modify it.

All question texts/answers/explanations were inventoried. Code mappings use the learning target and reviewed descriptions; selected ambiguous images were inspected. This is not a full legal or visual QA certification of every image. Incidental background signs are not exhaustively labelled.

## Questions by app category

| Category | Questions |
| --- | ---: |
| alcohol_drugs | 36 |
| motorways | 27 |
| overtaking | 34 |
| parking_stopping | 33 |
| priority_rules | 37 |
| road_signs | 116 |
| safety | 62 |
| speed_limits | 33 |

## Findings and holds

- **wrong-right-turn-code (resolved):** Right-turn scene and explanation disagree on the code; B21-1, B21b and B21c1 held pending correction. `situation_mandatory_right`
  Resolved 2026-09-13: Corrected both languages to B21-1.
- **wrong-motorway-end-code (resolved):** Motorway-end image is C208, while explanation names C112. Both codes held pending correction. `situation_motorway_end`
  Resolved 2026-09-13: Corrected both languages to C208.
- **temporary-sign-background (resolved):** Worker sign uses a white background in a temporary works scene. Review AK5 rendering. `situation_roadworks`
  Resolved 2026-09-13: Replaced asset with visually reviewed yellow-background AK5.
- **ambiguous-obstacle-target (resolved):** J13-type marker and J5 island marker share the scene. Clarify the question target and directional explanation. `situation_obstacle_marker`
  Resolved 2026-09-13: Explicitly targets roadside J13 and distinguishes J5; removed wrong directional explanation.
- **car-scope-review (resolved):** A 3.6 m-high vehicle and explicit van driving need review against the ordinary-passenger-car scope. `situation_height_limit_3_5m` `situation_front_load_no_projection`
  Resolved 2026-09-13: Both questions now concern ordinary passenger cars; front-load image replaced.
- **catalogue-subtypes (resolved):** Nine C24 lane-diagram entries need visual subtype review. Generic light variants and selected contextual signs are also held in the registry.
  Resolved 2026-09-13: Inspected all nine diagrams and all flagged scene images; recorded confirmed signs or their absence.
- **a13b-already-generated (resolved):** A13b has an existing question plus a local unimported draft. Do not regenerate automatically. `danger_sign_pedestrian_crossing`
  Resolved 2026-09-13: Existing question and draft remain registered and blocked against repetition; neither is imported again.
- **bus-lane-legacy-filename (resolved):** The question teaches C6; B27a is only a comparison. Registry does not use the misleading filename as classification evidence. `situation_bus_lane`
  Resolved 2026-09-13: C6 mapping retained; comparison-only B27a remains excluded from this question coverage.
- **catalogue-is-not-car-allowlist (resolved):** Existing library includes specialist vehicle restrictions. Inventory preserves them; generation still requires a car-driver learning objective.
  Resolved 2026-09-13: Specialist entries remain reference inventory and are explicitly excluded from car generation.
- **bus-approach-image (resolved):** Original bus was ahead rather than approaching from the right. `situation_reserved_bus_lane_priority_right`
  Resolved 2026-09-13: Replaced image with right-side approach and aligned both-language text with the visible uncontrolled intersection.

## Repetition checks

- Exact duplicate question-content groups: 0.
- Exact reused-image groups: 0.
- Shared codes are existing coverage, not proof that two situations are identical.
- The manually listed scenario groups below identify overlap to review, not confirmed duplicates.
- SHA-256 detects exact repeated content/assets; it cannot recognize paraphrases or visually similar scenes.

- **slippery-road:** Same sign/hazard; compare learning objective before creating another scenario. `situation_slippery_rain`, `situation_slippery_road`, `danger_sign_slippery_road`
- **crosswind:** Same sign/hazard; recognition and action questions overlap without being exact duplicates. `situation_crosswind`, `situation_strong_crosswind`, `danger_sign_crosswind`
- **stop:** Two STOP approach situations already exist. `situation_stop`, `situation_stop_ab4_realistic`
- **no-overtaking:** B3 already has extent and basic restriction variants. `situation_no_overtaking`, `situation_no_overtaking_basic`
- **alcohol-general-limit:** Blood and breath versions address the same threshold concept in different units. `alcohol_general_limit`, `situation_breath_test_general_limit`
- **alcohol-probationary-limit:** Text and scene questions already cover the probationary threshold. `alcohol_probationary_limit`, `situation_breath_test_probationary_limit`
- **queue-hazard-lights:** Related warning-light actions in a sudden queue; compare before repeating. `situation_motorway_last_in_slow_queue`, `situation_hazard_lights_strong_slowdown`

## Code coverage

Existing category links come from question records. Suggested routes are authoring defaults and never move existing questions. Catalogue-only signs still require a passenger-car scenario review. A code with a review hold stays blocked even when it has another valid question.

| Code | Status | Primary questions | Suggested category |
| --- | --- | ---: | --- |
| A13a | covered | 3 | safety |
| A13b | covered | 1 | road_signs |
| A14 | covered | 2 | road_signs |
| A15a1 | covered | 2 | road_signs |
| A15a2 | covered | 1 | road_signs |
| A15b | covered | 3 | safety |
| A15c | covered | 1 | road_signs |
| A16 | covered | 2 | safety |
| A17 | covered | 2 | road_signs |
| A18 | covered | 2 | road_signs |
| A19 | covered | 3 | safety |
| A1a | covered | 2 | road_signs |
| A1b | covered | 1 | road_signs |
| A1c | covered | 2 | road_signs |
| A1d | covered | 2 | road_signs |
| A20 | covered | 2 | safety |
| A21 | covered | 2 | safety |
| A23 | covered | 2 | safety |
| A24 | covered | 3 | safety |
| A2a | covered | 2 | road_signs |
| A2b | covered | 2 | road_signs |
| A3 | covered | 1 | road_signs |
| A3a | covered | 2 | road_signs |
| A3b | covered | 1 | road_signs |
| A4 | covered | 3 | safety |
| A6 | covered | 1 | road_signs |
| A7 | covered | 2 | road_signs |
| A8 | covered | 2 | road_signs |
| A9a | covered | 1 | road_signs |
| A9b | covered | 2 | road_signs |
| AB1 | covered | 2 | priority_rules |
| AB2 | covered | 1 | priority_rules |
| AB25 | covered | 2 | priority_rules |
| AB3a | covered | 2 | priority_rules |
| AB4 | covered | 2 | priority_rules |
| AB6 | covered | 1 | priority_rules |
| AB7 | covered | 1 | priority_rules |
| AK14 | covered | 1 | road_signs |
| AK5 | covered | 1 | safety |
| B0 | covered | 1 | road_signs |
| B1 | covered | 1 | road_signs |
| B10a | catalogue_only | 0 | road_signs |
| B11 | covered | 1 | road_signs |
| B12 | covered | 2 | road_signs |
| B13 | catalogue_only | 0 | road_signs |
| B13a | catalogue_only | 0 | road_signs |
| B14 | covered | 5 | speed_limits |
| B15 | covered | 1 | priority_rules |
| B16 | covered | 1 | road_signs |
| B17 | covered | 1 | road_signs |
| B18a | catalogue_only | 0 | road_signs |
| B18b | catalogue_only | 0 | road_signs |
| B18c | catalogue_only | 0 | road_signs |
| B21-1 | covered | 1 | road_signs |
| B21-2 | catalogue_only | 0 | road_signs |
| B21a1 | covered | 1 | road_signs |
| B21a2 | catalogue_only | 0 | road_signs |
| B21b | covered | 1 | road_signs |
| B21c1 | covered | 1 | road_signs |
| B21c2 | catalogue_only | 0 | road_signs |
| B21d1 | covered | 1 | road_signs |
| B21d2 | catalogue_only | 0 | road_signs |
| B21e | covered | 1 | road_signs |
| B22a | covered | 1 | road_signs |
| B22b | covered | 1 | road_signs |
| B22c | covered | 1 | road_signs |
| B25 | covered | 1 | speed_limits |
| B26 | covered | 1 | safety |
| B27a | catalogue_only | 0 | road_signs |
| B27b | covered | 1 | road_signs |
| B29 | covered | 1 | road_signs |
| B2a | covered | 1 | road_signs |
| B2b | covered | 1 | road_signs |
| B2c | covered | 1 | road_signs |
| B3 | covered | 2 | overtaking |
| B30 | covered | 1 | speed_limits |
| B31 | covered | 1 | road_signs |
| B33 | covered | 1 | speed_limits |
| B34 | covered | 1 | overtaking |
| B34a | catalogue_only | 0 | overtaking |
| B35 | covered | 1 | road_signs |
| B39 | catalogue_only | 0 | road_signs |
| B3a | covered | 1 | overtaking |
| B4 | covered | 1 | road_signs |
| B40 | catalogue_only | 0 | road_signs |
| B41 | catalogue_only | 0 | road_signs |
| B42 | catalogue_only | 0 | road_signs |
| B43 | covered | 1 | speed_limits |
| B44 | covered | 1 | road_signs |
| B45 | covered | 1 | road_signs |
| B49 | covered | 1 | road_signs |
| B52 | covered | 1 | speed_limits |
| B53 | covered | 1 | speed_limits |
| B54 | covered | 1 | road_signs |
| B55 | covered | 1 | road_signs |
| B5a | catalogue_only | 0 | road_signs |
| B5b | catalogue_only | 0 | road_signs |
| B6a1 | covered | 2 | parking_stopping |
| B6a2 | covered | 1 | parking_stopping |
| B6a3 | catalogue_only | 0 | parking_stopping |
| B6d | covered | 1 | parking_stopping |
| B7a | catalogue_only | 0 | road_signs |
| B7b | covered | 1 | road_signs |
| B8 | covered | 1 | road_signs |
| B9a | catalogue_only | 0 | road_signs |
| B9b | covered | 1 | road_signs |
| B9c | catalogue_only | 0 | road_signs |
| B9d | catalogue_only | 0 | road_signs |
| B9e | catalogue_only | 0 | road_signs |
| B9f | catalogue_only | 0 | road_signs |
| B9g | catalogue_only | 0 | road_signs |
| B9h | catalogue_only | 0 | road_signs |
| B9i | catalogue_only | 0 | road_signs |
| C107 | covered | 1 | road_signs |
| C108 | covered | 1 | road_signs |
| C111 | covered | 2 | safety |
| C112 | covered | 1 | safety |
| C113 | covered | 1 | road_signs |
| C114 | covered | 1 | road_signs |
| C115 | covered | 1 | road_signs |
| C116 | covered | 1 | road_signs |
| C12 | covered | 1 | road_signs |
| C13a | covered | 1 | road_signs |
| C13b | covered | 1 | road_signs |
| C13c | covered | 1 | road_signs |
| C13d | catalogue_only | 0 | road_signs |
| C18 | covered | 2 | priority_rules |
| C1a | covered | 1 | parking_stopping |
| C1b | covered | 1 | parking_stopping |
| C1c | covered | 1 | parking_stopping |
| C207 | covered | 0 | motorways |
| C208 | covered | 1 | motorways |
| C20a | covered | 1 | road_signs |
| C20b | covered | 1 | road_signs |
| C20c | catalogue_only | 0 | road_signs |
| C23 | catalogue_only | 0 | road_signs |
| C24a | covered | 1 | road_signs |
| C24b | covered | 1 | road_signs |
| C24c | covered | 1 | road_signs |
| C26a | covered | 1 | road_signs |
| C26b | catalogue_only | 0 | road_signs |
| C27 | covered | 1 | road_signs |
| C28 | covered | 1 | road_signs |
| C29a | covered | 1 | road_signs |
| C29b | catalogue_only | 0 | road_signs |
| C29c | covered | 1 | road_signs |
| C30 | covered | 1 | road_signs |
| C4a | covered | 1 | speed_limits |
| C4b | covered | 1 | speed_limits |
| C5 | covered | 0 | parking_stopping |
| C50 | catalogue_only | 0 | road_signs |
| C51a | covered | 1 | road_signs |
| C51b | catalogue_only | 0 | road_signs |
| C6 | covered | 1 | road_signs |
| C62 | covered | 1 | motorways |
| C64a | covered | 1 | motorways |
| C64b | covered | 1 | motorways |
| C64c1 | catalogue_only | 0 | motorways |
| C64c2 | covered | 1 | motorways |
| C64d | covered | 1 | motorways |
| C8 | covered | 1 | road_signs |
| C9 | covered | 1 | parking_stopping |
| J13 | covered | 1 | road_signs |
| J4 | covered | 1 | road_signs |
| J5 | covered | 0 | road_signs |
| M11b2 | covered | 0 | road_signs |
| M2 | covered | 0 | road_signs |
| M4f | no_question_mapping | 0 | road_signs |
| M6h | no_question_mapping | 0 | parking_stopping |
| M6i | covered | 0 | parking_stopping |
| M9z | covered | 0 | road_signs |
| R11j | no_question_mapping | 0 | priority_rules |
| R11v | covered | 3 | priority_rules |
| R16td | covered | 1 | priority_rules |
| R21a | covered | 1 | safety |
| R21c | covered | 1 | safety |
| R24 | covered | 1 | priority_rules |
| SR4 | covered | 1 | road_signs |
| XB14 | covered | 1 | speed_limits |

## References

- [Cerema consolidated sign regulation](https://equipementsdelaroute.cerema.fr/IMG/pdf/arrete_du_24_novembre_1967_relatif_a_la_signalisation_des_routes_et_des_autoroutes_-_legifrance.pdf) — Code identity reference; right-turn and motorway/tunnel distinctions, marker and temporary-sign definitions. Consulted 2026-09-12/13.
- [Cerema illustrated sign catalogue, March 2024](https://equipementsdelaroute.cerema.fr/IMG/pdf/01-_panneaux_iisr_mars_2024_cle2191ef.pdf) — Visual nomenclature reference. Does not by itself define the passenger-car curriculum.
- [Code de la route, front load overhang](https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074228/LEGISCTA000006177086/2026-01-02) — Article R312-22: ordinary passenger-car front-load rule checked 2026-09-13.

See [registry usage](../../scripts/SIGN_REGISTRY.md) for commands, review updates and limitations.
