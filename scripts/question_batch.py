#!/usr/bin/env python3
"""Resumable reviewed question batches. Generation and visual review remain human/agent tasks.

Uses the sign workflow's shared lock, journal and recovery. Never calls an image API,
automatically approves a visual, edits user progress, or runs Git commands.
"""
import argparse
import copy
from collections import Counter
from datetime import date
from difflib import SequenceMatcher
import json
import math
from pathlib import Path
import re
import struct
import sys
import unicodedata
from urllib.parse import urlparse

import sign_registry as r
import sign_workflow as w

TARGET = 1000
ASSETS = Path('assets-source/question-batches')
SOURCES = r.AUDIT / 'france-question-sources.jsonl'
BASELINE = r.AUDIT / 'expansion-1000/baseline.json'
CHECKS = ('official_rule', 'novelty', 'signs_and_text', 'road_geometry',
          'vehicles_and_people', 'dashboard_and_equipment', 'full_resolution',
          'phone_size', 'french_and_english', 'all_four_options')
EVIDENCE = ('python_tests', 'ios_tests', 'sqlite_check', 'simulator_review')
PUBLIC_SOURCE_DOMAINS = ('gouv.fr', 'service-public.fr', 'ameli.fr',
                         'ansm.sante.fr', 'cerema.fr', 'unece.org')


def identifier(value):
    if not re.fullmatch(r'[a-z0-9][a-z0-9_-]*', value):
        raise ValueError('Invalid batch/scenario identifier')
    return value


def job_path(batch_id):
    return r.BATCHES / (identifier(batch_id) + '.json')


def normalized(value):
    return ' '.join(re.findall(r'\w+', unicodedata.normalize('NFKC', value).casefold()))


def content_hash(question):
    return r.digest({'translations': question['translations'],
                     'correct_answers': w.correct_answers(question)})


def all_candidates(root, registry, exclude_batch=None):
    pack = r.read(root, r.CONTENT / 'pack.json')
    candidates = [(q, None) for q in pack['questions']]
    candidates += [(j['proposal']['question'], j['proposal']['scenario_id'])
                   for j in registry['jobs'] if j['state'] != 'imported']
    for batch in registry['batches']:
        if batch['id'] != exclude_batch and batch['state'] == 'reserved':
            candidates += [(item['proposal']['question'], item['proposal']['scenario_id'])
                           for item in batch['items']]
    return candidates


def nearest(question, candidates):
    # Lexical similarity alone ranked shared question boilerplate above the
    # actual rule. Compare meaningful words in both languages and explanations.
    # This retrieves review candidates; it does not certify semantic uniqueness.
    stop = set('je j me mon ma mes le la les l un une des de du d a à au aux en et ou que qui quel quelle quelles quels est sont ce ces cette cet il elle ils elles on nous vous peut peux puis dois doit pour par sur dans avec sans si ne n pas plus the a an i my am is are do does can may must should of to in on at and or it this that with without which what how'.split())
    def tokens(q):
        fields = [t.get(k, '') for t in q['translations'].values()
                  for k in ('question_text', 'explanation')]
        return {t for t in normalized(' '.join(fields)).split() if len(t) > 2 and t not in stop}
    documents = [tokens(question)] + [tokens(q) for q, _ in candidates]
    frequency = Counter(t for doc in documents for t in doc)
    weights = {t: math.log(1 + len(documents) / n) ** 2 for t, n in frequency.items()}
    target = documents[0]
    text = normalized(question['translations']['fr']['question_text'])
    results = []
    for (other, _), document in zip(candidates, documents[1:]):
        other_text = normalized(other['translations']['fr']['question_text'])
        denom = math.sqrt(sum(weights[t] for t in target) * sum(weights[t] for t in document))
        overlap = sum(weights[t] for t in target & document) / denom if denom else 0
        score = .85 * overlap + .15 * SequenceMatcher(None, text, other_text).ratio()
        results.append({'key': other['key'], 'similarity': round(score, 3),
                        'question_fr': other['translations']['fr']['question_text']})
    return sorted(results, key=lambda item: (-item['similarity'], item['key']))[:5]


def validate_proposal(root, registry, proposal, candidates, own_batch=None, revising_key=None):
    identifier(proposal['scenario_id'])
    if proposal.get('scope') != 'ordinary_passenger_car':
        raise ValueError('Only ordinary passenger-car objectives are allowed')
    for field in ('scope_review', 'learning_objective', 'topic', 'scenario',
                  'novelty_review', 'image_prompt'):
        if not isinstance(proposal.get(field), str) or not proposal[field].strip():
            raise ValueError(f'Missing {field}')
    if not proposal.get('sources'):
        raise ValueError('Reviewed sources are required')
    authoritative = False
    for source in proposal['sources']:
        url = urlparse(source['url'])
        date.fromisoformat(source['checked_on'])
        if url.scheme != 'https' or not url.hostname or not source['supports'].strip():
            raise ValueError('Every source needs its URL, review date and supported rule')
        if source.get('kind') == 'official':
            authoritative |= any(url.hostname == domain or url.hostname.endswith('.' + domain)
                                 for domain in PUBLIC_SOURCE_DOMAINS)
        if source.get('kind') == 'manufacturer':
            authoritative = True  # reviewer must check this is the original manufacturer's manual
    if not authoritative:
        raise ValueError('At least one official or original manufacturer source is required')
    q = proposal['question']
    w.validate_question(q, existing_key=revising_key)
    for language in ('fr', 'en'):
        explanation = q['translations'][language]['explanation']
        if len(explanation) < 100 or '.' not in explanation:
            raise ValueError('Explanations need at least 100 characters and a complete sentence')
    if q.get('image_path') or q.get('video_path'):
        raise ValueError('Images are attached only after generation and review')
    categories = {c['slug'] for c in r.read(root, r.CONTENT / 'pack.json')['categories']}
    if q['category_slug'] not in categories:
        raise ValueError('Unknown question category')
    for lang in ('fr', 'en'):
        if any(not proposal['option_rationale'][lang].get(a, '').strip() for a in 'abcd'):
            raise ValueError('Explain each correct option and distractor in both languages')
    primary = proposal.get('primary_codes', [])
    if len(primary) > 1 or len(set(primary)) != len(primary):
        raise ValueError('At most one primary sign learning target per situation')
    for code in primary:
        if code not in registry['codes']:
            raise ValueError('Unknown sign code')
        if revising_key is None:
            w.assert_available(registry, code, own_batch)
        if q['category_slug'] != registry['codes'][code]['suggested_category_slug']:
            raise ValueError('Sign category differs from its reviewed route')
    for code in proposal.get('context_codes', []):
        if code not in registry['codes']:
            raise ValueError('Unknown contextual sign code')
    previous_scenarios = {x.get('scenario_id') for x in registry['questions'] if x.get('key') != revising_key}
    if proposal['scenario_id'] in previous_scenarios:
        raise ValueError('Scenario already exists')
    for other, scenario_id in candidates:
        if q['key'] == other['key'] or proposal['scenario_id'] == scenario_id:
            raise ValueError('Question/scenario already exists or is reserved')
        if content_hash(q) == content_hash(other):
            raise ValueError('Exact question content already exists')
        for lang in ('fr', 'en'):
            if normalized(q['translations'][lang]['question_text']) == normalized(other['translations'][lang]['question_text']):
                raise ValueError('Repeated question wording needs a different learning situation')


def validate_mix(proposals, expected):
    if len(proposals) != expected or expected not in (2, 10):
        raise ValueError('Expected ten questions, or the final two at 998')
    multiple = sum(len(w.correct_answers(p['question'])) > 1 for p in proposals)
    if multiple != (2 if expected == 10 else 0):
        raise ValueError('A full batch needs eight single-answer and two multiple-answer questions')
    codes = [code for p in proposals for code in p.get('primary_codes', [])]
    if len(codes) != len(set(codes)):
        raise ValueError('Repeated primary sign within batch')


def reserve(root, batch_id, proposals, replace_existing=False):
    path = job_path(batch_id)
    registry = w.fresh(root)
    if (root / BASELINE).exists() and r.read(root, BASELINE).get('status') != 'verified':
        raise ValueError('Finish the outstanding baseline validation before starting batches')
    if (root / path).exists():
        raise ValueError('Batch already exists; resume it')
    if any(b['state'] != 'verified' for b in registry['batches']):
        raise ValueError('Finish and verify the preceding batch first')
    count = registry['counts']['questions']
    if count >= TARGET and not replace_existing:
        raise ValueError('Target already reached')
    validate_mix(proposals, 10 if replace_existing else min(10, TARGET - count))
    keys = [p['question']['key'] for p in proposals]
    if len(set(keys)) != len(keys):
        raise ValueError('Question keys must be distinct within a batch')
    existing = {q['key']: q for q in r.read(root, r.CONTENT / 'pack.json')['questions']}
    decisions = r.read(root, r.REVIEW)
    candidates = all_candidates(root, registry)
    items = []
    files = {}
    for proposal in proposals:
        key = proposal['question']['key']
        comparison = candidates
        previous = None
        if replace_existing:
            old = existing.get(key)
            if old is None or not old.get('image_path') or old.get('video_path'):
                raise ValueError('Replacement batches require existing illustrated questions; preserve text-only records')
            if not proposal.get('replacement_reason', '').strip():
                raise ValueError('Every replacement needs a recorded reason')
            if content_hash(proposal['question']) == content_hash(old):
                raise ValueError('Replacement needs a different learning situation, not the same question')
            if sum(q['key'] == key for q, _ in candidates) != 1:
                raise ValueError('Replacement question key is also reserved elsewhere')
            # Keep the old record in the review comparison, but exclude its key
            # from the collision check because that identity must survive.
            comparison = [(q, s) for q, s in candidates if q['key'] != key]
            for code in proposal.get('primary_codes', []):
                w.assert_available(registry, code, batch_id)
            original_image = r.image_file(old['image_path'])
            archive = ASSETS / batch_id / proposal['scenario_id'] / ('previous-image' + original_image.suffix)
            data = (root / original_image).read_bytes()
            files[archive] = data
            previous = {'question': copy.deepcopy(old), 'question_sha256': r.digest(old),
                        'image_sha256': w.sha(data), 'archived_image_path': str(archive),
                        'sign_review': copy.deepcopy(decisions['questions'].get(key)),
                        'reason': proposal['replacement_reason']}
        validate_proposal(root, registry, proposal, comparison,
                          revising_key=key if replace_existing else None)
        item = {'proposal': proposal, 'state': 'reserved',
                'nearest_questions': nearest(proposal['question'], candidates), 'history': []}
        if previous is not None:
            item['replaces'] = previous
        items.append(item)
        candidates.append((proposal['question'], proposal['scenario_id']))
    batch = {'schema_version': 1, 'id': batch_id, 'state': 'reserved',
             'mode': 'replacement' if replace_existing else 'addition',
             'created_on': str(date.today()), 'target': TARGET, 'questions_before': count,
             'pack_before_sha256': r.file_hash(root, r.CONTENT / 'pack.json'), 'items': items}
    files[path] = w.js(batch)
    for p in proposals:
        files[ASSETS / batch_id / p['scenario_id'] / 'prompt.md'] = (p['image_prompt'] + '\n').encode()
    w.commit(root, files)
    return batch


def editable(root, batch_id, scenario_id):
    registry = w.fresh(root)
    batch = r.read(root, job_path(batch_id))
    if batch['state'] != 'reserved':
        raise ValueError('Imported batches cannot be edited through staging')
    item = next((i for i in batch['items'] if i['proposal']['scenario_id'] == scenario_id), None)
    if item is None:
        raise ValueError('Scenario is not in this batch')
    return registry, batch, item


def image_size(data):
    if data.startswith(b'\x89PNG\r\n\x1a\n') and data[12:16] == b'IHDR':
        width, height = struct.unpack('>II', data[16:24])
        return width, height, '.png'
    if data.startswith(b'\xff\xd8'):
        offset = 2
        while offset + 4 <= len(data):
            if data[offset] != 255:
                break
            marker = data[offset + 1]
            length = int.from_bytes(data[offset + 2:offset + 4], 'big')
            if marker in (0xC0, 0xC1, 0xC2):
                height, width = struct.unpack('>HH', data[offset + 5:offset + 9])
                return width, height, '.jpg'
            if length < 2:
                break
            offset += length + 2
    raise ValueError('Expected a decodable PNG/JPEG scene')


def duplicate_image(registry, digest, own_item=None):
    existing = [q.get('image_sha256') for q in registry['questions']]
    existing += [j.get('image_sha256') for j in registry['jobs']]
    existing += [h for draft in registry['drafts'] for h in draft['files'].values()]
    for batch in registry['batches']:
        for item in batch['items']:
            if (batch['id'], item['proposal']['scenario_id']) != own_item:
                existing.append(item.get('image_sha256'))
    if digest in existing:
        raise ValueError('Exact scene image already exists in bank/drafts/jobs')


def stage(root, batch_id, scenario_id, image, prompt):
    registry, batch, item = editable(root, batch_id, scenario_id)
    if not prompt.strip():
        raise ValueError('Save the exact generation/edit prompt with each candidate')
    if len(item['history']) >= 4:
        raise ValueError('Three corrections exhausted; replace this candidate')
    data = Path(image).read_bytes()
    width, height, suffix = image_size(data)
    if width < 1000 or height < 560 or not 1.65 <= width / height <= 1.9:
        raise ValueError('Scene must be a sufficiently detailed landscape image near 16:9')
    digest = w.sha(data)
    duplicate_image(registry, digest, (batch_id, scenario_id))
    if any(h['image_sha256'] == digest for h in item['history']):
        raise ValueError('This exact candidate is already saved; review or generate a correction')
    attempt = len(item['history']) + 1
    folder = ASSETS / batch_id / scenario_id
    path = folder / f'scene-{attempt}{suffix}'
    item.pop('review', None)
    item.update(state='staged', image_path=str(path), image_sha256=digest,
                dimensions=[width, height])
    item['history'].append({'image_path': str(path), 'image_sha256': digest,
                            'prompt': prompt, 'created_on': str(date.today())})
    w.commit(root, {path: data, folder / f'prompt-{attempt}.md': (prompt + '\n').encode(),
                    job_path(batch_id): w.js(batch)})
    return item


def review(root, batch_id, scenario_id, receipt):
    _, batch, item = editable(root, batch_id, scenario_id)
    if item['state'] != 'staged':
        raise ValueError('Review requires the currently staged candidate')
    validate_receipt(item, receipt)
    receipt = {**receipt, 'recorded_on': str(date.today())}
    item['review'] = receipt
    item['history'][-1]['review'] = receipt
    item['state'] = 'reviewed' if receipt['result'] == 'pass' else 'rejected'
    w.commit(root, {job_path(batch_id): w.js(batch)})
    return item


def validate_receipt(item, receipt):
    if (receipt.get('proposal_sha256') != r.digest(item['proposal'])
            or receipt.get('image_sha256') != item['image_sha256']):
        raise ValueError('Review does not match the current proposal and image')
    if receipt.get('result') not in ('pass', 'reject') or not receipt.get('notes', '').strip():
        raise ValueError('An explicit inspection result and notes are required')
    if receipt['result'] == 'pass':
        if any(not isinstance(receipt.get('checks', {}).get(k), str)
               or not receipt['checks'][k].strip() for k in CHECKS):
            raise ValueError('Every visual/content check needs specific observations')
        compared = set(receipt.get('compared_question_keys', []))
        if not {q['key'] for q in item['nearest_questions']} <= compared:
            raise ValueError('Inspect and distinguish the nearest existing questions before approval')


def amend(root, batch_id, revisions):
    """Repair wording after failed integration; keep keys, images and answer sets.

    Every changed proposal requires a fresh complete inspection receipt. Old
    proposals/reviews remain in the audit trail. The journal makes retries safe.
    """
    registry = w.fresh(root)
    batch = r.read(root, job_path(batch_id))
    if batch['state'] != 'imported':
        raise ValueError('Only an imported, not-yet-verified batch can be amended')
    if r.file_hash(root, r.CONTENT / 'pack.json') != batch['pack_after_sha256']:
        raise ValueError('Bank changed since import; reconcile before amending')
    if not revisions or len({v['scenario_id'] for v in revisions}) != len(revisions):
        raise ValueError('Supply distinct wording revisions')
    pack = r.read(root, r.CONTENT / 'pack.json')
    decisions = r.read(root, r.REVIEW)
    changed = []
    for revision in revisions:
        item = next(i for i in batch['items'] if i['proposal']['scenario_id'] == revision['scenario_id'])
        proposal = revision['proposal']
        permitted = copy.deepcopy(item['proposal'])
        permitted['question']['translations'] = proposal['question']['translations']
        if permitted != proposal or not revision.get('reason', '').strip():
            raise ValueError('Wording amendment must preserve key, answer set, image and objective and include a reason')
        if proposal == item['proposal']:
            continue  # Safe retry of the exact amendment.
        key = proposal['question']['key']
        candidates = [(q, sid) for q, sid in all_candidates(root, registry, batch_id) if q['key'] != key]
        validate_proposal(root, registry, proposal, candidates, batch_id, revising_key=key)
        current = next(q for q in pack['questions'] if q['key'] == key)
        if (r.digest(current) != item['imported_question_sha256']
                or r.file_hash(root, r.image_file(current['image_path'])) != item['image_sha256']
                or r.file_hash(root, Path(item['image_path'])) != item['image_sha256']):
            raise ValueError('Imported question/image changed; reconcile before amending')
        reviewed = {**item, 'proposal': proposal}
        validate_receipt(reviewed, revision['review'])
        if revision['review']['result'] != 'pass':
            raise ValueError('Amendment requires a new passing full review')
        item.setdefault('amendments', []).append({
            'previous_proposal': item['proposal'], 'previous_review': item['review'],
            'previous_question_sha256': item['imported_question_sha256'],
            'reason': revision['reason'], 'recorded_on': str(date.today())})
        item['proposal'] = proposal
        item['review'] = {**revision['review'], 'recorded_on': str(date.today())}
        current['translations'] = proposal['question']['translations']
        item['imported_question_sha256'] = r.digest(current)
        decisions['questions'][key]['source_sha256'] = r.digest({'record': current, 'image_sha256': item['image_sha256']})
        decisions['questions'][key]['note'] = revision['review']['notes']
        changed.append(key)
    if not changed:
        return batch
    schema = (root / w.SCHEMA).read_text()
    match = re.search(r'contentVersion: Int64 = (\d+)', schema)
    version = int(match[1]) + 1
    schema = schema[:match.start(1)] + str(version) + schema[match.end(1):]
    batch.setdefault('integration_amendments', []).append({
        'previous_pack_sha256': batch['pack_after_sha256'],
        'previous_content_version': batch['content_version'], 'question_keys': changed})
    batch.update(content_version=version, pack_after_sha256=w.sha(w.js(pack)))
    batch.pop('verification', None)
    w.commit(root, {r.CONTENT / 'pack.json': w.js(pack), r.REVIEW: w.js(decisions),
                    w.SCHEMA: schema.encode(), job_path(batch_id): w.js(batch)})
    return batch


def replace(root, batch_id, scenario_id, proposal, reason):
    registry, batch, item = editable(root, batch_id, scenario_id)
    if not reason.strip():
        raise ValueError('Replacement/revision needs a reason')
    others = [i for i in batch['items'] if i is not item]
    candidates = all_candidates(root, registry, batch_id)
    candidates += [(i['proposal']['question'], i['proposal']['scenario_id']) for i in others]
    replacing = batch.get('mode') == 'replacement'
    key = item['proposal']['question']['key']
    if replacing and proposal['question']['key'] != key:
        raise ValueError('Replacement must preserve the stable question key')
    comparison = [(q, s) for q, s in candidates if q['key'] != key] if replacing else candidates
    if replacing:
        for code in proposal.get('primary_codes', []):
            w.assert_available(registry, code, batch_id)
    validate_proposal(root, registry, proposal, comparison, batch_id,
                      revising_key=key if replacing else None)
    if len(item['history']) >= 4 and proposal['scenario_id'] == scenario_id:
        raise ValueError('After three corrections choose a different situation')
    validate_mix([i['proposal'] for i in others] + [proposal], len(batch['items']))
    new = {'proposal': proposal, 'state': 'reserved',
           'history': item['history'] if proposal['scenario_id'] == scenario_id else [],
           'nearest_questions': nearest(proposal['question'], candidates),
           'replacements': item.get('replacements', []) + [{'reason': reason, 'previous': {
               k: v for k, v in item.items() if k != 'replacements'}}]}
    if replacing:
        new['replaces'] = copy.deepcopy(item['replaces'])
    batch['items'][batch['items'].index(item)] = new
    w.commit(root, {job_path(batch_id): w.js(batch),
                    ASSETS / batch_id / proposal['scenario_id'] / 'prompt.md':
                    (proposal['image_prompt'] + '\n').encode()})
    return new


def repair(root, batch_id, revision):
    """Replace a defective imported item without changing its stable database key.

    Requires a newly authored objective/image and a complete exact-file review.
    The previous item and verification are retained; all integration checks must
    run again. The existing journal provides interrupted-write recovery.
    """
    registry = w.fresh(root)
    batch = r.read(root, job_path(batch_id))
    repair_id = identifier(revision['repair_id'])
    for prior in batch.get('content_repairs', []):
        if prior['repair_id'] == repair_id:
            if prior['revision_sha256'] != r.digest(revision):
                raise ValueError('Repair identifier reused with different content')
            return batch
    if batch['state'] not in ('imported', 'verified'):
        raise ValueError('Repair requires an imported batch')
    if r.file_hash(root, r.CONTENT / 'pack.json') != batch['pack_after_sha256']:
        raise ValueError('Bank changed since import; reconcile before repairing')
    if not revision.get('reason', '').strip():
        raise ValueError('Repair needs a reason')
    item = next(i for i in batch['items'] if i['proposal']['scenario_id'] == revision['scenario_id'])
    proposal = revision['proposal']
    key = item['proposal']['question']['key']
    if proposal['question']['key'] != key:
        raise ValueError('Repair must preserve the stable question key')
    if revision['previous_question_sha256'] != item['imported_question_sha256']:
        raise ValueError('Repair was prepared against a stale question')
    pack = r.read(root, r.CONTENT / 'pack.json')
    index = next(i for i, q in enumerate(pack['questions']) if q['key'] == key)
    old = pack['questions'][index]
    if (r.digest(old) != item['imported_question_sha256'] or
            r.file_hash(root, r.image_file(old['image_path'])) != item['image_sha256']):
        raise ValueError('Imported question/image changed before repair')
    candidates = [(q, sid) for q, sid in all_candidates(root, registry, batch_id) if q['key'] != key]
    validate_proposal(root, registry, proposal, candidates, batch_id, revising_key=key)
    for code in set(proposal.get('primary_codes', [])) - set(item['proposal'].get('primary_codes', [])):
        w.assert_available(registry, code, batch_id)
    validate_mix([proposal if i is item else i['proposal'] for i in batch['items']], len(batch['items']))
    path = Path(revision['image_path'])
    if path.is_absolute() or '..' in path.parts or not path.is_relative_to(ASSETS / batch_id):
        raise ValueError('Repair image must be saved inside this batch asset folder')
    data = (root / path).read_bytes()
    width, height, suffix = image_size(data)
    if width < 1000 or height < 560 or not 1.65 <= width / height <= 1.9:
        raise ValueError('Repair image must be detailed landscape near 16:9')
    digest = w.sha(data)
    duplicate_image(registry, digest)
    new = dict(proposal=proposal, state='reviewed', image_path=str(path), image_sha256=digest,
               dimensions=[width, height], nearest_questions=nearest(proposal['question'], candidates),
               history=[dict(image_path=str(path), image_sha256=digest, prompt=proposal['image_prompt'],
                             created_on=str(date.today()), review=revision['review'])], review=revision['review'])
    validate_receipt(new, revision['review'])
    if revision['review']['result'] != 'pass':
        raise ValueError('Repair requires a passing complete review')
    q = copy.deepcopy(proposal['question'])
    q['correct_answers'] = w.correct_answers(q)
    q.pop('correct_answer', None)
    q['image_path'] = 'france/' + key + suffix
    pack['questions'][index] = q
    new['imported_question_sha256'] = r.digest(q)
    batch.setdefault('content_repairs', []).append(dict(repair_id=repair_id,
        revision_sha256=r.digest(revision), reason=revision['reason'], previous_item=copy.deepcopy(item),
        previous_verification=batch.pop('verification', None), previous_pack_sha256=batch['pack_after_sha256'],
        previous_content_version=batch['content_version'], recorded_on=str(date.today())))
    batch['items'][batch['items'].index(item)] = new
    batch.pop('verified_on', None)
    decisions = r.read(root, r.REVIEW)
    codes = proposal.get('primary_codes', [])
    decisions['questions'][key] = dict(status='mapped' if codes else 'no_sign_target',
        primary_codes=codes, context_codes=proposal.get('context_codes', []), scenario_id=proposal['scenario_id'],
        source_sha256=r.digest({'record': q, 'image_sha256': digest}),
        note=revision['review']['notes'], reviewed_on=str(date.today()))
    sources = (root / SOURCES).read_bytes()
    sources += ('' if not sources or sources.endswith(b'\n') else '\n').encode()
    sources += (json.dumps(dict(question_key=key, batch_id=batch_id, repair_id=repair_id,
        sources=proposal['sources'], learning_objective=proposal['learning_objective'], topic=proposal['topic'],
        reviewed_on=str(date.today())), ensure_ascii=False) + '\n').encode()
    schema = (root / w.SCHEMA).read_text()
    match = re.search(r'contentVersion: Int64 = (\d+)', schema)
    version = int(match[1]) + 1
    schema = schema[:match.start(1)] + str(version) + schema[match.end(1):]
    batch.update(state='imported', content_version=version, pack_after_sha256=w.sha(w.js(pack)))
    w.commit(root, {r.CONTENT / 'pack.json': w.js(pack), r.image_file(q['image_path']): data,
        r.REVIEW: w.js(decisions), SOURCES: sources, w.SCHEMA: schema.encode(), job_path(batch_id): w.js(batch)})
    return batch


def import_batch(root, batch_id):
    registry = w.fresh(root)
    batch = r.read(root, job_path(batch_id))
    if batch['state'] in ('imported', 'verified'):
        return {'id': batch_id, 'state': 'already_imported', 'questions_after': batch['questions_after']}
    pack_path = r.CONTENT / 'pack.json'
    if r.file_hash(root, pack_path) != batch['pack_before_sha256']:
        raise ValueError('Bank changed since reservation; reconcile before importing')
    proposals = [i['proposal'] for i in batch['items']]
    replacing = batch.get('mode') == 'replacement'
    validate_mix(proposals, 10 if replacing else min(10, TARGET - registry['counts']['questions']))
    candidates = all_candidates(root, registry, batch_id)
    pack = r.read(root, pack_path)
    original_keys = [q['key'] for q in pack['questions']]
    indexes = {q['key']: index for index, q in enumerate(pack['questions'])}
    decisions = r.read(root, r.REVIEW)
    sources = (root / SOURCES).read_bytes() if (root / SOURCES).exists() else b''
    if sources and not sources.endswith(b'\n'):
        sources += b'\n'
    files = {}
    for item in batch['items']:
        p = item['proposal']
        key = p['question']['key']
        comparison = [(q, s) for q, s in candidates if q['key'] != key] if replacing else candidates
        if replacing:
            previous = item['replaces']
            old = pack['questions'][indexes[key]]
            if (r.digest(old) != previous['question_sha256']
                    or r.digest(previous['question']) != previous['question_sha256']
                    or r.file_hash(root, r.image_file(old['image_path'])) != previous['image_sha256']
                    or r.file_hash(root, Path(previous['archived_image_path'])) != previous['image_sha256']):
                raise ValueError('Original question/image or its archive changed before replacement')
            if content_hash(p['question']) == content_hash(old):
                raise ValueError('Replacement needs a different learning situation, not the same question')
            for code in p.get('primary_codes', []):
                w.assert_available(registry, code, batch_id)
        validate_proposal(root, registry, p, comparison, batch_id,
                          revising_key=key if replacing else None)
        receipt = item.get('review', {})
        if (item['state'] != 'reviewed' or receipt.get('result') != 'pass'
                or receipt.get('proposal_sha256') != r.digest(p)
                or receipt.get('image_sha256') != item.get('image_sha256')):
            raise ValueError('Every current question and image must pass review before batch import')
        data = (root / item['image_path']).read_bytes()
        if w.sha(data) != item['image_sha256']:
            raise ValueError('Image changed after review')
        duplicate_image(registry, item['image_sha256'], (batch_id, p['scenario_id']))
        q = dict(p['question'])
        q['correct_answers'] = w.correct_answers(q)
        q.pop('correct_answer', None)
        q['image_path'] = 'france/' + q['key'] + Path(item['image_path']).suffix
        target = r.image_file(q['image_path'])
        if (root / target).exists() and (not replacing or target != r.image_file(old['image_path'])):
            raise ValueError('Destination image already exists')
        files[target] = data
        if replacing:
            pack['questions'][indexes[key]] = q
        else:
            pack['questions'].append(q)
        codes = p.get('primary_codes', [])
        decisions['questions'][q['key']] = {
            'status': 'mapped' if codes else 'no_sign_target', 'primary_codes': codes,
            'context_codes': p.get('context_codes', []), 'scenario_id': p['scenario_id'],
            'source_sha256': r.digest({'record': q, 'image_sha256': item['image_sha256']}),
            'note': receipt['notes'], 'reviewed_on': str(date.today())}
        for code in codes:
            decisions['scope'][code] = 'ordinary_car_learning_target'
        sources += (json.dumps({'question_key': q['key'], 'batch_id': batch_id,
                               'reviewed_on': str(date.today()), 'sources': p['sources'],
                               'learning_objective': p['learning_objective'], 'topic': p['topic']},
                              ensure_ascii=False) + '\n').encode()
        item['imported_question_sha256'] = r.digest(q)
        candidates.append((q, p['scenario_id']))
    if replacing and [q['key'] for q in pack['questions']] != original_keys:
        raise ValueError('Replacement must preserve every existing question key and count')
    schema = (root / w.SCHEMA).read_text()
    match = re.search(r'contentVersion: Int64 = (\d+)', schema)
    if not match:
        raise ValueError('Cannot find content version')
    version = int(match[1]) + 1
    schema = schema[:match.start(1)] + str(version) + schema[match.end(1):]
    batch.update(state='imported', imported_on=str(date.today()), content_version=version,
                 questions_after=len(pack['questions']), pack_after_sha256=w.sha(w.js(pack)))
    files.update({pack_path: w.js(pack), r.REVIEW: w.js(decisions), w.SCHEMA: schema.encode(),
                  SOURCES: sources, job_path(batch_id): w.js(batch)})
    w.commit(root, files)
    return batch


def verify(root, batch_id, evidence):
    registry = w.fresh(root)
    batch = r.read(root, job_path(batch_id))
    if batch['state'] not in ('imported', 'verified'):
        raise ValueError('Import before checking integration')
    pack_digest = r.file_hash(root, r.CONTENT / 'pack.json')
    if pack_digest != batch['pack_after_sha256'] or evidence.get('pack_sha256') != pack_digest:
        raise ValueError('Verification must cover the exact imported bank')
    if evidence.get('content_version') != batch['content_version']:
        raise ValueError('Verification content version mismatch')
    if registry['counts']['questions'] != batch['questions_after']:
        raise ValueError('Unexpected question count')
    if registry['exact_duplicate_content_groups'] or registry['exact_duplicate_image_groups']:
        raise ValueError('Duplicate content/images detected')
    for name in EVIDENCE:
        check = evidence.get(name, {})
        path = Path(check.get('path', ''))
        if (check.get('result') != 'pass' or not check.get('notes', '').strip()
                or path.is_absolute() or '..' in path.parts or not (root / path).is_file()
                or r.file_hash(root, path) != check.get('sha256')):
            raise ValueError(f'Missing/current passing evidence required: {name}')
    batch.update(state='verified', verified_on=str(date.today()), verification=evidence)
    w.commit(root, {job_path(batch_id): w.js(batch)})
    return batch


def status(root):
    registry = w.fresh(root)
    blueprint = r.read(root, r.CONTENT / 'blueprint.json')['mock_exam_quotas']
    counts = registry['counts']['questions_by_category']
    return {'target': TARGET, 'counts': registry['counts'],
            'remaining': max(0, TARGET - registry['counts']['questions']),
            'category_targets': {k: TARGET * v // sum(blueprint.values()) for k, v in blueprint.items()},
            'category_deficits': {k: TARGET * v // sum(blueprint.values()) - counts.get(k, 0)
                                  for k, v in blueprint.items()},
            'batches': [{'id': b['id'], 'state': b['state'],
                         'items': dict(Counter(i['state'] for i in b['items']))} for b in registry['batches']]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['status', 'reserve', 'reserve-replacements', 'stage', 'review', 'replace', 'import', 'amend', 'repair', 'verify', 'recover'])
    parser.add_argument('batch', nargs='?')
    parser.add_argument('scenario', nargs='?')
    parser.add_argument('--json', type=Path, help='Proposals array, replacement proposal, review or verification receipt')
    parser.add_argument('--image', type=Path)
    parser.add_argument('--prompt', type=Path, help='Exact generation/edit prompt')
    parser.add_argument('--reason', default='')
    args = parser.parse_args()
    try:
        with w.locked(r.ROOT):
            value = json.loads(args.json.read_text()) if args.json else None
            if args.command == 'status': result = status(r.ROOT)
            elif args.command == 'recover': w.recover(r.ROOT); result = {'state': 'recovered'}
            elif args.command == 'reserve': result = reserve(r.ROOT, args.batch, value)
            elif args.command == 'reserve-replacements': result = reserve(r.ROOT, args.batch, value, replace_existing=True)
            elif args.command == 'stage': result = stage(r.ROOT, args.batch, args.scenario, args.image, args.prompt.read_text())
            elif args.command == 'review': result = review(r.ROOT, args.batch, args.scenario, value)
            elif args.command == 'replace': result = replace(r.ROOT, args.batch, args.scenario, value, args.reason)
            elif args.command == 'import': result = import_batch(r.ROOT, args.batch)
            elif args.command == 'amend': result = amend(r.ROOT, args.batch, value)
            elif args.command == 'repair': result = repair(r.ROOT, args.batch, value)
            else: result = verify(r.ROOT, args.batch, value)
            if args.command != 'status':
                result = {key: result[key] for key in ('id', 'state', 'questions_after', 'image_path', 'image_sha256') if key in result}
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError, AttributeError, struct.error) as error:
        print(f'BATCH BLOCKED: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
