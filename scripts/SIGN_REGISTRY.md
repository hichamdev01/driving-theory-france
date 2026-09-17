# France sign-code registry

The registry is the first authoring step for ordinary passenger-car questions.
It inventories the bundled content which `ContentLoader` imports into local
SQLite. It does not change the pack, images, database, or user progress.

Run from the project directory, using Python 3 and its standard library:

```sh
python3 scripts/sign_registry.py verify
python3 scripts/sign_registry.py check A13b
python3 -m unittest discover -s scripts/tests -p 'test_sign_registry.py'
```

`check A13b` returns `skip_existing`, its question key and its local draft ID.
Case and whitespace are normalized (`a 13 B` matches `A13b`); suffixes and
hyphens remain significant. `B14` is one code across all speed values.

Exit codes:

| Exit | Meaning |
| --- | --- |
| 0 | Build/verification succeeded. **Not permission to generate.** |
| 1 | Missing, stale, malformed or unreviewed input; stop. |
| 2 | Existing question, relevant context, supplementary sign or draft; skip generation. |
| 3 | Code/candidate/scope needs review; stop. |

This stage intentionally never returns `generation_allowed: true`. An uncovered
code still needs a valid car scenario and approved category. This inventory is
not a complete French sign catalogue or a whitelist of signs for cars.

## Files

- [Review decisions](../docs/content-audit/france-sign-review.json): editable
  mappings keyed by stable question key and catalogue image path, references,
  findings, category suggestions, scope notes, and the existing A13b draft.
- [Generated registry](../docs/content-audit/france-sign-registry.json): code
  lookups, all question and catalogue records, exact hashes and source manifest.
- [Audit report](../docs/content-audit/france-sign-audit.md): counts, findings,
  overlapping scenarios and code coverage.

`primary_codes` identify the learning target. `supplementary_codes` identify
tested plates. `context_codes` identify established supporting signs and block
repetition conservatively. `comparison_codes` are mentions used only to explain
a distinction; they do not establish coverage. `candidate_codes` always impose
a review hold. A hold takes precedence over other valid coverage of that code.

`no_sign_target` means a general-rule learning objective, not that its image
contains no signs. Background signs have not been exhaustively annotated.
Question status `mapped` means a code identity was assigned, not that every
aspect of its road scene or legal explanation has passed publication QA.

Existing category links are copied from questions. `suggested_category_slug`
is a proposed default for a future car scenario and never moves existing
questions. Sign-library categories and question categories are different.
Specialist library entries are retained for the audit; their presence is not
authorization to generate specialist-vehicle questions.

## Updating a review

1. Review changed/new questions against their image, French/English text,
   answers and authoritative sign reference. Use the stable key, not its array
   position or a guessed filename. Explicitly choose `mapped`, `needs_review`
   or `no_sign_target`, with codes and an evidence note.
2. Update that entry in `france-sign-review.json`. `source_sha256` is produced
   by `identity(record, root)` in `sign_registry.py`: it binds the entire source
   record and exact image bytes. Update it only after reviewing those bytes;
   there is deliberately no automatic “accept all changes” command.
3. Register any new local quiz-card draft with its code, ID, file paths and
   file SHA-256 values. Images appearing under `assets-source/quiz-cards` without
   a draft entry block verification. Other draft locations must be added to
   `draft_directories` before using them in the future workflow.
4. Add new observed codes to `known_codes`, with category/scope decisions as
   appropriate. Resolve related findings/candidate holds and removed keys.
5. Run `python3 scripts/sign_registry.py build`, then `verify` and the tests.
   Build refuses stale/missing reviews; it only writes the two generated files.

Questions can share a sign while testing different situations. Exact content
and image SHA-256 groups catch literal duplicates; manually recorded scenario
groups identify conceptual overlap. Neither catches every paraphrase or similar
image. A future generation stage needs a reviewed structured scenario identity
as well as the default one-situation-per-code check.

The inventory does not inspect retired questions on installed devices or act
as a transaction lock. [The sign-question workflow](SIGN_WORKFLOW.md) now provides
serialized reservations, reviewed staging, recoverable import and an import-time
recheck. Its pending jobs are included in registry lookups and block repetition.
No scheduler or SQLite schema migration is required.
