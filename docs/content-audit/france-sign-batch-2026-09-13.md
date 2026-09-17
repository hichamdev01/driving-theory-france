# French car-sign batch — 13 September 2026

Ten scene images generated with the built-in image-generation tool, visually reviewed against the existing sign references, and imported with French and English questions. All 298 previous questions are unchanged; the pack now contains 308 questions at content version 47.

| Code | Category | Image | Saved prompt | Import receipt |
| --- | --- | --- | --- | --- |
| B17 | road_signs | [Image](../../TheoryPrep/Resources/Content/france/images/situation_b17_minimum_gap_70m.jpg) | [Prompt](../../assets-source/sign-workflow/B17/prompt.md) | [Receipt](sign-jobs/B17.json) |
| B21b | road_signs | [Image](../../TheoryPrep/Resources/Content/france/images/situation_b21b_straight_at_junction.jpg) | [Prompt](../../assets-source/sign-workflow/B21b/prompt.md) | [Receipt](sign-jobs/B21b.json) |
| B16 | road_signs | [Image](../../TheoryPrep/Resources/Content/france/images/situation_b16_no_horn_rural.jpg) | [Prompt](../../assets-source/sign-workflow/B16/prompt.md) | [Receipt](sign-jobs/B16.json) |
| C1b | parking_stopping | [Image](../../TheoryPrep/Resources/Content/france/images/situation_c1b_parking_disc_control.jpg) | [Prompt](../../assets-source/sign-workflow/C1b/prompt.md) | [Receipt](sign-jobs/C1b.json) |
| B6a2 | parking_stopping | [Image](../../TheoryPrep/Resources/Content/france/images/situation_b6a2_no_parking_first_half_month.jpg) | [Prompt](../../assets-source/sign-workflow/B6a2/prompt.md) | [Receipt](sign-jobs/B6a2.json) |
| C4b | speed_limits | [Image](../../TheoryPrep/Resources/Content/france/images/situation_c4b_end_advisory_70.jpg) | [Prompt](../../assets-source/sign-workflow/C4b/prompt.md) | [Receipt](sign-jobs/C4b.json) |
| B43 | speed_limits | [Image](../../TheoryPrep/Resources/Content/france/images/situation_b43_end_minimum_30.jpg) | [Prompt](../../assets-source/sign-workflow/B43/prompt.md) | [Receipt](sign-jobs/B43.json) |
| C13c | road_signs | [Image](../../TheoryPrep/Resources/Content/france/images/situation_c13c_dead_end_pedestrian_exit.jpg) | [Prompt](../../assets-source/sign-workflow/C13c/prompt.md) | [Receipt](sign-jobs/C13c.json) |
| C64b | motorways | [Image](../../TheoryPrep/Resources/Content/france/images/situation_c64b_toll_bank_card_payment.jpg) | [Prompt](../../assets-source/sign-workflow/C64b/prompt.md) | [Receipt](sign-jobs/C64b.json) |
| C112 | safety | [Image](../../TheoryPrep/Resources/Content/france/images/situation_c112_tunnel_exit.jpg) | [Prompt](../../assets-source/sign-workflow/C112/prompt.md) | [Receipt](sign-jobs/C112.json) |

Each receipt binds the reviewed question and scene image by hash. Retrying all ten imports returned `already_imported` and left the pack and content version unchanged. The existing content seeder loads the new bundled questions and image references into local SQLite when the updated app launches.

Validation: all 27 Python workflow/registry tests and all 26 iOS simulator tests passed. Registry verification and `git diff --check` passed. No commit or push performed.

Installed and launched the tested build in the iPhone 17 Pro simulator. Read-only SQLite verification confirmed content version 47 and all ten new questions active exactly once, with the expected categories and bundled image paths.
