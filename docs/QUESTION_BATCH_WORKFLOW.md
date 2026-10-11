# Reviewed question batches toward 1,000

The approved expansion starts at 388 questions (359 illustrated). Add 61 batches
of ten and a final two, for 1,000 questions and 971 images. Keep the 29 existing
text-only drills. Do not commit, push, or publish as part of this workflow.

The native SwiftUI app already supports multiple answers and tells learners to
select one or all correct answers. A full batch contains eight single-answer
questions and two questions with multiple correct answers. The final two are
single-answer. Every question has four distinct options, French and English
wording and explanations. The original confidential ETG bank is not being copied.

## Responsibilities and coverage

Codex researches, writes original questions, generates individual scene images
with the built-in image tool, and inspects the actual outputs. This script is a
local state machine, not an unattended generator or an automatic visual/legal
certifier. It needs neither an image API key nor a backend. Saved state can be
resumed after interruption; it does not keep generating when the agent stops.

Consult public Ornikar examples for themes and style. Verify each rule using
current Légifrance, Service Public, Sécurité routière, or an original manufacturer
manual for vehicle-specific equipment. Save source URLs, checked dates and the
specific rule supported. Write original language rather than copying exercises.
Distinguish laws from recommendations and make all assumptions explicit.

Use the existing training blueprint proportions as final category targets:

| Category | Target |
| --- | ---: |
| road_signs | 200 |
| priority_rules | 125 |
| speed_limits | 100 |
| parking_stopping | 75 |
| overtaking | 100 |
| motorways | 75 |
| alcohol_drugs | 125 |
| safety | 200 |

These are our training allocations, not official examination quotas. Choose
underrepresented objectives and fill category deficits while varying categories
within each batch. Track `topic` separately so first aid, vehicle equipment,
environment, vulnerable users and driver responsibilities are not hidden by the
broad category names. A category target never justifies a repeated situation.

## Commands

Run commands from the repository root. All mutations share the existing sign
workflow lock and recoverable file journal. Do not concurrently edit content.

```sh
python3 scripts/question_batch.py status
python3 scripts/question_batch.py reserve expansion-001 --json proposals.json
python3 scripts/question_batch.py stage expansion-001 SCENARIO --image /absolute/path/scene.jpg --prompt exact-prompt.md
python3 scripts/question_batch.py review expansion-001 SCENARIO --json inspection.json
python3 scripts/question_batch.py import expansion-001
python3 scripts/question_batch.py verify expansion-001 --json verification.json
```

`reserve` takes an array of ten complete proposals, or two when the bank reaches
998. It also blocks expansion while the recorded baseline validation remains
unfinished. Authoring manifests live in `docs/content-audit/batch-jobs/`; generation
prompts and all staged image versions live in `assets-source/question-batches/`.
Do not manually set job states or create passing receipts before inspecting.

Each proposal supplies `scenario_id`, `scope: ordinary_passenger_car`,
`scope_review`, `learning_objective`, `topic`, `scenario`, `novelty_review`,
`image_prompt`, `sources`, optional `primary_codes`/`context_codes`, and `question`.
The question uses the existing pack schema, omitting media paths until import.
Prefer `correct_answers: ["a"]` or `["a", "c"]`; never supply both answer formats.
Supply `option_rationale.fr` and `.en`, each with a/b/c/d reasons. Each source has
`url`, `kind` (`official`, `manufacturer`, or `background`), `checked_on` (ISO date),
and `supports` (a concise paraphrase of the verified rule).

The official-source check recognises French government domains and the public
bodies Service Public, Assurance Maladie, ANSM, Cerema and UNECE. A recognised
domain is only an eligibility check: read the actual source, verify the relevant
conditions and date, and record unavailable material honestly. Manufacturer
sources must be original manuals or guidance from the relevant manufacturer.
Ornikar belongs in `background`, not `official`.

Prepared proposals may be saved before the baseline gate clears, but they are
not reservations or approvals. Keep their preflight report separate from batch
jobs and recheck them against the current bank when reserving. Resolve existing
semantic overlaps before claiming the final bank contains 1,000 unique
situations; zero exact hash duplicates is insufficient.

Reservation checks all current questions and pending jobs, repeats of scenario
IDs and normalized stems, exact content, passenger-car scope, and reserved or
covered sign codes. It saves the five nearest French stems for a further manual
novelty comparison. Similarity is a screening aid, not semantic certification:
read earlier objectives and answers too. A differently worded repeat must fail.

## Strict inspection and corrections

Save scene-only landscape PNG/JPEG files, at least 1000×560 and close to 16:9.
Stage only a generated candidate, not a contact sheet or placeholder. Inspect at
full resolution, zoom into relevant details, and check a phone-sized rendering.
The script checks image headers and dimensions; iOS tests must also decode media.

A review receipt contains the current `proposal_sha256` (canonical JSON SHA-256),
`image_sha256`, `result` (`pass` or `reject`), `notes`, and, for passing reviews,
`compared_question_keys` and specific observations under all ten `checks` keys:

- `official_rule`: conditions, date, source and legal obligation versus advice.
- `novelty`: how the decision differs from the nearest items and broader inventory.
- `signs_and_text`: every sign code, shape, colour, symbol, plate and legible word.
- `road_geometry`: lanes, markings, junctions, direction and perspective.
- `vehicles_and_people`: positions, lights, gestures, proportions and plausible movement.
- `dashboard_and_equipment`: controls, symbols, numbers, restraints and equipment.
- `full_resolution`: whole frame and detailed inspection of the final file.
- `phone_size`: useful clues remain visible without hidden details or misleading cropping.
- `french_and_english`: matching meaning, precise language and no unstated necessary facts.
- `all_four_options`: correct answer set and why each distractor is wrong.

Record a concrete observation even when an element is absent; do not manufacture
evidence. Review approval applies only to the exact proposal and staged bytes.
Changing either requires another complete inspection. Any unresolved ambiguity,
incorrect detail, or unreadable necessary clue blocks import.

For a failed image, record a rejection then stage an edited/generated candidate
with its exact prompt. Keep the old file. After the original plus three correction
attempts, replace the situation rather than weakening the gate:

```sh
python3 scripts/question_batch.py replace expansion-001 OLD_SCENARIO --json new-proposal.json --reason 'Specific unresolved problem and replacement objective'
```

Replacement preserves the abandoned proposal, images and inspections in history.
Revising the same scenario does not reset its attempt count. The batch must retain
its answer-format mix. Review means no detected unresolved defects, not a promise
that AI inspection cannot miss a mistake.

### Replacing repeated legacy situations without adding records

Use `reserve-replacements` for a batch of ten existing illustrated questions that
need genuinely different learning objectives. Each proposal keeps the exact old
`question.key`, supplies a `replacement_reason`, and otherwise follows the same
authoring schema, eight-single/two-multiple mix and review requirements:

```sh
python3 scripts/question_batch.py reserve-replacements legacy-repairs-001 --json replacements.json
```

This mode is available only after the preceding batch is verified. It archives
each original question, image and sign-review mapping before generation. The
usual `stage`, `review`, `replace`, `import` and `verify` commands then apply.
Replacing an unsuccessful candidate must also retain its original question key.
Covered sign codes remain blocked, and exact copies of the original question do
not qualify as replacements. Review must establish semantic novelty, including
comparison with other sign codes that teach the same decision.

Import replaces the ten records in place, preserves the full key order and total
question count, and advances the content version once. It rejects changes to the
original content, images or archived evidence, and retains safe retry/recovery.
The 29 text-only records cannot be selected by this mode. Original images remain
in the batch archive even if a bundled image is replaced. A repair batch does not
count toward the 612 additions and still requires all four integration evidence
records, including actual simulator review and progress comparison.

## Import and verification

Both explanations must contain at least 100 characters and a complete sentence,
matching the native content quality check. Reservation catches this before
generation. Add useful rule or safety context rather than filler.

Import requires every item to have a current passing review, rechecks duplicates,
and refuses a bank changed since reservation. It copies final images into bundled
content, appends all questions, source entries and sign mappings, then increments
the content version once. SQLite stores image paths; images are bundled files.
Existing question keys and progress are preserved. Repeating import is a no-op.

After each import:

```sh
python3 scripts/sign_registry.py verify
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
```

Run the current iOS tests, install/launch the simulator build, and check the
expected active question count, categories, translations, image decoding and
multiple-answer behaviour. Inspect all ten new questions on the simulator. Save
logs/screenshots/SQLite results in the batch evidence directory. Never mark tests
passed if access was denied or a run was interrupted.

`verify` takes the exact imported `pack_sha256`, `content_version`, and four
evidence records: `python_tests`, `ios_tests`, `sqlite_check`, `simulator_review`.
Each record requires `result: pass`, meaningful `notes`, a workspace-relative
`path`, and the SHA-256 of that existing evidence file. The script checks receipts,
not the truth of a fabricated inspection. Actual inspection is mandatory.

The next reservation is blocked until the preceding batch is verified. Stop on
failed checks, correct the problem and rerun affected checks before continuing.
If a write was interrupted, run `python3 scripts/question_batch.py recover`.
Recovery refuses conflicting user edits; reconcile them instead of overwriting.
Never delete the journal to bypass recovery. Stop at exactly 1,000, then save the
final count, category/topic coverage, source and validation report.

### Inspecting the actual app without changing practice history

In Debug builds, launch with `-ContentReviewKeys key1,key2` to open the real
question screen with a deterministic selection and canonical answer order.
The existing `-UITestLanguage fr` / `en` argument selects the review language.
This route exercises real answer selection and scoring but does not record
practice progress. It is unavailable in Release builds. Inspect every imported
item and test incomplete and complete multiple-answer sets. Restore the normal
launch and the user's language afterward.

Run `python3 scripts/verify_simulator_bank.py DATABASE` against the actual
simulator SQLite file before and after UI review. It checks the complete active
bank, translations, answers, categories, images, version and integrity using a
read-only connection, and reports a practice-history hash. Retain both results
and confirm that hash is unchanged. Find the current container after each test
installation; its UUID can change.

### Repairing wording after a failed integration check

An imported batch remains blocked until verification passes. For wording-only
repairs, prepare an array containing `scenario_id`, the full revised `proposal`,
a fresh complete `review` receipt and `reason`, then run:

```sh
python3 scripts/question_batch.py amend expansion-001 --json wording-amendments.json
```

This command only accepts an imported, unverified batch and preserves stable
keys, images, answer sets, categories and learning objectives. Every changed
proposal needs a new full inspection; old approvals cannot be reused. Previous
proposals and reviews are retained, the content version increases, and the
transaction is journalled. Exact retries do not increase the version again.
Rerun content and native tests and simulator checks on the amended bank before
verification. Image or objective replacements need a separately reviewed repair;
do not use this wording-only command to conceal those changes.
# Correcting an imported duplicate or defective scene

If a later review finds a defect, revoke its verification in the manifest with
the reason and retained prior evidence; keep the batch `imported` so expansion
cannot continue. Do not change a reviewed file silently. Author a different
objective when the defect is a semantic duplicate, retain the stable question
key, generate and inspect a new image, and save a fresh complete review receipt.

`python3 scripts/question_batch.py repair BATCH --json REVISION.json` installs
an exact-hash replacement in the latest imported bank. The revision contains
`repair_id`, original `scenario_id`, `previous_question_sha256`, `reason`, new
`proposal`, batch-relative `image_path`, and `review`. It preserves keys/counts
and the 8/2 mix, records the prior proposal/image/review, bumps the content version,
and invalidates integration verification. The shared journal supports interrupted
imports and identical retries. Run all batch integration checks again before
marking it verified. Retain rejected generation candidates and exact edit prompts.

Novelty comparisons must cover all categories, not just the destination category.
The retrieval helper weights distinctive words from both translations and
explanations; its five suggestions are only a starting point for manual review.
R16 family/variant coverage is checked together to prevent a family code bypassing
an existing directional-signal question.
