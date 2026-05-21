#!/usr/bin/env python3
"""Audit Miu action frames for identity-breaking color drift."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def visible_pixels(path: Path) -> list[tuple[int, int, int]]:
    image = Image.open(path).convert("RGBA")
    return [pixel[:3] for pixel in image.getdata() if pixel[3] > 20]


def average(pixels: list[tuple[int, int, int]]) -> tuple[float, float, float]:
    return tuple(sum(pixel[index] for pixel in pixels) / len(pixels) for index in range(3))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames-root", required=True)
    parser.add_argument("--reference-action", default="loaf")
    parser.add_argument("--max-blue-bias", type=float, default=12.0)
    args = parser.parse_args()

    root = Path(args.frames_root).expanduser().resolve()
    reference_dir = root / args.reference_action
    reference_pixels: list[tuple[int, int, int]] = []
    for frame in sorted(reference_dir.glob("*.png")):
        reference_pixels.extend(visible_pixels(frame))
    if not reference_pixels:
        raise SystemExit(f"No visible reference pixels: {reference_dir}")

    reference = average(reference_pixels)
    failed: list[str] = []
    print(f"reference {args.reference_action} avg={tuple(round(value, 1) for value in reference)}")
    for action_dir in sorted(path for path in root.iterdir() if path.is_dir()):
        pixels: list[tuple[int, int, int]] = []
        for frame in sorted(action_dir.glob("*.png")):
            pixels.extend(visible_pixels(frame))
        if not pixels:
            continue
        avg = average(pixels)
        blue_bias = (avg[2] - avg[0]) - (reference[2] - reference[0])
        status = "OK" if blue_bias < args.max_blue_bias else "CHECK"
        print(
            f"{status} {action_dir.name:12s} "
            f"blueBias={blue_bias:5.1f} avg={tuple(round(value, 1) for value in avg)}"
        )
        if status != "OK":
            failed.append(action_dir.name)
    if failed:
        print("failed:", ", ".join(failed))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
