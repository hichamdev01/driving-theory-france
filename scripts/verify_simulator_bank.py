#!/usr/bin/env python3
"""Compare a running simulator's read-only SQLite content with the bundled pack."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import sqlite3

import sign_workflow as workflow


def verify(database, root):
    pack_path = root / 'TheoryPrep/Resources/Content/france/pack.json'
    pack = json.loads(pack_path.read_text())
    version = int(re.search(r'contentVersion: Int64 = (\d+)',
                  (root / 'TheoryPrep/Database/Schema.swift').read_text()).group(1))
    db = sqlite3.connect(database.resolve().as_uri() + '?mode=ro', uri=True)
    db.row_factory = sqlite3.Row
    try:
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert db.execute('SELECT content_version FROM user_settings WHERE id=1').fetchone()[0] == version
        rows = db.execute('''SELECT q.*, cat.slug FROM questions q
            JOIN countries c ON q.country_id=c.id JOIN categories cat ON q.category_id=cat.id
            WHERE c.code='FR' AND q.active=1''').fetchall()
        by_key = {q['question_key']: q for q in rows}
        assert len(rows) == len(by_key) == len(pack['questions'])
        assert set(by_key) == {q['key'] for q in pack['questions']}
        for q in pack['questions']:
            row = by_key[q['key']]
            assert row['slug'] == q['category_slug'], q['key']
            assert row['image_path'] == q.get('image_path'), q['key']
            assert row['video_path'] == q.get('video_path'), q['key']
            assert row['difficulty'] == q['difficulty'], q['key']
            assert set(row['correct_answers'].split(',')) == set(workflow.correct_answers(q)), q['key']
            for lang in ('fr', 'en'):
                translations = db.execute('SELECT * FROM question_translations WHERE question_id=? AND language_code=?',
                                          (row['id'], lang)).fetchall()
                assert len(translations) == 1, (q['key'], lang)
                for field, value in q['translations'][lang].items():
                    assert translations[0][field] == value, (q['key'], lang, field)
        progress = {table: [tuple(row) for row in db.execute(f'SELECT * FROM {table} ORDER BY id')]
                    for table in ('user_question_progress', 'user_mistakes')}
        return dict(result='pass', content_version=version, questions=len(rows),
                    illustrated=sum(bool(q['image_path']) for q in rows),
                    categories=dict(Counter(q['slug'] for q in rows)),
                    pack_sha256=hashlib.sha256(pack_path.read_bytes()).hexdigest(),
                    progress_sha256=hashlib.sha256(json.dumps(progress, sort_keys=True).encode()).hexdigest(),
                    checks='SQLite integrity, all active FR keys, categories, media paths, difficulty, answer sets and both full translations match the current pack.')
    finally:
        db.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('database', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.database, Path(__file__).resolve().parents[1]), indent=2))
