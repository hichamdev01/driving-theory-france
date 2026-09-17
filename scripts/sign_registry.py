#!/usr/bin/env python3
"""Build/check the France authoring inventory; never writes app content or SQLite."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CONTENT = Path('TheoryPrep/Resources/Content/france')
AUDIT = Path('docs/content-audit')
REVIEW = AUDIT / 'france-sign-review.json'
REGISTRY = AUDIT / 'france-sign-registry.json'
REPORT = AUDIT / 'france-sign-audit.md'
JOBS = AUDIT / 'sign-jobs'


def encoded(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


def digest(value):
    return hashlib.sha256(encoded(value)).hexdigest()


def read(root, path):
    return json.loads((root / path).read_text())


def file_hash(root, path):
    return hashlib.sha256((root / path).read_bytes()).hexdigest()


def image_file(image_path):
    if not image_path or not re.fullmatch(r'france/[^/]+\.(png|jpg|jpeg)', image_path):
        raise ValueError(f'Unsupported image path: {image_path!r}')
    return CONTENT / 'images' / Path(image_path).name


def identity(item, root):
    """Review is bound to both metadata and the exact referenced image bytes."""
    path = item.get('image_path')
    return digest({'record': item, 'image_sha256': file_hash(root, image_file(path)) if path else None})


def active_signs(pack, catalogue):
    # Mirror ContentLoader's canonical-category override and image deduplication.
    categories = {x['slug'] for x in catalogue['categories']}
    additional = {x['slug'] for x in pack['roadSignCategories']} - categories
    images = {x.get('image_path') for x in catalogue['signs'] if x.get('image_path')}
    return catalogue['signs'] + [x for x in pack['roadSigns']
        if x['road_sign_category_slug'] in additional
        and (not x.get('image_path') or x['image_path'] not in images)]


def duplicates(records, field):
    groups = defaultdict(list)
    for record in records:
        if record.get(field):
            groups[record[field]].append(record['key'])
    return sorted([sorted(keys) for keys in groups.values() if len(keys) > 1])


def build(root=ROOT):
    pack = read(root, CONTENT / 'pack.json')
    catalogue = read(root, CONTENT / 'road-signs.json')
    review = read(root, REVIEW)
    if review['schema_version'] != 1:
        raise ValueError('Unsupported review schema version')
    categories = {x['slug'] for x in pack['categories']}
    errors, questions, signs = [], [], []
    manifest = {}
    paths = {CONTENT / 'pack.json', CONTENT / 'road-signs.json', REVIEW,
             Path('scripts/sign_registry.py'), Path('TheoryPrep/Models/ContentPack.swift'),
             Path('docs/CONTENT_GUIDE.md')}
    known = set(review['known_codes'])
    if len({x.casefold() for x in known}) != len(known):
        raise ValueError('Ambiguous code normalization')
    index = {code: {'code': code, 'question_keys': [], 'supplementary_question_keys': [],
        'context_question_keys': [], 'comparison_question_keys': [], 'catalogue_images': [],
        'review_holds': [], 'draft_ids': [], 'pending_job_ids': [], 'existing_categories': []} for code in sorted(known)}

    def attach(mapping, source, question=False):
        if mapping['status'] not in ('mapped', 'no_sign_target', 'needs_review', 'unreviewed'):
            raise ValueError(f'{source}: invalid review status')
        if mapping['status'] == 'mapped' and not mapping.get('primary_codes'):
            raise ValueError(f'{source}: mapped record needs a primary code')
        if mapping['status'] == 'no_sign_target' and mapping.get('primary_codes'):
            raise ValueError(f'{source}: no_sign_target cannot have primary codes')
        fields = {'primary_codes': 'question_keys', 'supplementary_codes': 'supplementary_question_keys',
                  'context_codes': 'context_question_keys', 'comparison_codes': 'comparison_question_keys'}
        for field in (*fields, 'candidate_codes'):
            for code in mapping.get(field, []):
                if code not in index:
                    raise ValueError(f'{source}: unknown reviewed code {code}')
                if question and field in fields:
                    index[code][fields[field]].append(source)
                if field == 'candidate_codes' or mapping['status'] == 'needs_review':
                    index[code]['review_holds'].append(source)

    raw_questions = pack['questions']
    keys = [q.get('key') for q in raw_questions]
    if any(not key for key in keys) or len(set(keys)) != len(keys):
        raise ValueError('Missing or duplicate stable question keys')
    for q in sorted(raw_questions, key=lambda x: x['key']):
        key = q['key']
        mapping = review['questions'].get(key)
        if mapping is None or mapping.get('source_sha256') != identity(q, root):
            errors.append(f'Question needs current review: {key}')
            mapping = {'status': 'unreviewed', 'primary_codes': [], 'note': 'Missing or stale review.'}
        if q['category_slug'] not in categories:
            errors.append(f'Unknown category: {key}')
        answers = q.get('correct_answers') or [q.get('correct_answer')]
        if not answers or any(a not in 'abcd' for a in answers if isinstance(a, str)) or any(not isinstance(a, str) or len(a) != 1 for a in answers):
            errors.append(f'Invalid correct answers: {key}')
        for lang in pack['languages']:
            if any(not q['translations'].get(lang, {}).get(f) for f in
                   ('question_text', 'answer_a', 'answer_b', 'answer_c', 'answer_d', 'explanation')):
                errors.append(f'Incomplete translation: {key}/{lang}')
        attach(mapping, key, question=True)
        image_path = q.get('image_path')
        if image_path:
            paths.add(image_file(image_path))
        # Deliberately excludes key/category/path: finds content copied under a new identity.
        content_hash = digest({'translations': q['translations'], 'correct_answers': sorted(answers)})
        questions.append({'key': key, 'category_slug': q['category_slug'],
            'question_fr': q['translations']['fr']['question_text'],
            'image_path': image_path, 'image_sha256': file_hash(root, image_file(image_path)) if image_path else None,
            'content_sha256': content_hash, **mapping})
    for key in set(review['questions']) - set(keys):
        errors.append(f'Review references removed question: {key}')

    catalogue_keys = []
    for sign in sorted(active_signs(pack, catalogue), key=lambda x: x['image_path']):
        path = sign['image_path']
        catalogue_keys.append(path)
        paths.add(image_file(path))
        mapping = review['catalogue'].get(path)
        if mapping is None or mapping.get('source_sha256') != identity(sign, root):
            errors.append(f'Catalogue entry needs current review: {path}')
            mapping = {'status': 'unreviewed', 'primary_codes': []}
        attach(mapping, path)
        for code in mapping.get('primary_codes', []):
            index[code]['catalogue_images'].append(path)
        signs.append({'image_path': path, 'category_slug': sign['road_sign_category_slug'],
                      'name_fr': sign['translations']['fr']['name'], **mapping})
    if len(set(catalogue_keys)) != len(catalogue_keys):
        errors.append('Duplicate catalogue image identity')
    for path in set(review['catalogue']) - set(catalogue_keys):
        errors.append(f'Review references removed catalogue entry: {path}')

    drafts = review['drafts']
    if len({d['id'] for d in drafts}) != len(drafts):
        errors.append('Duplicate draft id')
    for draft in drafts:
        for code in draft['codes']:
            index[code]['draft_ids'].append(draft['id'])
        for path, expected in draft['files'].items():
            paths.add(Path(path))
            if not (root / path).is_file() or file_hash(root, path) != expected:
                errors.append(f'Draft needs current review: {path}')
    # New authoring drafts must be registered before any inventory check can clear.
    registered_drafts = {p for d in drafts for p in d['files']}
    for directory in review['draft_directories']:
        for path in sorted((root / directory).rglob('*')):
            if path.is_file() and path.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'):
                relative = path.relative_to(root).as_posix()
                paths.add(Path(relative))
                if relative not in registered_drafts:
                    errors.append(f'Unregistered draft image: {relative}')

    jobs = []
    for path in sorted((root / JOBS).glob('*.json')):
        if path.name.startswith('.'):
            continue
        job = read(root, path.relative_to(root))
        code = job['code']
        if code not in index or job['state'] not in ('reserved', 'staged', 'reviewed', 'imported'):
            raise ValueError(f'Invalid workflow job: {path.name}')
        if job['state'] != 'imported':
            index[code]['pending_job_ids'].append(job['id'])
        if job.get('image_path'):
            asset = Path(job['image_path'])
            paths.add(asset)
            if file_hash(root, asset) != job['image_sha256']:
                errors.append(f'Workflow image changed: {job["id"]}')
        paths.add(path.relative_to(root))
        jobs.append(job)
    question_index = {q['key']: q for q in questions}
    for code, entry in index.items():
        for field in entry:
            if isinstance(entry[field], list):
                entry[field] = sorted(set(entry[field]))
        entry['existing_categories'] = sorted({question_index[k]['category_slug'] for k in entry['question_keys']})
        route = review['routing'].get(code)
        if route and route not in categories:
            errors.append(f'Invalid category route: {code}/{route}')
        entry['suggested_category_slug'] = route
        entry['car_scope'] = review['scope'].get(code, 'requires_car_scenario_review')
        if entry['review_holds']:
            entry['status'] = 'needs_review'
        elif entry['question_keys'] or entry['supplementary_question_keys'] or entry['context_question_keys']:
            entry['status'] = 'covered'
        elif entry['draft_ids'] or entry['pending_job_ids']:
            entry['status'] = 'draft_exists'
        elif entry['catalogue_images']:
            entry['status'] = 'catalogue_only'
        else:
            entry['status'] = 'no_question_mapping'
    for group in review['scenario_review_groups']:
        if any(k not in question_index for k in group['question_keys']):
            errors.append(f'Unknown question in scenario group: {group["id"]}')
    for path in sorted(paths):
        if (root / path).is_file():
            manifest[path.as_posix()] = file_hash(root, path)
        else:
            errors.append(f'Missing file: {path}')
    return {'schema_version': 1, 'country': 'france', 'licence_scope': 'ordinary_passenger_car',
        'audit_date': review['audit_date'], 'source_manifest_sha256': digest(manifest),
        'source_files': manifest, 'validation_errors': sorted(errors),
        'counts': {'questions': len(questions), 'questions_with_images': sum(bool(q['image_path']) for q in questions),
            'catalogue_entries': len(signs), 'codes': len(index),
            'question_statuses': dict(sorted(Counter(q['status'] for q in questions).items())),
            'questions_by_category': dict(sorted(Counter(q['category_slug'] for q in questions).items())),
            'codes_with_primary_questions': sum(bool(e['question_keys']) for e in index.values())},
        'codes': index, 'questions': questions, 'catalogue': signs, 'drafts': drafts, 'jobs': jobs,
        'exact_duplicate_content_groups': duplicates(questions, 'content_sha256'),
        'exact_duplicate_image_groups': duplicates(questions, 'image_sha256'),
        'scenario_review_groups': review['scenario_review_groups'], 'findings': review['findings'],
        'references': review['references']}


def lookup(registry, raw_code):
    if registry['validation_errors']:
        return {'input': raw_code, 'decision': 'blocked', 'generation_allowed': False,
                'reason': 'Registry has unreviewed or invalid source data.'}
    token = re.sub(r'\s+', '', raw_code).casefold()
    matches = [code for code in registry['codes'] if code.casefold() == token]
    if not matches:
        return {'input': raw_code, 'decision': 'needs_review', 'generation_allowed': False,
                'reason': 'Code is outside this observed-content registry; absence is not clearance.'}
    entry = registry['codes'][matches[0]]
    if entry['review_holds']:
        decision = 'needs_review'
    elif entry['question_keys'] or entry['supplementary_question_keys'] or entry['context_question_keys'] or entry['draft_ids'] or entry['pending_job_ids']:
        decision = 'skip_existing'
    else:
        decision = 'needs_review'
    return {**entry, 'decision': decision, 'generation_allowed': False,
        'reason': 'Existing questions/drafts block automatic repetition.' if decision == 'skip_existing' else
                  'Resolve holds or approve a car scenario and category before generation.'}


def report(registry):
    c = registry['counts']
    lines = ['# France sign-code audit', '', f'Audited {registry["audit_date"]}.', '',
        f'{c["questions"]} bundled questions ({c["questions_with_images"]} with images), '
        f'{c["catalogue_entries"]} active catalogue entries, {c["codes"]} observed/candidate codes. '
        f'{c["codes_with_primary_questions"]} codes have primary question mappings.', '',
        'Scope: the current bundled France pack, the catalogue merged as ContentLoader merges it, '
        'and registered local quiz-card drafts. This does not query installed-device SQLite or retired questions. '
        'The app imports this content into local SQLite; the registry does not modify it.', '',
        'All question texts/answers/explanations were inventoried. Code mappings use the learning target and '
        'reviewed descriptions; selected ambiguous images were inspected. This is not a full legal or visual QA '
        'certification of every image. Incidental background signs are not exhaustively labelled.', '',
        '## Questions by app category', '', '| Category | Questions |', '| --- | ---: |']
    lines += [f'| {k} | {v} |' for k, v in c['questions_by_category'].items()]
    lines += ['', '## Findings and holds', '']
    for finding in registry['findings']:
        lines.append((f'- **{finding["id"]} ({finding["severity"]}):** {finding["detail"]} '
                      + ' '.join(f'`{k}`' for k in finding.get('question_keys', []))).rstrip())
        if finding.get('resolution'):
            lines.append(f'  Resolved {finding["resolved_on"]}: {finding["resolution"]}')
    lines += ['', '## Repetition checks', '',
        f'- Exact duplicate question-content groups: {len(registry["exact_duplicate_content_groups"])}.',
        f'- Exact reused-image groups: {len(registry["exact_duplicate_image_groups"])}.',
        '- Shared codes are existing coverage, not proof that two situations are identical.',
        '- The manually listed scenario groups below identify overlap to review, not confirmed duplicates.',
        '- SHA-256 detects exact repeated content/assets; it cannot recognize paraphrases or visually similar scenes.', '']
    for kind in ('exact_duplicate_content_groups', 'exact_duplicate_image_groups'):
        for group in registry[kind]:
            lines.append(f'- {kind}: ' + ', '.join(f'`{k}`' for k in group))
    for group in registry['scenario_review_groups']:
        lines.append(f'- **{group["id"]}:** {group["note"]} ' + ', '.join(f'`{k}`' for k in group['question_keys']))
    lines += ['', '## Code coverage', '',
        'Existing category links come from question records. Suggested routes are authoring defaults and '
        'never move existing questions. Catalogue-only signs still require a passenger-car scenario review. '
        'A code with a review hold stays blocked even when it has another valid question.', '',
        '| Code | Status | Primary questions | Suggested category |', '| --- | --- | ---: | --- |']
    for code, entry in registry['codes'].items():
        lines.append(f'| {code} | {entry["status"]} | {len(entry["question_keys"])} | {entry["suggested_category_slug"] or "review"} |')
    lines += ['', '## References', '']
    lines += [f'- [{ref["title"]}]({ref["url"]}) — {ref["use"]}' for ref in registry['references']]
    lines += ['', 'See [registry usage](../../scripts/SIGN_REGISTRY.md) for commands, review updates and limitations.', '']
    return '\n'.join(lines)


def rendered(registry):
    return json.dumps(registry, ensure_ascii=False, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['build', 'verify', 'check'])
    parser.add_argument('code', nargs='?')
    args = parser.parse_args()
    if args.command == 'check' and not args.code:
        parser.error('check requires a sign code')
    try:
        registry = build()
        if registry['validation_errors']:
            raise ValueError('\n'.join(registry['validation_errors']))
        if args.command == 'build':
            (ROOT / REGISTRY).write_text(rendered(registry))
            (ROOT / REPORT).write_text(report(registry))
            print(json.dumps(registry['counts'], ensure_ascii=False))
            return 0
        if (ROOT / REGISTRY).read_text() != rendered(registry) or (ROOT / REPORT).read_text() != report(registry):
            raise ValueError('Registry/report is stale. Review changed inputs, then run build.')
        if args.command == 'verify':
            print('Registry and report are current; all source records and assets accounted for.')
            return 0
        result = lookup(registry, args.code)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 2 if result['decision'] == 'skip_existing' else 3
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'REGISTRY BLOCKED: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
