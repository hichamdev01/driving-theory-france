import copy
import json
from pathlib import Path
import struct
import sys
import unittest
from unittest.mock import patch
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import question_batch as b
import sign_registry as r
import sign_workflow as w
import test_sign_registry as fixtures


def png(number):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    row = b'\x00' + bytes([number, 100, 130]) * 1024
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1024, 576, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(row * 576)) + chunk(b'IEND', b''))


class BatchTests(unittest.TestCase):
    write = fixtures.SourceChangeTests.write
    save = fixtures.SourceChangeTests.save

    def setUp(self):
        fixtures.SourceChangeTests.setUp(self)
        self.write(w.SCHEMA, b'enum Schema { static let contentVersion: Int64 = 90 }\n')
        self.save(r.CONTENT / 'blueprint.json', {'mock_exam_quotas': {'priority_rules': 40}})
        self.proposals = [self.proposal(i) for i in range(10)]
        w.refresh(self.root)

    def proposal(self, index):
        q = copy.deepcopy(self.question)
        q.update(key=f'situation_fixture_{index}', difficulty='medium')
        q.pop('image_path')
        q.pop('correct_answer')
        q['correct_answers'] = ['a', 'c'] if index in (8, 9) else ['a']
        for lang in ('fr', 'en'):
            # The source fixture shares translations; separate them deliberately.
            q['translations'][lang] = dict(q['translations'][lang], question_text=f'{lang} unique scenario {index}?')
            q['translations'][lang]['explanation'] = ('This fixture explanation supplies the applicable rule and its safety context. '
                                                      'Each real question must have an independently reviewed explanation.')
        return dict(scenario_id=f'fixture_{index}', scope='ordinary_passenger_car',
                    scope_review='Car learner only.', learning_objective=f'Objective {index}', topic='priority',
                    scenario=f'Scene {index}', novelty_review='Different decision from all current questions.',
                    image_prompt=f'Generate scene {index}', question=q, primary_codes=[], context_codes=[],
                    option_rationale={lang: {a: f'Why {a} is correct/wrong.' for a in 'abcd'} for lang in ('fr', 'en')},
                    sources=[{'url': 'https://www.legifrance.gouv.fr/codes/', 'kind': 'official',
                              'checked_on': '2026-10-09', 'supports': 'Fixture rule reference'}])

    def reserve(self):
        return b.reserve(self.root, 'batch-001', self.proposals)

    def stage(self, index, attempt=0):
        image = self.root / 'candidate.png'
        image.write_bytes(png(index + attempt * 10))
        return b.stage(self.root, 'batch-001', f'fixture_{index}', image, f'Exact prompt {index}/{attempt}')

    def receipt(self, item, result='pass'):
        return dict(result=result, notes='Specific actual inspection notes in production.',
                    proposal_sha256=r.digest(item['proposal']), image_sha256=item['image_sha256'],
                    checks={k: f'Fixture observation for {k}' for k in b.CHECKS},
                    compared_question_keys=[q['key'] for q in item['nearest_questions']])

    def ready(self):
        self.reserve()
        for i in range(10):
            item = self.stage(i)
            b.review(self.root, 'batch-001', f'fixture_{i}', self.receipt(item))

    def test_batch_size_answer_mix_and_invalid_choices_are_rejected(self):
        for mutate in (lambda p: p.pop(),
                       lambda p: p[0]['question'].update(correct_answers=['a', 'b']),
                       lambda p: p[0]['question'].update(correct_answers=['a', 'a']),
                       lambda p: p[0]['question'].update(correct_answers=['e'])):
            proposals = copy.deepcopy(self.proposals)
            mutate(proposals)
            with self.assertRaises(ValueError):
                b.reserve(self.root, 'invalid', proposals)
        self.assertFalse((self.root / b.job_path('invalid')).exists())

    def test_unverified_baseline_blocks_expansion(self):
        self.save(b.BASELINE, {'status': 'awaiting_native_verification'})
        with self.assertRaisesRegex(ValueError, 'baseline'):
            self.reserve()

    def test_public_bodies_and_lookalike_domains(self):
        registry = w.fresh(self.root)
        proposal = copy.deepcopy(self.proposals[0])
        for host in ('www.legifrance.gouv.fr', 'www.ameli.fr', 'ansm.sante.fr',
                     'equipementsdelaroute.cerema.fr', 'unece.org'):
            with self.subTest(host=host):
                proposal['sources'][0]['url'] = 'https://' + host + '/rule'
                b.validate_proposal(self.root, registry, proposal, [])
        for host in ('fakeameli.fr', 'ameli.fr.example.com', 'www.ornikar.com'):
            with self.subTest(host=host), self.assertRaisesRegex(ValueError, 'official'):
                proposal['sources'][0]['url'] = 'https://' + host + '/rule'
                b.validate_proposal(self.root, registry, proposal, [])

    def test_all_ten_reviews_required_before_import(self):
        self.reserve()
        self.stage(0)
        with self.assertRaisesRegex(ValueError, 'review'):
            b.import_batch(self.root, 'batch-001')
        self.assertEqual(len(r.read(self.root, r.CONTENT / 'pack.json')['questions']), 1)

    def test_short_explanation_blocked_before_generation(self):
        self.proposals[0]['question']['translations']['en']['explanation'] = 'Too short.'
        with self.assertRaisesRegex(ValueError, '100 characters'):
            self.reserve()

    def test_imported_wording_repair_requires_fresh_review_and_is_idempotent(self):
        self.ready()
        imported = b.import_batch(self.root, 'batch-001')
        old = imported['items'][0]
        proposal = copy.deepcopy(old['proposal'])
        proposal['question']['translations']['en']['explanation'] += ' Additional reviewed safety detail.'
        revision = dict(scenario_id='fixture_0', proposal=proposal, reason='Repair explanation', review=old['review'])
        with self.assertRaisesRegex(ValueError, 'match'):
            b.amend(self.root, 'batch-001', [revision])
        revision['review'] = self.receipt({**old, 'proposal': proposal})
        amended = b.amend(self.root, 'batch-001', [revision])
        self.assertEqual(amended['questions_after'], imported['questions_after'])
        self.assertEqual(amended['content_version'], imported['content_version'] + 1)
        self.assertEqual(amended['items'][0]['amendments'][0]['previous_proposal'], old['proposal'])
        before_retry = (self.root / (r.CONTENT / 'pack.json')).read_bytes()
        b.amend(self.root, 'batch-001', [revision])
        self.assertEqual((self.root / (r.CONTENT / 'pack.json')).read_bytes(), before_retry)
        changed_key = copy.deepcopy(revision)
        changed_key['proposal']['question']['key'] = 'different_key'
        with self.assertRaisesRegex(ValueError, 'preserve key'):
            b.amend(self.root, 'batch-001', [changed_key])

    def test_staging_invalidates_review_and_preserves_candidates(self):
        self.reserve()
        first = self.stage(0)
        b.review(self.root, 'batch-001', 'fixture_0', self.receipt(first))
        second = self.stage(0, 1)
        self.assertNotIn('review', second)
        self.assertTrue((self.root / first['image_path']).is_file())
        with self.assertRaisesRegex(ValueError, 'match'):
            b.review(self.root, 'batch-001', 'fixture_0', self.receipt(first))

    def test_missing_review_observations_or_novelty_comparisons_fail(self):
        self.reserve()
        item = self.stage(0)
        receipt = self.receipt(item)
        receipt['checks'].pop('road_geometry')
        with self.assertRaises(ValueError): b.review(self.root, 'batch-001', 'fixture_0', receipt)
        receipt = self.receipt(item)
        receipt['compared_question_keys'] = []
        with self.assertRaises(ValueError): b.review(self.root, 'batch-001', 'fixture_0', receipt)

    def test_changed_proposal_cannot_reuse_review_even_after_registry_rebuild(self):
        self.ready()
        batch = r.read(self.root, b.job_path('batch-001'))
        batch['items'][0]['proposal']['question']['correct_answers'] = ['b']
        self.save(b.job_path('batch-001'), batch)
        w.refresh(self.root)
        with self.assertRaisesRegex(ValueError, 'review'): b.import_batch(self.root, 'batch-001')

    def test_changed_image_blocks_import(self):
        self.ready()
        batch = r.read(self.root, b.job_path('batch-001'))
        self.write(batch['items'][0]['image_path'], png(100))
        with self.assertRaises(ValueError): b.import_batch(self.root, 'batch-001')

    def test_duplicate_content_image_and_sign_are_rejected(self):
        p = copy.deepcopy(self.proposals)
        p[1]['question']['translations'] = copy.deepcopy(p[0]['question']['translations'])
        with self.assertRaises(ValueError): b.reserve(self.root, 'dupe', p)
        p = copy.deepcopy(self.proposals)
        p[0]['primary_codes'] = ['AB4']
        with self.assertRaisesRegex(ValueError, 'existing'): b.reserve(self.root, 'covered', p)
        self.reserve()
        item = self.stage(0)
        with self.assertRaisesRegex(ValueError, 'already exists'):
            b.stage(self.root, 'batch-001', 'fixture_1', self.root / item['image_path'], 'Copied image')

    def test_pending_signs_block_old_sign_workflow(self):
        self.review['known_codes'].append('B15')
        self.review['routing']['B15'] = 'priority_rules'
        self.save(r.REVIEW, self.review)
        w.refresh(self.root)
        self.proposals[0]['primary_codes'] = ['B15']
        self.reserve()
        registry = w.fresh(self.root)
        self.assertEqual(r.lookup(registry, 'B15')['decision'], 'skip_existing')
        with self.assertRaises(ValueError): w.assert_available(registry, 'B15')

    def test_import_is_idempotent_bilingual_and_preserves_existing_record(self):
        original = copy.deepcopy(r.read(self.root, r.CONTENT / 'pack.json')['questions'][0])
        self.ready()
        batch = b.import_batch(self.root, 'batch-001')
        self.assertEqual(batch['questions_after'], 11)
        self.assertEqual(b.import_batch(self.root, 'batch-001')['state'], 'already_imported')
        pack = r.read(self.root, r.CONTENT / 'pack.json')
        self.assertEqual(pack['questions'][0], original)
        self.assertEqual(sum(len(q.get('correct_answers', [])) == 2 for q in pack['questions']), 2)
        self.assertIn('= 91', (self.root / w.SCHEMA).read_text())
        self.assertEqual(len((self.root / b.SOURCES).read_text().splitlines()), 10)

    def test_unverified_batch_blocks_next_batch(self):
        self.ready()
        b.import_batch(self.root, 'batch-001')
        with self.assertRaisesRegex(ValueError, 'preceding'):
            b.reserve(self.root, 'batch-002', [self.proposal(i + 20) for i in range(10)])

    def test_bank_changed_since_reservation_is_not_overwritten(self):
        self.ready()
        pack = r.read(self.root, r.CONTENT / 'pack.json')
        pack['user_edit'] = True
        self.save(r.CONTENT / 'pack.json', pack)
        w.refresh(self.root)
        with self.assertRaisesRegex(ValueError, 'Bank changed'): b.import_batch(self.root, 'batch-001')
        self.assertTrue(r.read(self.root, r.CONTENT / 'pack.json')['user_edit'])

    def test_interrupted_import_recovers_and_does_not_duplicate(self):
        self.ready()
        with patch.object(w, 'refresh', side_effect=RuntimeError('crash')):
            with self.assertRaises(RuntimeError): b.import_batch(self.root, 'batch-001')
        self.assertTrue((self.root / w.JOURNAL).exists())
        w.recover(self.root)
        self.assertEqual(len(r.read(self.root, r.CONTENT / 'pack.json')['questions']), 11)
        self.assertEqual(b.import_batch(self.root, 'batch-001')['state'], 'already_imported')

    def test_three_corrections_then_replacement_required(self):
        self.reserve()
        for attempt in range(4):
            item = self.stage(0, attempt)
            b.review(self.root, 'batch-001', 'fixture_0', self.receipt(item, 'reject'))
        with self.assertRaisesRegex(ValueError, 'exhausted'): self.stage(0, 4)
        with self.assertRaises(ValueError):
            b.replace(self.root, 'batch-001', 'fixture_0', self.proposal(0), 'Try same again')
        new = b.replace(self.root, 'batch-001', 'fixture_0', self.proposal(20), 'Different decision after failed corrections')
        self.assertEqual(new['state'], 'reserved')
        self.assertEqual(len(new['replacements'][0]['previous']['history']), 4)

    def test_verification_needs_real_evidence_for_current_pack(self):
        self.ready()
        batch = b.import_batch(self.root, 'batch-001')
        evidence = {'pack_sha256': batch['pack_after_sha256'], 'content_version': batch['content_version']}
        with self.assertRaises(ValueError): b.verify(self.root, 'batch-001', evidence)
        for name in b.EVIDENCE:
            path = Path('evidence') / (name + '.txt')
            self.write(path, b'Passing test fixture evidence')
            evidence[name] = {'result': 'pass', 'notes': 'Checked fixture', 'path': str(path),
                              'sha256': r.file_hash(self.root, path)}
        self.assertEqual(b.verify(self.root, 'batch-001', evidence)['state'], 'verified')
        self.write(evidence['ios_tests']['path'], b'changed evidence')
        with self.assertRaises(ValueError): b.verify(self.root, 'batch-001', evidence)

    def test_final_two_and_target_cap(self):
        with patch.object(b, 'TARGET', 3):
            b.reserve(self.root, 'final', self.proposals[:2])
        with patch.object(b, 'TARGET', 1):
            with self.assertRaises(ValueError): b.reserve(self.root, 'over', self.proposals)

    def repair_fixture(self):
        self.ready()
        batch = b.import_batch(self.root, 'batch-001')
        item = batch['items'][0]
        proposal = self.proposal(40)
        proposal['question']['key'] = item['proposal']['question']['key']
        path = b.ASSETS / 'batch-001/replacement/scene.png'
        self.write(path, png(150))
        candidates = [(q, s) for q, s in b.all_candidates(self.root, w.fresh(self.root), 'batch-001')
                      if q['key'] != proposal['question']['key']]
        reviewed = dict(proposal=proposal, image_sha256=w.sha(png(150)),
                        nearest_questions=b.nearest(proposal['question'], candidates))
        return dict(repair_id='replace-overlap', scenario_id='fixture_0', proposal=proposal,
                    previous_question_sha256=item['imported_question_sha256'], image_path=str(path),
                    reason='Confirmed duplicate learning objective.', review=self.receipt(reviewed))

    def test_repair_preserves_key_count_and_audit_and_is_idempotent(self):
        revision = self.repair_fixture()
        before = r.read(self.root, r.CONTENT / 'pack.json')
        batch = b.repair(self.root, 'batch-001', revision)
        after = r.read(self.root, r.CONTENT / 'pack.json')
        self.assertEqual([q['key'] for q in before['questions']], [q['key'] for q in after['questions']])
        self.assertEqual(batch['content_version'], 92)
        self.assertEqual(batch['state'], 'imported')
        self.assertEqual(batch['content_repairs'][0]['previous_item']['proposal']['scenario_id'], 'fixture_0')
        self.assertEqual(b.repair(self.root, 'batch-001', revision)['content_version'], 92)
        with self.assertRaisesRegex(ValueError, 'preceding'):
            b.reserve(self.root, 'next', [self.proposal(i + 50) for i in range(10)])

    def test_repair_rejects_stale_receipt_and_key_change(self):
        revision = self.repair_fixture()
        for mutation, error in [(lambda v: v['proposal']['question'].update(key='situation_other'), 'stable'),
                                (lambda v: v['review'].update(image_sha256='stale'), 'match'),
                                (lambda v: v.update(previous_question_sha256='stale'), 'stale')]:
            value = copy.deepcopy(revision)
            mutation(value)
            with self.assertRaisesRegex(ValueError, error): b.repair(self.root, 'batch-001', value)
        self.assertIn('= 91', (self.root / w.SCHEMA).read_text())

    def test_interrupted_repair_recovers_without_duplicate_or_second_version_bump(self):
        revision = self.repair_fixture()
        with patch.object(w, 'refresh', side_effect=RuntimeError('crash')):
            with self.assertRaises(RuntimeError): b.repair(self.root, 'batch-001', revision)
        w.recover(self.root)
        self.assertEqual(b.repair(self.root, 'batch-001', revision)['content_version'], 92)
        self.assertEqual(len(r.read(self.root, r.CONTENT / 'pack.json')['questions']), 11)

    def test_signal_family_cannot_bypass_existing_direction_variant(self):
        registry = {'codes': {'R16': {}, 'R16td': {'question_keys': ['existing-right-arrow']}}}
        with self.assertRaisesRegex(ValueError, 'related signal'):
            w.assert_available(registry, 'R16')

    def test_nearest_prefers_shared_rule_over_multiple_answer_boilerplate(self):
        def question(stem, explanation):
            return {'translations': {'fr': {'question_text': stem, 'explanation': explanation}}}
        target = question('Je suis dans la voie pour tourner à droite. La flèche jaune clignote alors que le feu principal est rouge. Quelles affirmations sont exactes ?',
                          'La flèche jaune clignotante autorise le mouvement indiqué malgré le rouge, en cédant le passage.')
        equivalent = dict(question('Le feu principal est rouge et la flèche jaune vers la droite clignote. Puis-je tourner ?',
                                   'La flèche jaune clignotante autorise le passage malgré le rouge sans donner la priorité.'), key='same_rule')
        unrelated = dict(question('Je transporte une personne titulaire de la carte stationnement. Quelles affirmations sont exactes ?',
                                  'La carte permet le stationnement avec son titulaire.'), key='boilerplate')
        self.assertEqual(b.nearest(target, [(unrelated, None), (equivalent, None)])[0]['key'], 'same_rule')

    def legacy_replacement_fixture(self):
        pack = r.read(self.root, r.CONTENT / 'pack.json')
        replacements = []
        for i in range(10):
            old = copy.deepcopy(self.proposals[i]['question'])
            old['key'] = f'legacy_{i}'
            old['image_path'] = f'france/legacy_{i}.png'
            self.write(r.image_file(old['image_path']), png(100 + i))
            pack['questions'].append(old)
            proposal = self.proposal(20 + i)
            proposal['question']['key'] = old['key']
            proposal['question']['correct_answers'] = ['a', 'c'] if i >= 8 else ['a']
            proposal['replacement_reason'] = 'Confirmed repeated legacy objective.'
            replacements.append(proposal)
        text_only = copy.deepcopy(self.question)
        text_only.pop('image_path')
        text_only['key'] = 'retained_text_only'
        for lang in ('fr', 'en'):
            text_only['translations'][lang] = dict(text_only['translations'][lang], question_text=f'{lang} text-only drill?')
        pack['questions'].append(text_only)
        self.save(r.CONTENT / 'pack.json', pack)
        for q in pack['questions'][1:]:
            self.review['questions'][q['key']] = {
                'source_sha256': r.identity(q, self.root), 'status': 'no_sign_target',
                'primary_codes': [], 'context_codes': [],
            }
        self.save(r.REVIEW, self.review)
        w.refresh(self.root)
        return replacements

    def ready_replacements(self):
        proposals = self.legacy_replacement_fixture()
        b.reserve(self.root, 'legacy-repairs', proposals, replace_existing=True)
        for i, p in enumerate(proposals):
            path = self.root / 'candidate.png'
            path.write_bytes(png(180 + i))
            item = b.stage(self.root, 'legacy-repairs', p['scenario_id'], path, 'Reviewed replacement fixture')
            b.review(self.root, 'legacy-repairs', p['scenario_id'], self.receipt(item))
        return proposals

    def test_legacy_replacements_preserve_keys_text_only_and_original_evidence(self):
        self.ready_replacements()
        before = r.read(self.root, r.CONTENT / 'pack.json')
        batch = b.import_batch(self.root, 'legacy-repairs')
        after = r.read(self.root, r.CONTENT / 'pack.json')
        self.assertEqual(batch['questions_before'], batch['questions_after'])
        self.assertEqual([q['key'] for q in before['questions']], [q['key'] for q in after['questions']])
        self.assertEqual(before['questions'][0], after['questions'][0])
        self.assertEqual(before['questions'][-1], after['questions'][-1])
        for i, item in enumerate(batch['items']):
            old = item['replaces']
            self.assertEqual(old['question'], before['questions'][i + 1])
            self.assertEqual((self.root / old['archived_image_path']).read_bytes(), png(100 + i))
            self.assertEqual((self.root / r.image_file(after['questions'][i + 1]['image_path'])).read_bytes(), png(180 + i))
        self.assertIn('= 91', (self.root / w.SCHEMA).read_text())
        self.assertEqual(b.import_batch(self.root, 'legacy-repairs')['state'], 'already_imported')
        self.assertIn('= 91', (self.root / w.SCHEMA).read_text())

    def test_legacy_replacement_scope_reason_and_covered_sign_guards(self):
        proposals = self.legacy_replacement_fixture()
        mutations = [
            (lambda p: p[0]['question'].update(key='new_key'), 'existing illustrated'),
            (lambda p: p[0]['question'].update(key='retained_text_only'), 'text-only'),
            (lambda p: p[0].pop('replacement_reason'), 'reason'),
            (lambda p: p[0]['question'].update(key=p[1]['question']['key']), 'distinct'),
            (lambda p: p[0].update(primary_codes=['AB4']), 'existing'),
        ]
        for mutate, error in mutations:
            candidate = copy.deepcopy(proposals)
            mutate(candidate)
            with self.subTest(error=error), self.assertRaisesRegex(ValueError, error):
                b.reserve(self.root, 'invalid-legacy', candidate, replace_existing=True)
        self.assertFalse((self.root / b.job_path('invalid-legacy')).exists())
        unchanged = copy.deepcopy(proposals)
        old = r.read(self.root, r.CONTENT / 'pack.json')['questions'][1]
        unchanged[0]['question'] = {k: copy.deepcopy(v) for k, v in old.items() if k != 'image_path'}
        with self.assertRaisesRegex(ValueError, 'different learning situation'):
            b.reserve(self.root, 'same-legacy', unchanged, replace_existing=True)

    def test_nonstandard_legacy_key_is_only_accepted_for_that_existing_identity(self):
        question = copy.deepcopy(self.proposals[0]['question'])
        question['key'] = 'danger_sign_legacy'
        with self.assertRaisesRegex(ValueError, 'stable question key'):
            w.validate_question(question)
        w.validate_question(question, existing_key='danger_sign_legacy')
        with self.assertRaisesRegex(ValueError, 'stable question key'):
            w.validate_question(question, existing_key='different_legacy_key')
        question['key'] = '../escape'
        with self.assertRaisesRegex(ValueError, 'stable question key'):
            w.validate_question(question, existing_key='../escape')

    def test_legacy_replacement_archive_changes_and_stale_reviews_block_import(self):
        self.ready_replacements()
        batch = r.read(self.root, b.job_path('legacy-repairs'))
        item = batch['items'][0]
        self.write(item['replaces']['archived_image_path'], png(240))
        with self.assertRaisesRegex(ValueError, 'archive changed'):
            b.import_batch(self.root, 'legacy-repairs')
        self.write(item['replaces']['archived_image_path'], png(100))
        path = self.root / 'new-candidate.png'
        path.write_bytes(png(241))
        b.stage(self.root, 'legacy-repairs', item['proposal']['scenario_id'], path, 'Corrected candidate')
        with self.assertRaisesRegex(ValueError, 'review'):
            b.import_batch(self.root, 'legacy-repairs')
        self.assertIn('= 90', (self.root / w.SCHEMA).read_text())

    def test_legacy_replacement_candidate_change_must_keep_key_and_archive(self):
        proposals = self.legacy_replacement_fixture()
        batch = b.reserve(self.root, 'legacy-repairs', proposals, replace_existing=True)
        revised = self.proposal(60)
        with self.assertRaisesRegex(ValueError, 'stable question key'):
            b.replace(self.root, 'legacy-repairs', proposals[0]['scenario_id'], revised, 'New candidate')
        revised['question']['key'] = proposals[0]['question']['key']
        item = b.replace(self.root, 'legacy-repairs', proposals[0]['scenario_id'], revised, 'New candidate')
        self.assertEqual(item['replaces'], batch['items'][0]['replaces'])
        self.assertTrue((self.root / item['replaces']['archived_image_path']).exists())

    def test_interrupted_legacy_import_recovers_without_count_or_version_increase_on_retry(self):
        self.ready_replacements()
        before = r.read(self.root, r.CONTENT / 'pack.json')
        with patch.object(w, 'refresh', side_effect=RuntimeError('crash')):
            with self.assertRaises(RuntimeError):
                b.import_batch(self.root, 'legacy-repairs')
        w.recover(self.root)
        b.import_batch(self.root, 'legacy-repairs')
        after = r.read(self.root, r.CONTENT / 'pack.json')
        self.assertEqual([q['key'] for q in before['questions']], [q['key'] for q in after['questions']])
        self.assertIn('= 91', (self.root / w.SCHEMA).read_text())

    def test_legacy_replacement_gate_and_target_cap(self):
        proposals = self.legacy_replacement_fixture()
        # Repairing at the target is permitted, but does not waive review gates.
        with patch.object(b, 'TARGET', 12):
            b.reserve(self.root, 'legacy-repairs', proposals, replace_existing=True)
        with self.assertRaisesRegex(ValueError, 'preceding'):
            b.reserve(self.root, 'blocked', proposals, replace_existing=True)


if __name__ == '__main__':
    unittest.main()
