#!/usr/bin/env python3
"""Normalize generated authoring cards and export their scene-only JPEGs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageCms, ImageDraw, ImageFont, ImageStat


CARD_WIDTH = 1600
CARD_HEIGHT = 900
SCENE_HEIGHT = round(CARD_HEIGHT * 0.65)
PANEL_COLOR = (26, 28, 30)
SEPARATOR_COLOR = (92, 99, 108)
GREEN = (34, 197, 94)
GREEN_FILL = (17, 83, 50)
WHITE = (248, 250, 252)
MUTED_BORDER = (75, 85, 99)
REGULAR_FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD_FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def row_difference(image: Image.Image, y: int) -> float:
    current = image.crop((0, y, image.width, y + 1))
    previous = image.crop((0, y - 1, image.width, y))
    return sum(ImageStat.Stat(ImageChops.difference(current, previous)).mean) / 3


def find_scene_bottom(image: Image.Image) -> int:
    """Find the full-width scene/panel edge near the intended 65% boundary."""
    start = round(image.height * 0.45)
    end = round(image.height * 0.72)
    candidates: list[int] = []
    for y in range(start, end):
        above = image.crop((0, max(0, y - 8), image.width, y - 2))
        below = image.crop((0, min(y + 2, image.height - 1), image.width, min(y + 8, image.height)))
        above_mean = sum(ImageStat.Stat(above).mean) / 3
        below_stats = ImageStat.Stat(below)
        below_mean = sum(below_stats.mean) / 3
        below_deviation = sum(below_stats.stddev) / 3
        # Answer borders and glyphs can create a sharper one-row edge than the
        # separator. The real edge is the first transition into a dark,
        # low-variance full-width band; later text and answer edges are ignored.
        if below_mean < 75 and below_deviation < 24 and above_mean - below_mean > 7:
            candidates.append(y)
    if candidates:
        return candidates[0]
    return max((row_difference(image, y), y) for y in range(start, end))[1]


def crop_to_aspect(image: Image.Image, width: int, height: int) -> Image.Image:
    target = width / height
    current = image.width / image.height
    if current > target:
        crop_width = round(image.height * target)
        left = max(0, (image.width - crop_width) // 2)
        image = image.crop((left, 0, left + crop_width, image.height))
    elif current < target:
        crop_height = round(image.width / target)
        # Keep the horizon and dashboard; remove evenly from top and bottom.
        top = max(0, (image.height - crop_height) // 2)
        image = image.crop((0, top, image.width, top + crop_height))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        proposed = word if not current else f"{current} {word}"
        if draw.textlength(proposed, font=font) <= width:
            current = proposed
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


def layout_panel(draw: ImageDraw.ImageDraw, question: dict) -> tuple[ImageFont.FreeTypeFont, ImageFont.FreeTypeFont, list[str], list[list[str]], list[int]]:
    fr = question["translations"]["fr"]
    answers = [fr[f"answer_{letter}"] for letter in "abcd"]
    available_width = CARD_WIDTH - 48
    for question_size, answer_size in [(25, 20), (23, 19), (21, 18), (20, 17), (19, 16)]:
        question_font = ImageFont.truetype(BOLD_FONT, question_size)
        answer_font = ImageFont.truetype(REGULAR_FONT, answer_size)
        question_lines = wrap_text(draw, f"Question: {fr['question_text']}", question_font, available_width)
        answer_lines = [
            wrap_text(draw, f"{letter.upper()}. {answer}", answer_font, available_width - 56)
            for letter, answer in zip("abcd", answers)
        ]
        q_line_height = question_size + 6
        a_line_height = answer_size + 5
        row_heights = [max(43, len(lines) * a_line_height + 12) for lines in answer_lines]
        used = 2 + 12 + len(question_lines) * q_line_height + 10 + sum(row_heights) + 10
        if used <= CARD_HEIGHT - SCENE_HEIGHT:
            return question_font, answer_font, question_lines, answer_lines, row_heights
    raise RuntimeError(f"Quiz panel text does not fit for {question['key']}")


def draw_panel(card: Image.Image, question: dict) -> None:
    draw = ImageDraw.Draw(card)
    panel_top = SCENE_HEIGHT
    draw.rectangle((0, panel_top, CARD_WIDTH, CARD_HEIGHT), fill=PANEL_COLOR)
    draw.line((0, panel_top, CARD_WIDTH, panel_top), fill=SEPARATOR_COLOR, width=2)
    question_font, answer_font, question_lines, answer_lines, row_heights = layout_panel(draw, question)

    y = panel_top + 14
    q_line_height = question_font.size + 6
    for line in question_lines:
        draw.text((24, y), line, font=question_font, fill=WHITE)
        y += q_line_height
    y += 8

    correct = question["correct_answer"]
    answer_line_height = answer_font.size + 5
    for letter, lines, row_height in zip("abcd", answer_lines, row_heights):
        top = y
        bottom = y + row_height - 4
        is_correct = letter == correct
        draw.rounded_rectangle(
            (24, top, CARD_WIDTH - 24, bottom),
            radius=6,
            fill=GREEN_FILL if is_correct else PANEL_COLOR,
            outline=GREEN if is_correct else MUTED_BORDER,
            width=3 if is_correct else 1,
        )
        text_y = top + 6
        for line in lines:
            draw.text((40, text_y), line, font=answer_font, fill=WHITE)
            text_y += answer_line_height
        if is_correct:
            x = CARD_WIDTH - 62
            cy = (top + bottom) // 2
            draw.line((x - 12, cy, x - 4, cy + 8), fill=WHITE, width=5)
            draw.line((x - 4, cy + 8, x + 13, cy - 10), fill=WHITE, width=5)
        y += row_height


def source_path(raw_directory: Path, key: str) -> Path:
    candidates = [
        raw_directory / f"{key}-card-raw-v3.png",
        raw_directory / f"{key}-card-raw-v2.png",
        raw_directory / f"{key}-card-raw.png",
        raw_directory / f"{key}-card.png",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"Missing raw card for {key}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", type=Path, required=True)
    parser.add_argument("--raw-directory", type=Path, required=True)
    parser.add_argument("--card-directory", type=Path, required=True)
    parser.add_argument("--scene-directory", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    questions = json.loads(args.batch.read_text(encoding="utf-8"))
    args.card_directory.mkdir(parents=True, exist_ok=True)
    args.scene_directory.mkdir(parents=True, exist_ok=True)
    report: list[dict] = []
    srgb_profile = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()

    for question in questions:
        key = question["key"]
        source = source_path(args.raw_directory, key)
        raw = Image.open(source).convert("RGB")
        scene_bottom = question.get("raw_scene_bottom", find_scene_bottom(raw))
        raw_scene = raw.crop((0, 0, raw.width, scene_bottom))
        if question.get("scene_resize_mode") == "stretch":
            # Some generators place their quiz panel above the requested 65%
            # boundary.  After explicitly cropping that panel, preserve the
            # full scene width so edge-mounted signs and road users remain in
            # frame instead of being removed by a second centre crop.
            scene = raw_scene.resize((CARD_WIDTH, SCENE_HEIGHT), Image.Resampling.LANCZOS)
        else:
            scene = crop_to_aspect(raw_scene, CARD_WIDTH, SCENE_HEIGHT)

        card = Image.new("RGB", (CARD_WIDTH, CARD_HEIGHT), PANEL_COLOR)
        card.paste(scene, (0, 0))
        draw_panel(card, question)
        card_path = args.card_directory / f"{key}-card.png"
        card.save(card_path, format="PNG", icc_profile=srgb_profile)

        scene_path = args.scene_directory / f"{key}.jpg"
        # This is exactly the 65% top crop of the normalized 1600x900 card.
        card.crop((0, 0, CARD_WIDTH, round(CARD_HEIGHT * 0.65))).save(
            scene_path,
            format="JPEG",
            quality=90,
            optimize=True,
            progressive=True,
            icc_profile=srgb_profile,
        )
        report.append(
            {
                "key": key,
                "raw_card": str(source),
                "raw_dimensions": [raw.width, raw.height],
                "raw_scene_bottom": scene_bottom,
                "raw_scene_ratio": round(scene_bottom / raw.height, 4),
                "normalized_card": str(card_path),
                "normalized_dimensions": [CARD_WIDTH, CARD_HEIGHT],
                "scene_asset": str(scene_path),
                "scene_dimensions": [CARD_WIDTH, SCENE_HEIGHT],
                "jpeg_quality": 90,
                "color_profile": "sRGB",
            }
        )

    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
