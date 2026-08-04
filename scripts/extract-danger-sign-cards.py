#!/usr/bin/env python3

from pathlib import Path
import argparse

from PIL import Image


SIGN_NAMES = [
    "permanent_warning",
    "temporary_warning",
    "priority_to_right",
    "bend_right",
    "bend_left",
    "double_bend_right",
    "double_bend_left",
    "uneven_road",
    "speed_hump",
    "road_narrows_right",
    "road_narrows_left",
    "road_narrows_both",
    "slippery_road",
    "movable_bridge",
    "level_crossing_barriers",
    "level_crossing_no_barrier",
    "tramway_crossing",
    "public_transport_crossing",
    "children",
    "pedestrian_crossing",
    "unspecified_danger",
    "cattle",
    "sheep",
    "wild_animals",
    "horse_riders",
    "steep_descent",
    "traffic_lights",
    "two_way_traffic",
    "falling_rocks",
    "quayside",
    "cyclists",
    "aircraft",
    "crosswind",
    "priority_intersection",
    "roundabout",
]

X_RANGES = [(23, 193), (214, 384), (405, 575), (596, 766), (787, 957)]
Y_RANGES = [
    (170, 340),
    (398, 568),
    (630, 780),
    (850, 1020),
    (1075, 1245),
    (1300, 1470),
    (1525, 1695),
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGB")
    args.output.mkdir(parents=True, exist_ok=True)

    for index, name in enumerate(SIGN_NAMES):
        row, column = divmod(index, 5)
        left, right = X_RANGES[column]
        top, bottom = Y_RANGES[row]
        sign = source.crop((left, top, right, bottom))
        scale = min(480 / sign.width, 480 / sign.height)
        sign = sign.resize(
            (round(sign.width * scale), round(sign.height * scale)),
            Image.Resampling.LANCZOS,
        )

        card = Image.new("RGB", (1200, 600), "white")
        card.paste(sign, ((card.width - sign.width) // 2, (card.height - sign.height) // 2))
        card.save(args.output / f"danger_sign_{name}.png", optimize=True)


if __name__ == "__main__":
    main()
