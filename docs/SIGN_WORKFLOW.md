# Image and question generation workflow

Use this process to add French driving-theory questions for ordinary
passenger-car learners (permis B). Every new image belongs to a complete
French/English question with four distinct options, one correct answer and an
explanation.

## End-to-end process

1. **Choose the learning objective.** Start with a sign code or a driving
   situation. For batches, count the existing questions per category and favour
   underrepresented categories while keeping each question in the category that
   matches its objective.
2. **Check for duplicates before generation.** Verify the registry, inspect
   existing questions, drafts and pending jobs, and compare the proposed
   situation with earlier learning objectives. Different wording or a different
   image does not make a repeated situation new. For sign jobs, reserve the code
   using the commands below.
3. **Verify the rule.** Consult current authoritative references, confirm any
   sign code and pictogram, and save the source URLs with the proposal. Keep the
   learner's role within ordinary passenger-car driving.
4. **Write the question first.** Save a stable scenario ID, category, French and
   English question, four options, the correct answer and explanations. State
   relevant facts that a still image cannot establish in the question itself.
5. **Generate and save the image.** Save the exact prompt and create a realistic
   landscape driving scene using the built-in image tool. The
   [original quiz-card prompt](QUIZ_CARD_IMAGE_PROMPT.md) supplies visual guidance;
   for the app, generate the scene alone, without a quiz panel or highlighted
   answer, because SwiftUI renders the question and options separately.
6. **Review the complete question.** Inspect the actual image, signs, lane
   geometry, vehicle positions and agreement with both translations and all
   answers. Correct problems, inspect replacements, and record the review
   against the final image bytes and question.
7. **Integrate the reviewed content.** Add the question to the France pack in
   the correct category, copy the image into bundled content, and set its
   `image_path`. Preserve existing stable keys and update the content version.
   The app imports the pack into local SQLite; images remain bundled files
   referenced by the database, rather than image BLOBs.
8. **Update the registry and validate.** Save mappings, source references and
   review receipts, rebuild and verify the registry, run the relevant content
   checks and iOS tests, and verify the imported questions and images in the app.

## Sign codes and general scenarios

The CLI below supports **one sign-code job at a time**. General driving
scenarios and balanced batches follow the same review process, but do not yet
have a reusable batch-import CLI. Do not invent sign codes to fit the script.
Record general-rule objectives as `no_sign_target`, with reviewed contextual
sign codes where relevant.

The [completed 30-scenario batch](content-audit/france-balanced-batch-2026-09-16.md)
shows category allocation, prompts, proposals, corrections and verification
receipts. Its [manifest](../assets-source/balanced-batch-2026-09-16/manifest.json)
is a concrete example for planning future batches. See the
[registry guide](../scripts/SIGN_REGISTRY.md) for coverage and review rules.

## Sign-code tooling

This local workflow supports one reviewed passenger-car situation per sign code.
Codex verifies the reference, writes the bilingual question and image prompt,
uses the built-in image tool, and inspects the result. Python handles reservations,
validation, import and registry refresh. It does not require an API key or a backend.
It is a Codex-assisted workflow, not an unattended image-generation service.

### Run for a sign code

Ask Codex: **“Run the sign-question workflow for CODE.”** Codex should:

1. Run `python3 scripts/sign_registry.py verify` and inspect the code's coverage.
   Stop if the code has existing questions, drafts, pending jobs, review holds,
   or an excluded car scope. A catalogue entry alone is not a question.
2. Check authoritative sign references and nearby existing learning objectives.
   Write `assets-source/sign-workflow/CODE/proposal.json`, following the B15
   example. Include an exact code, stable scenario ID, novelty and car-scope
   review, references, image prompt, and a complete French/English question.
   The category must match the registry's reviewed route; do not invent a route.
3. Reserve before generating:

   ```sh
   python3 scripts/sign_workflow.py reserve CODE --proposal assets-source/sign-workflow/CODE/proposal.json
   ```

4. Generate a scene-only image with the built-in image tool, following the
   proposal's `image_prompt` and the imagegen skill. The app renders the answers
   separately; never import an answer-bearing quiz card as the question image.
   Inspect the actual sign, arrow directions, vehicle positions and road geometry.
5. Stage the selected PNG/JPEG and record the actual review:

   ```sh
   python3 scripts/sign_workflow.py stage CODE --image /absolute/path/to/scene.jpg
   python3 scripts/sign_workflow.py review CODE --note 'Specific visual, language, answer, category and source checks performed.'
   ```

6. Import and verify:

   ```sh
   python3 scripts/sign_workflow.py import CODE
   python3 scripts/sign_registry.py verify
   python3 -m unittest discover -s scripts/tests -p 'test_sign*.py'
   ```

   Run the existing iOS content tests after changing the bundled bank. Record the
   source review in the question-source audit when needed.

### What the script guarantees

- A shared process lock serializes workflow writes in this checkout. Pending jobs
  appear in registry lookups immediately, before image generation starts.
- Source changes invalidate a stale registry. Import rechecks existing code
  coverage, destination/key collisions and exact duplicate images/question text.
- Review binds to the proposal and staged image hash. Restaging an image clears
  the review. The review note records an actual inspection; the script does not
  itself certify visual or legal correctness.
- Import appends one question, copies the scene into bundled content, adds its
  reviewed sign mapping, increments `Schema.contentVersion`, and marks the job
  imported. Existing stable keys are preserved. The app's seeder subsequently
  imports it into local SQLite without deleting progress.
- Repeating import returns `already_imported` and does not increment the version
  or add another question. Repeating reserve never generates another job.
- Writes are individually atomic and covered by a durable recovery journal.
  They are not one filesystem-wide atomic transaction. If interrupted, other
  workflow operations stop until `python3 scripts/sign_workflow.py recover`
  completes the saved transaction. Recovery refuses conflicting user edits.

Keep concurrent content editing/builds separate from import. The lock coordinates
this workflow; it cannot lock arbitrary editors or other import scripts.

### Resume a job

Jobs live in `docs/content-audit/sign-jobs/CODE.json`; inspect `state`:

- `reserved`: generate or select its image; do not reserve again.
- `staged`: inspect the image, or stage a corrected replacement, then review.
- `reviewed`: import, or stage a replacement and review again.
- `imported`: finished; do not regenerate.

The reserved proposal is stored inside the job; modifying the original proposal
file later does not change that reservation. There is no automatic cancellation,
expiry, variant override or batch mode yet. Leave failed jobs reserved until
deliberately reconciled so a retry cannot silently spend another generation.

Scenario IDs catch exact repeated registered situations. The `novelty_review`
also compares earlier questions whose wording or sign differs. These checks do
not provide automatic semantic similarity detection.

### First completed run

B15 is saved as `situation_b15_yield_oncoming_bridge` in `priority_rules`.
Its proposal and prompt are under `assets-source/sign-workflow/B15/`, its receipt
is `docs/content-audit/sign-jobs/B15.json`, and its bundled image is
`TheoryPrep/Resources/Content/france/images/situation_b15_yield_oncoming_bridge.jpg`.
It was generated with the built-in image tool and imported at content version 37.

Pilot validation: 27 Python workflow/registry tests and 26 iOS tests passed.
A repeated import returned `already_imported`; at the end of that pilot, the bank
contained exactly one B15 question and 298 questions overall. Registry freshness
and whitespace checks also passed.
