import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('sign_registry', Path(__file__).resolve().parents[1] / 'sign_registry.py')
r = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(r)


class BundledRegistryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.registry = r.build()

    def test_every_source_is_accounted_for_and_artifacts_current(self):
        self.assertEqual(self.registry['validation_errors'], [])
        pack = r.read(r.ROOT, r.CONTENT / 'pack.json')
        self.assertEqual({q['key'] for q in self.registry['questions']}, {q['key'] for q in pack['questions']})
        self.assertEqual((r.ROOT / r.REGISTRY).read_text(), r.rendered(self.registry))
        self.assertEqual((r.ROOT / r.REPORT).read_text(), r.report(self.registry))

    def test_a13b_blocks_question_and_draft(self):
        result = r.lookup(self.registry, ' a 13 B ')
        self.assertEqual(result['decision'], 'skip_existing')
        self.assertIn('danger_sign_pedestrian_crossing', result['question_keys'])
        self.assertIn('a13b-passage-pietons', result['draft_ids'])

    def test_comparison_is_not_question_coverage(self):
        code = self.registry['codes']['B27a']
        self.assertNotIn('situation_bus_lane', code['question_keys'])
        self.assertIn('situation_bus_lane', code['comparison_question_keys'])
        self.assertIn('situation_bus_lane', self.registry['codes']['C6']['question_keys'])

    def test_resolved_codes_keep_coverage_without_false_mappings(self):
        for code in ['B21-1', 'C208', 'AK5']:
            result = r.lookup(self.registry, code)
            self.assertEqual(result['decision'], 'skip_existing')
            self.assertEqual(result['review_holds'], [])
        self.assertNotIn('situation_mandatory_right', self.registry['codes']['B21b']['question_keys'])
        self.assertNotIn('situation_motorway_end', self.registry['codes']['C112']['question_keys'])

    def test_review_hold_still_overrides_existing_coverage(self):
        registry = copy.deepcopy(self.registry)
        registry['codes']['A13b']['review_holds'] = ['new-conflicting-question']
        self.assertEqual(r.lookup(registry, 'A13b')['decision'], 'needs_review')

    def test_resolved_visual_mappings_do_not_invent_absent_signs(self):
        questions = {q['key']: q for q in self.registry['questions']}
        for key in ['situation_disabled_bay_without_card', 'situation_reserved_bus_lane_priority_right']:
            self.assertEqual(questions[key]['status'], 'no_sign_target')
            self.assertEqual(questions[key].get('candidate_codes', []), [])
        for code in ['C24a', 'C24b', 'C24c']:
            self.assertTrue(self.registry['codes'][code]['catalogue_images'])
            self.assertFalse(self.registry['codes'][code]['review_holds'])

    def test_shared_speed_code_keeps_variants(self):
        keys = self.registry['codes']['B14']['question_keys']
        self.assertIn('situation_speed_limit_50', keys)
        self.assertIn('situation_speed_limit_110', keys)
        self.assertFalse(any(set(keys) <= set(g) for g in self.registry['exact_duplicate_content_groups']))

    def test_no_false_clearance_for_catalogue_only_or_unknown(self):
        for code in ['B21-2', 'A999', 'A13', 'B211', '']:
            result = r.lookup(self.registry, code)
            self.assertEqual(result['decision'], 'needs_review')
            self.assertFalse(result['generation_allowed'])


class SourceChangeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        translation = dict(question_text='Stop?', answer_a='Yes', answer_b='No',
                           answer_c='Later', answer_d='Never', explanation='Stop before proceeding.')
        self.question = dict(key='stop', category_slug='priority_rules', correct_answer='a',
                             image_path='france/stop.png', translations={'fr': translation, 'en': translation})
        self.pack = dict(categories=[{'slug': 'priority_rules'}], languages=['en', 'fr'],
                         questions=[self.question], roadSignCategories=[], roadSigns=[])
        self.write(r.CONTENT / 'images/stop.png', b'image fixture')
        self.write('scripts/sign_registry.py', b'builder fixture')
        self.write('TheoryPrep/Models/ContentPack.swift', b'loader fixture')
        self.write('docs/CONTENT_GUIDE.md', b'scope fixture')
        self.save(r.CONTENT / 'pack.json', self.pack)
        self.save(r.CONTENT / 'road-signs.json', {'categories': [], 'signs': []})
        self.review = dict(schema_version=1, audit_date='2026-09-13', known_codes=['AB4'],
            questions={'stop': {'source_sha256': r.identity(self.question, self.root),
                               'status': 'mapped', 'primary_codes': ['AB4']}},
            catalogue={}, drafts=[], draft_directories=['assets-source/quiz-cards'],
            routing={'AB4': 'priority_rules'}, scope={}, scenario_review_groups=[], findings=[], references=[])
        self.save(r.REVIEW, self.review)

    def write(self, path, content):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)

    def save(self, path, content):
        self.write(path, json.dumps(content).encode())

    def test_new_question_requires_explicit_review(self):
        self.pack['questions'].append({**self.question, 'key': 'new'})
        self.save(r.CONTENT / 'pack.json', self.pack)
        registry = r.build(self.root)
        self.assertIn('Question needs current review: new', registry['validation_errors'])
        self.assertEqual(r.lookup(registry, 'AB4')['decision'], 'blocked')

    def test_changed_image_invalidates_review(self):
        self.write(r.CONTENT / 'images/stop.png', b'changed image')
        self.assertIn('Question needs current review: stop', r.build(self.root)['validation_errors'])

    def test_changed_explanation_invalidates_review(self):
        self.question['translations']['en']['explanation'] = 'Changed meaning'
        self.save(r.CONTENT / 'pack.json', self.pack)
        self.assertIn('Question needs current review: stop', r.build(self.root)['validation_errors'])

    def test_missing_image_does_not_pass(self):
        (self.root / r.CONTENT / 'images/stop.png').unlink()
        with self.assertRaises(FileNotFoundError):
            r.build(self.root)

    def test_unregistered_draft_blocks(self):
        self.write('assets-source/quiz-cards/new.png', b'draft')
        self.assertIn('Unregistered draft image: assets-source/quiz-cards/new.png', r.build(self.root)['validation_errors'])

    def test_registered_draft_alone_blocks_repetition(self):
        path = 'assets-source/quiz-cards/new.png'
        self.write(path, b'draft')
        self.pack['questions'] = []
        self.review['questions'] = {}
        self.review['drafts'] = [{'id': 'draft', 'codes': ['AB4'], 'files': {path: r.file_hash(self.root, path)}}]
        self.save(r.CONTENT / 'pack.json', self.pack)
        self.save(r.REVIEW, self.review)
        result = r.lookup(r.build(self.root), 'AB4')
        self.assertEqual(result['decision'], 'skip_existing')
        self.assertEqual(result['question_keys'], [])

    def test_duplicate_keys_are_rejected(self):
        self.pack['questions'].append(copy.deepcopy(self.question))
        self.save(r.CONTENT / 'pack.json', self.pack)
        with self.assertRaisesRegex(ValueError, 'duplicate stable question'):
            r.build(self.root)

    def test_exact_duplicate_detection_ignores_identity_and_order(self):
        new = {**self.question, 'key': 'other'}
        self.pack['questions'].append(new)
        self.review['questions']['other'] = {**self.review['questions']['stop'], 'source_sha256': r.identity(new, self.root)}
        self.save(r.REVIEW, self.review)
        self.save(r.CONTENT / 'pack.json', self.pack)
        registry = r.build(self.root)
        self.assertEqual(registry['exact_duplicate_content_groups'], [['other', 'stop']])
        self.assertEqual(registry['exact_duplicate_image_groups'], [['other', 'stop']])
        self.pack['questions'].reverse()
        self.save(r.CONTENT / 'pack.json', self.pack)
        reordered = r.build(self.root)
        self.assertEqual(registry['questions'], reordered['questions'])
        self.assertEqual(reordered['validation_errors'], [])

    def test_catalogue_merge_uses_loader_precedence(self):
        canonical = {'road_sign_category_slug': 'danger', 'image_path': 'france/canonical.png'}
        priority = {'road_sign_category_slug': 'priority', 'image_path': 'france/priority.png'}
        pack = {'roadSignCategories': [{'slug': 'danger'}, {'slug': 'priority'}],
                'roadSigns': [canonical, priority, {**canonical, 'image_path': 'france/legacy.png'}]}
        catalogue = {'categories': [{'slug': 'danger'}], 'signs': [canonical]}
        self.assertEqual(r.active_signs(pack, catalogue), [canonical, priority])


if __name__ == '__main__':
    unittest.main()
