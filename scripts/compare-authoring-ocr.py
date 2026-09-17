#!/usr/bin/env python3
"""Compare Apple Vision OCR output with the structured French source text."""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKC", value)
    value = value.replace("’", "'").replace("‘", "'").replace("`", "'")
    return re.sub(r"\s+", " ", value).strip().lower()


def best_similarity(expected: str, lines: list[str]) -> float:
    expected_words = normalize(expected).split()
    words = normalize(" ".join(lines)).split()
    minimum = max(1, len(expected_words) - 2)
    maximum = min(len(words), len(expected_words) + 2)
    best = 0.0
    for length in range(minimum, maximum + 1):
        for start in range(0, len(words) - length + 1):
            candidate = " ".join(words[start : start + length])
            best = max(best, SequenceMatcher(None, normalize(expected), candidate).ratio())
    return round(best, 4)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", type=Path, required=True)
    parser.add_argument("--ocr", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    questions = {item["key"]: item for item in json.loads(args.batch.read_text(encoding="utf-8"))}
    ocr_items = [json.loads(line) for line in args.ocr.read_text(encoding="utf-8").splitlines() if line]
    report: list[dict] = []

    for item in ocr_items:
        stem = Path(item["path"]).stem
        key = stem.removesuffix("-card")
        question = questions[key]
        fr = question["translations"]["fr"]
        expected = [
            f"Question: {fr['question_text']}",
            *[f"{letter.upper()}. {fr[f'answer_{letter}']}" for letter in "abcd"],
        ]
        lines = item.get("lines", [])
        joined = normalize(" ".join(lines))
        fields = []
        for value in expected:
            exact = normalize(value) in joined
            fields.append(
                {
                    "expected": value,
                    "normalized_exact_match": exact,
                    "best_similarity": 1.0 if exact else best_similarity(value, lines),
                }
            )
        report.append(
            {
                "key": key,
                "ocr_error": item.get("error"),
                "all_fields_match": not item.get("error") and all(field["normalized_exact_match"] for field in fields),
                "fields": fields,
            }
        )

    report.sort(key=lambda item: item["key"])
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    failures = [item for item in report if not item["all_fields_match"]]
    print(json.dumps({"cards": len(report), "passed": len(report) - len(failures), "failed": len(failures)}, indent=2))
    for failure in failures:
        print(failure["key"])
        for field in failure["fields"]:
            if not field["normalized_exact_match"]:
                print(f"  {field['best_similarity']:.4f}  {field['expected']}")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
