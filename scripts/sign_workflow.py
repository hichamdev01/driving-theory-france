#!/usr/bin/env python3
"""Local reviewed sign-question workflow. Image generation is performed by Codex."""
import argparse
import base64
from contextlib import contextmanager
from datetime import date
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile

import sign_registry as r

ASSETS = Path('assets-source/sign-workflow')
JOURNAL = r.JOBS / '.transaction.json'
SCHEMA = Path('TheoryPrep/Database/Schema.swift')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(root, path, data):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=target.parent, prefix='.' + target.name)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def js(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


@contextmanager
def locked(root):
    # Kernel releases the lock on process exit, including crashes. Never delete it.
    name = 'theoryprep-sign-workflow-' + sha(str(root.resolve()).encode())[:20] + '.lock'
    with open(Path(tempfile.gettempdir()) / name, 'a') as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def refresh(root):
    registry = r.build(root)
    if registry['validation_errors']:
        raise ValueError('\n'.join(registry['validation_errors']))
    write(root, r.REGISTRY, r.rendered(registry).encode())
    write(root, r.REPORT, r.report(registry).encode())
    return registry


def fresh(root):
    if (root / JOURNAL).exists():
        raise ValueError('Interrupted transaction; run recover before doing more work.')
    registry = r.build(root)
    if registry['validation_errors'] or (root / r.REGISTRY).read_text() != r.rendered(registry):
        raise ValueError('Registry is stale or has invalid inputs; review and rebuild first.')
    return registry


def recover(root):
    transaction = r.read(root, JOURNAL)
    # Check all files before changing any: refuse to overwrite unrelated user edits.
    for item in transaction['files']:
        target = root / item['path']
        current = sha(target.read_bytes()) if target.exists() else None
        if current not in (item['before_sha256'], item['after_sha256']):
            raise ValueError(f'Concurrent edit requires reconciliation: {item["path"]}')
    for item in transaction['files']:
        write(root, item['path'], base64.b64decode(item['after']))
    refresh(root)
    (root / JOURNAL).unlink()


def commit(root, files):
    entries = []
    for path, data in files.items():
        target = root / path
        entries.append({'path': str(path), 'before_sha256': sha(target.read_bytes()) if target.exists() else None,
                        'after_sha256': sha(data), 'after': base64.b64encode(data).decode()})
    write(root, JOURNAL, js({'files': entries}))
    recover(root)


def canonical(registry, value):
    token = re.sub(r'\s+', '', value).casefold()
    return next((c for c in registry['codes'] if c.casefold() == token), None)


def assert_available(registry, code, own_job=None):
    entry = registry['codes'][code]
    for field in ('question_keys', 'supplementary_question_keys', 'context_question_keys', 'draft_ids', 'review_holds'):
        if entry[field]:
            raise ValueError(f'{code}: skip existing coverage/draft or unresolved hold ({field})')
    if any(j != own_job for j in entry['pending_job_ids']):
        raise ValueError(f'{code}: another job already reserved this code')
    if entry['car_scope'] == 'excluded_from_car_generation':
        raise ValueError(f'{code}: outside passenger-car generation scope')


def validate_proposal(registry, proposal):
    code = canonical(registry, proposal['code'])
    if code is None or proposal['code'] != code:
        raise ValueError('Proposal needs an exact known canonical code')
    if proposal['scope'] != 'ordinary_passenger_car' or not proposal['scope_review'].strip():
        raise ValueError('A reviewed passenger-car learning objective is required')
    if not re.fullmatch(r'[a-z0-9_]+', proposal['scenario_id']):
        raise ValueError('Invalid scenario identity')
    for field in ('scenario', 'novelty_review', 'image_prompt'):
        if not proposal[field].strip():
            raise ValueError(f'Missing {field}')
    if not proposal['references'] or any(not url.startswith('https://') for url in proposal['references']):
        raise ValueError('Verified reference URLs are required')
    q = proposal['question']
    if not re.fullmatch(r'situation_[a-z0-9_]+', q['key']):
        raise ValueError('Invalid stable question key')
    if q['category_slug'] != registry['codes'][code]['suggested_category_slug']:
        raise ValueError('Category differs from the reviewed registry route')
    if q.get('correct_answer') not in ('a', 'b', 'c', 'd') or 'correct_answers' in q:
        raise ValueError('Pilot workflow requires exactly one correct answer')
    if q['difficulty'] not in ('easy', 'medium', 'hard'):
        raise ValueError('Invalid difficulty')
    for lang in ('fr', 'en'):
        for field in ('question_text', 'answer_a', 'answer_b', 'answer_c', 'answer_d', 'explanation'):
            if not isinstance(q['translations'][lang][field], str) or not q['translations'][lang][field].strip():
                raise ValueError(f'Missing translation: {lang}/{field}')
        if len({q['translations'][lang]['answer_' + a].strip() for a in 'abcd'}) != 4:
            raise ValueError('Answer choices must be distinct')
    return code


def reserve(root, proposal):
    registry = fresh(root)
    code = validate_proposal(registry, proposal)
    assert_available(registry, code)
    path = r.JOBS / (code + '.json')
    if (root / path).exists():
        raise ValueError(f'{code}: job already exists; resume it instead of regenerating')
    for job in registry['jobs']:
        if job['proposal']['scenario_id'] == proposal['scenario_id']:
            raise ValueError('Scenario is already reserved/imported')
    job = {'id': code, 'code': code, 'state': 'reserved', 'created_on': str(date.today()), 'proposal': proposal}
    commit(root, {path: js(job)})
    return job


def stage(root, code, image):
    registry = fresh(root)
    job = r.read(root, r.JOBS / (code + '.json'))
    assert_available(registry, code, code)
    if job['state'] not in ('reserved', 'staged', 'reviewed'):
        raise ValueError('Cannot replace an imported image through staging')
    data = Path(image).read_bytes()
    suffix = '.png' if data.startswith(b'\x89PNG\r\n\x1a\n') else '.jpg' if data.startswith(b'\xff\xd8\xff') else None
    if not suffix:
        raise ValueError('Expected a PNG or JPEG scene image')
    path = ASSETS / code / ('scene' + suffix)
    job.pop('reviewed_sha256', None)
    job.pop('review_note', None)
    job.update(state='staged', image_path=str(path), image_sha256=sha(data))
    commit(root, {path: data, r.JOBS / (code + '.json'): js(job)})
    return job


def review(root, code, note):
    fresh(root)
    job = r.read(root, r.JOBS / (code + '.json'))
    if job['state'] != 'staged' or not note.strip():
        raise ValueError('Review needs a staged image and an explicit visual/content review note')
    job.update(state='reviewed', review_note=note, reviewed_sha256=r.digest([job['proposal'], job['image_sha256']]))
    commit(root, {r.JOBS / (code + '.json'): js(job)})
    return job


def import_question(root, code):
    registry = fresh(root)
    jobpath = r.JOBS / (code + '.json')
    job = r.read(root, jobpath)
    if job['state'] == 'imported':
        return {'id': code, 'state': 'already_imported', 'question_key': job['question_key']}
    assert_available(registry, code, code)
    validate_proposal(registry, job['proposal'])
    if job['state'] != 'reviewed' or job.get('reviewed_sha256') != r.digest([job['proposal'], job['image_sha256']]):
        raise ValueError('Current proposal and image must pass visual/content review first')
    q = dict(job['proposal']['question'])
    q['image_path'] = 'france/' + q['key'] + Path(job['image_path']).suffix
    target = r.image_file(q['image_path'])
    if (root / target).exists() or any(x['key'] == q['key'] for x in registry['questions']):
        raise ValueError('Question key or destination image already exists')
    content = r.digest({'translations': q['translations'], 'correct_answers': [q['correct_answer']]})
    if any(x['content_sha256'] == content or x['image_sha256'] == job['image_sha256'] for x in registry['questions']):
        raise ValueError('Exact question or scene image already exists')
    pack = r.read(root, r.CONTENT / 'pack.json')
    pack['questions'].append(q)
    decisions = r.read(root, r.REVIEW)
    decisions['questions'][q['key']] = {'status': 'mapped', 'primary_codes': [code],
        'source_sha256': r.digest({'record': q, 'image_sha256': job['image_sha256']}),
        'note': job['review_note'], 'reviewed_on': str(date.today()), 'scenario_id': job['proposal']['scenario_id']}
    decisions['scope'][code] = 'ordinary_car_learning_target'
    schema = (root / SCHEMA).read_text()
    match = re.search(r'contentVersion: Int64 = (\d+)', schema)
    if not match:
        raise ValueError('Cannot find content version')
    version = int(match[1]) + 1
    schema = schema[:match.start(1)] + str(version) + schema[match.end(1):]
    job.update(state='imported', question_key=q['key'], imported_content_version=version, imported_on=str(date.today()))
    commit(root, {target: (root / job['image_path']).read_bytes(), r.CONTENT / 'pack.json': js(pack),
                  r.REVIEW: js(decisions), SCHEMA: schema.encode(), jobpath: js(job)})
    return job


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['reserve', 'stage', 'review', 'import', 'recover'])
    parser.add_argument('code', nargs='?')
    parser.add_argument('--proposal', type=Path)
    parser.add_argument('--image', type=Path)
    parser.add_argument('--note')
    args = parser.parse_args()
    try:
        with locked(r.ROOT):
            if args.command == 'recover':
                recover(r.ROOT)
                print('Transaction recovered and registry refreshed.')
                return 0
            registry = fresh(r.ROOT)
            code = canonical(registry, args.code or '')
            if not code:
                raise ValueError('A known sign code is required')
            if args.command == 'reserve':
                proposal = json.loads(args.proposal.read_text())
                if proposal['code'] != code:
                    raise ValueError('Proposal code mismatch')
                result = reserve(r.ROOT, proposal)
            elif args.command == 'stage':
                result = stage(r.ROOT, code, args.image)
            elif args.command == 'review':
                result = review(r.ROOT, code, args.note or '')
            else:
                result = import_question(r.ROOT, code)
            print(json.dumps({k: result[k] for k in ('id', 'state', 'question_key') if k in result}))
            return 0
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        print(f'WORKFLOW BLOCKED: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
