import copy
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sign_registry as r
import sign_workflow as w
import test_sign_registry as fixtures


class WorkflowTests(unittest.TestCase):
    write = fixtures.SourceChangeTests.write
    save = fixtures.SourceChangeTests.save

    def setUp(self):
        fixtures.SourceChangeTests.setUp(self)
        self.review['known_codes'].append('B15')
        self.review['routing']['B15'] = 'priority_rules'
        self.save(r.REVIEW, self.review)
        self.write(w.SCHEMA, b'enum Schema { static let contentVersion: Int64 = 36 }\n')
        self.proposal = json.loads((r.ROOT / 'assets-source/sign-workflow/B15/proposal.json').read_text())
        self.image = self.root / 'candidate.png'
        self.image.write_bytes(b'\x89PNG\r\n\x1a\nunique test image')
        w.refresh(self.root)

    def ready(self):
        w.reserve(self.root, self.proposal)
        w.stage(self.root, 'B15', self.image)
        w.review(self.root, 'B15', 'Reviewed the actual scene, both languages, sign, answer and category.')

    def test_pending_reservation_is_visible_to_registry(self):
        w.reserve(self.root, self.proposal)
        self.assertEqual(r.lookup(w.fresh(self.root), 'B15')['decision'], 'skip_existing')
        with self.assertRaises(ValueError):
            w.reserve(self.root, self.proposal)

    def test_two_workers_cannot_reserve_same_code(self):
        def worker():
            with w.locked(self.root):
                try:
                    w.reserve(self.root, self.proposal)
                    return 'reserved'
                except ValueError:
                    return 'blocked'
        with ThreadPoolExecutor(max_workers=2) as pool:
            self.assertEqual(sorted(pool.map(lambda _: worker(), range(2))), ['blocked', 'reserved'])

    def test_import_requires_visual_review(self):
        w.reserve(self.root, self.proposal)
        w.stage(self.root, 'B15', self.image)
        with self.assertRaisesRegex(ValueError, 'review'):
            w.import_question(self.root, 'B15')
        self.assertEqual(len(r.read(self.root, r.CONTENT / 'pack.json')['questions']), 1)

    def test_import_is_idempotent_and_keeps_existing_question(self):
        before = r.read(self.root, r.CONTENT / 'pack.json')['questions'][0]
        self.ready()
        result = w.import_question(self.root, 'B15')
        self.assertEqual(result['state'], 'imported')
        self.assertEqual(w.import_question(self.root, 'B15')['state'], 'already_imported')
        pack = r.read(self.root, r.CONTENT / 'pack.json')
        self.assertEqual(len(pack['questions']), 2)
        self.assertEqual(pack['questions'][0], before)
        self.assertIn('= 37', (self.root / w.SCHEMA).read_text())
        self.assertEqual(r.lookup(w.fresh(self.root), 'B15')['question_keys'], [self.proposal['question']['key']])

    def test_changed_image_blocks_import(self):
        self.ready()
        job = r.read(self.root, r.JOBS / 'B15.json')
        (self.root / job['image_path']).write_bytes(b'changed after review')
        with self.assertRaises(ValueError):
            w.import_question(self.root, 'B15')

    def test_replacement_image_requires_review_again(self):
        self.ready()
        self.image.write_bytes(b'\x89PNG\r\n\x1a\nreplacement image')
        w.stage(self.root, 'B15', self.image)
        with self.assertRaisesRegex(ValueError, 'review'):
            w.import_question(self.root, 'B15')

    def test_changed_proposal_cannot_reuse_approval_even_after_rebuild(self):
        self.ready()
        job = r.read(self.root, r.JOBS / 'B15.json')
        job['proposal']['question']['correct_answer'] = 'a'
        self.save(r.JOBS / 'B15.json', job)
        w.refresh(self.root)
        with self.assertRaisesRegex(ValueError, 'review'):
            w.import_question(self.root, 'B15')

    def test_journal_resumes_after_interruption(self):
        self.ready()
        with patch.object(w, 'refresh', side_effect=RuntimeError('simulated crash')):
            with self.assertRaises(RuntimeError):
                w.import_question(self.root, 'B15')
        self.assertTrue((self.root / w.JOURNAL).exists())
        w.recover(self.root)
        self.assertEqual(len(r.read(self.root, r.CONTENT / 'pack.json')['questions']), 2)
        self.assertFalse((self.root / w.JOURNAL).exists())
        self.assertEqual(w.import_question(self.root, 'B15')['state'], 'already_imported')

    def test_recovery_does_not_overwrite_unrelated_edits(self):
        self.ready()
        with patch.object(w, 'refresh', side_effect=RuntimeError('simulated crash')):
            with self.assertRaises(RuntimeError):
                w.import_question(self.root, 'B15')
        path = self.root / w.SCHEMA
        path.write_text('user edit')
        with self.assertRaisesRegex(ValueError, 'Concurrent edit'):
            w.recover(self.root)
        self.assertEqual(path.read_text(), 'user edit')

    def test_wrong_category_and_specialist_scope_block_reservation(self):
        for field, value in [('scope', 'heavy_goods'), ('scope_review', '')]:
            proposal = copy.deepcopy(self.proposal)
            proposal[field] = value
            with self.assertRaises(ValueError):
                w.reserve(self.root, proposal)
        proposal = copy.deepcopy(self.proposal)
        proposal['question']['category_slug'] = 'road_signs'
        with self.assertRaises(ValueError):
            w.reserve(self.root, proposal)


if __name__ == '__main__':
    unittest.main()
