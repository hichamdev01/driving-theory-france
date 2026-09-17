# Flagged content corrections — 13 September 2026

Resolved all 18 flagged/candidate question reviews and nine catalogue subtype
reviews from the initial sign-code audit. The registry has no remaining code
holds. Historical findings remain in the review file with their resolutions.

| Item | Correction |
| --- | --- |
| Right turn | Both explanations identify B21-1 and a turn before the sign. |
| End of motorway | Both explanations identify C208 instead of C112. |
| Roadside marker | Question explicitly targets the tall striped marker; explanation distinguishes J13 from the separate J5 island marker and removes the invented chevron/direction claim. |
| Height restriction | Reframed around total passenger-car height with a roof box, retaining the pictured 3.5 m restriction. |
| Front load | Van replaced with a passenger estate car; question refers to a car. Removed the inaccurate measurement overlay and numerical claim. |
| Roadworks | Replaced the white-background worker sign with yellow-background AK5. |
| Bus priority | Replaced the oncoming-bus scene with a bus approaching from the right. Both languages now describe the visible uncontrolled intersection without assuming an unseen reserved lane. |
| Other scene mappings | Confirmed visible signs and ordinary R11v signals. Ground markings alone no longer imply M6h or B27a coverage. |
| Catalogue diagrams | Entries 021–025 are C24a, 026–027 are C24b, and 028–029 are C24c. Names in both languages now include the reviewed code. |
| Specialist catalogue | Kept as reference inventory, explicitly excluded from automatic passenger-car generation where previously flagged. |

The pack still contains 297 questions in the same categories. All stable keys
and correct-answer positions were preserved. Six question translation records
and three scene images changed. Content version increased from 35 to 36 so
the existing stable-key seeder updates installed content on the next app launch.
No progress tables were edited directly.

The three replacement images were generated with the built-in image tool,
visually inspected, and converted to JPEG in the existing bundled asset paths:

- `situation_roadworks.jpg`: change sign background to yellow; retain the roadworks scene.
- `situation_front_load_no_projection.jpg`: passenger estate car with roof-secured timber projecting forward; no measurement overlay.
- `situation_reserved_bus_lane_priority_right.jpg`: bus on the right-hand cross street, facing left into the intersection; no priority controls.

The [review decisions](france-sign-review.json) bind these resolutions to the
current record and image hashes. The [registry](france-sign-registry.json) and
[audit report](france-sign-audit.md) were rebuilt. Existing A13b coverage and its
unimported draft remain blocked against repetition.

Validation: all 26 iOS tests passed on the iPhone 17 Pro simulator, all 17
Python registry tests passed, registry freshness verification passed, and
`git diff --check` reported no whitespace errors. A comparison with the
pre-correction pack confirmed identical question keys, categories, and answer
positions. These checks do not constitute a new full legal audit of the bank.

References checked: [Cerema consolidated sign definitions](https://equipementsdelaroute.cerema.fr/IMG/pdf/arrete_du_24_novembre_1967_relatif_a_la_signalisation_des_routes_et_des_autoroutes_-_legifrance.pdf),
[Code de la route loading provisions](https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074228/LEGISCTA000006177086/2026-01-02).
