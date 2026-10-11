# Expansion checkpoint — 11 October 2026

## Current state

- Goal: 1,000 passenger-car questions, 971 with images.
- Actual bank: **478 questions / 449 images / 24 multiple-answer questions**.
- Remaining: **522 questions**, 52 ten-item batches and final two.
- Content version: **102**. Expansion batches `expansion-001` through `expansion-008` verified; `expansion-009` imported with simulator review incomplete.
- Expansion paused by the user during batch 009 simulator review. The user subsequently authorized committing and pushing all current work to `main`. This does not resume expansion or approve a store release.

## Implemented

- `scripts/question_batch.py`: resumable reservation, versioned candidate images
  and prompts, exact-hash review receipts, structured ten-point inspection,
  nearest-question comparison, 8/2 answer mix, retry/replacement policy, all-items
  import, version bump, shared recovery journal, source audit and verification
  gate. The next batch cannot begin before the previous batch is verified.
- Sign registry now includes batch reservations and staged image fingerprints.
- Single-sign workflow now supports multiple correct answers.
- Operator documentation: `docs/QUESTION_BATCH_WORKFLOW.md`.
- 52 Python tests passed; current output is `assets-source/question-batches/expansion-007/python-tests.log`. Registry and
  whitespace checks passed after the latest corrections.
- Added native integration test for matching the full seeded bank to bundled
  questions and answer sets, preserving IDs/progress through a content-version
  update, and decoding all image assets. **All 36 native tests passed, including the new test.**

## Previous batch recheck

All ten September 21 images were inspected again. Three items were corrected:

1. Parking disc: added the C1a P symbol, corrected ten-minute graduations and
   exterior-view steering placement. Inspected at full size and 390px width.
2. Reversing camera: removed malformed peripheral instrument numbers by
   reframing the generated photograph. Inspected at full size and 390px width.
3. Traffic officer: the new officer-versus-green question repeated an older
   objective. It now asks which approaches stop for horizontal arms. New original
   scene shows both arms clearly, with four options and one correct answer in
   both languages. Historical question key retained; source and review metadata
   updated. The older question still teaches precedence over traffic lights.

Corrected assets, proposals and old candidates are retained under the existing
`assets-source/balanced-batch-2026-09-21/` folder. The original batch's import
version remains 89; its follow-up correction record points to version 91.
The bank has no exact duplicate content or image hashes. Existing related-topic
groups remain a manual novelty reference, not proof of complete semantic uniqueness.

## Baseline cleared and current work

The simulator permission blocker was resolved on 9 October. Current v91 and
review-route builds both passed all 36 iOS tests. All ten September 21 questions
were inspected in the actual simulator and answered correctly. A multiple-answer
question was also tested in French with an incomplete set (incorrect) and in
English with the complete set (correct). SQLite matches every bundled question,
translation, category, media path and answer set. The practice-history hash was
unchanged across review sessions. Evidence files: `baseline-ios-v91.log`,
`baseline-ios-review-route.log`, `baseline-sqlite-after-review.json` and
`baseline-simulator-review.json`. `baseline.json` is now verified.

The development-only `-ContentReviewKeys key1,key2` launch argument opens the
real question UI without writing practice history, enabling deterministic batch
inspection. `scripts/verify_simulator_bank.py DATABASE` verifies the actual
simulator database read-only. Both are available for subsequent batches.

The selected simulator is iPhone 17 Pro,
`B49BFA96-2E2B-4EBD-BF84-0860E2C2FD3B`, iOS 26.5. Build directory:
`/tmp/TheoryPrepExpansionDerivedData`.

Expansion batch `expansion-001` is verified: ten original illustrated questions,
eight single-answer and two multiple-answer, across all eight categories. Four
images needed corrections. Every final file passed full-size and 390px review,
then actual app inspection. Native testing caught two short English explanations;
a fresh hash-bound review and journalled wording amendment repaired them before
verification. Version92 was the initial import; version93 contains those repairs.
All47 Python and36 native tests pass. SQLite matches the complete398-question
bank, and actual UI review preserved the practice-history hash. Evidence and
receipts are in `assets-source/question-batches/expansion-001/evidence/`.
The workflow now catches minimum explanation length before generation and offers
an audited, idempotent wording-only repair for imported unverified batches.

`semantic-review-queue.json` also records an existing A3a pair with the same
objective and the remaining related groups. Resolve confirmed overlaps while
preserving stable keys before claiming 1,000 unique situations.

Expansion batch `expansion-002` is verified on 10 October: ten additions, eight single-answer and two multiple-answer, all eight categories. Four original images and one tunnel replacement were rejected and corrected. All 47 Python and 36 native tests pass. All ten French question screens were inspected and scored; English multiple-answer scoring and the longest question were checked. The complete 408-question SQLite bank matches version 94, and the practice-history hash remains unchanged. Evidence: `assets-source/question-batches/expansion-002/evidence/`.

Expansion batch `expansion-003` is verified: ten additions across six categories, with five equipment/driver-responsibility questions addressing neglected topics. Three candidate images were rejected. All 47 Python and 36 native tests pass; all ten French screens and three English items were inspected. The 418-question SQLite bank matches version 95 and practice history is unchanged. Evidence: `assets-source/question-batches/expansion-003/evidence/`.

Expansion batch `expansion-004` is verified: ten additions across all eight categories. Four candidate images were rejected. All 47 Python and 36 native tests pass. French and English simulator checks found and repaired singular wording in multiple-answer feedback; the corrected plural label was verified in both languages. SQLite matches all 428 questions at version 96 and practice history is unchanged. Evidence: `assets-source/question-batches/expansion-004/evidence/`.

Select and research `expansion-005`; the preceding batch is verified. Generate
one image per item, inspect every detail and follow the same import/verification gate.
Do not describe the 1,000-question goal as achieved until all 612 additions and
their required checks are complete. No commits, pushes or releases are authorized.

## Reopened validation

Expansion004 verification revoked: wider whole-bank comparison found the R16 item repeats `situation_yellow_arrow_red_light_turn` (R16td). The previous lexical nearest-question list missed it. Replace the new item while preserving its stable key, and reverify. No next batch may start meanwhile.

The reopened defect is now repaired and reverified at version97. The retained key now displays a new pregnancy seat-belt routing question (two correct answers); an extra outboard buckle in its first image was rejected and corrected. Both languages and complete/incomplete answer sets were checked in the simulator. All52 Python and36 native tests pass; full SQLite matches and history is unchanged. Evidence and final receipt: `assets-source/question-batches/expansion-004/verification-repair.json`. Continue expansion005.

## Expansion005 verified

438questions,409illustrated,29text-only; content version98.52workflow tests and36native tests passed. All10French questions reviewed in simulator; English incomplete multiple-answer sets rejected correctly. Saved history unchanged. Arrow candidate rejected after3corrections and replaced by routine oil-level measurement. Report: assets-source/question-batches/expansion-005/batch-report.md.562remain; continue expansion006.

## Expansion006 verified

448 questions,419 illustrated,29 text-only; content version99. All52 workflow and36 native tests passed. All ten French questions and both English multi-answer partial selections checked in simulator; SQLite matches the bank and practice history is unchanged. Cycle-box candidate replaced after three unsuccessful corrections. Report: `assets-source/question-batches/expansion-006/batch-report.md`.552 additions remain; select expansion007.

## Expansion007 verified

458 questions,429 illustrated,29 text-only; content version100. All52 workflow and36 native tests passed. All ten French questions and both English multi-answer partial selections checked in simulator; SQLite matches and history unchanged. Report: `assets-source/question-batches/expansion-007/batch-report.md`.542 additions remain; expansion008 is being authored.

## Expansion008 verified — 2026-10-11

468 questions,439 illustrated,29 text-only; content version101. All52 workflow and36 native tests passed. Ten French simulator reviews and two English incomplete multiple-answer checks passed. Saved progress and unrelated starting files unchanged.532 additions remain. See assets-source/question-batches/expansion-008/batch-report.md and verification.json.

## Expansion009 imported — 2026-10-11

478 questions,449 illustrated,29 text-only; content version102. All ten final
images and bilingual questions passed exact-file review after eight image
corrections. All52 workflow and36 native tests passed; simulator SQLite matches
the bank and saved progress is unchanged. Visual simulator review is pending:
computer-use reports the Mac is locked; user asked to unlock. No batch verification
or next reservation yet. Resume from expansion009/validation-pending.json.
522 additions remain. Legacy semantic queue now has six confirmed open groups.

## Legacy audit and repair workflow prepared — 2026-10-11

Reviewed the full bilingual wording/options/explanations for all32 preflagged
shared-code groups. There are now18 confirmed open semantic-overlap groups;
separate weaker applied objectives and wording issues remain recorded for repair.
Evidence: legacy-sign-comparisons-2026-10-11.json and semantic-review-queue.json.
This is a semantic audit, not a fresh legal/visual approval of old images.

Added reserve-replacements mode: ten reviewed new situations replace existing
illustrated records in place, with original content/image archives and stable
question keys. It preserves the text-only bank, count, retries and all review
gates.59 workflow tests pass, including seven new repair tests. Evidence:
legacy-replacement-workflow-validation.json. No legacy repair has been reserved
or imported. Bank remains478/version102, and expansion009 still awaits simulator
visual review after the Mac is unlocked.

## User pause and repository consolidation — 2026-10-11

The Mac was unlocked and French simulator questions 1–3 of expansion009 were inspected and answered correctly. Review stopped at question 4 when the user asked to pause. Questions 4–10 and English incomplete multiple-answer checks remain pending; no batch verification is claimed. The old lock message above records the earlier blocker.

The user then authorized committing, pushing and consolidating branches into the default branch. Both `feature/premuim` and the previously pushed `codex/expand-france-question-bank` are already ancestors of remote `main`; their committed content needs no separate merge. Current work includes the question bank/workflow plus existing home-screen and random-practice changes. The 18 open semantic-overlap groups remain unresolved and preserved in the audit trail.
