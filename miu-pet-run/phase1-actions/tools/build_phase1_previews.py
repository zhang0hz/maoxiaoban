#!/usr/bin/env python3
"""Build transparent frames, GIFs, and contact sheet for Miu Phase 1 actions."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

CELL_WIDTH = 192
CELL_HEIGHT = 208
CHROMA_KEY = (255, 0, 255)


def color_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> float:
    return math.sqrt(sum((left[index] - right[index]) ** 2 for index in range(3)))


def alpha_count(image: Image.Image) -> int:
    return sum(image.getchannel("A").histogram()[1:])


def remove_chroma(image: Image.Image, threshold: float) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if color_distance((red, green, blue), CHROMA_KEY) <= threshold:
                pixels[x, y] = (red, green, blue, 0)
    return rgba


def fit_to_cell(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    output = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT), (0, 0, 0, 0))
    if bbox is None:
        return output
    sprite = image.crop(bbox)
    max_width = CELL_WIDTH - 10
    max_height = CELL_HEIGHT - 10
    scale = min(max_width / sprite.width, max_height / sprite.height, 1.0)
    if scale != 1.0:
        sprite = sprite.resize(
            (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
            Image.Resampling.LANCZOS,
        )
    left = (CELL_WIDTH - sprite.width) // 2
    top = (CELL_HEIGHT - sprite.height) // 2
    output.alpha_composite(sprite, (left, top))
    return output


def connected_components(image: Image.Image) -> list[dict[str, object]]:
    alpha = image.getchannel("A")
    width, height = alpha.size
    data = alpha.tobytes()
    visited = bytearray(width * height)
    components: list[dict[str, object]] = []

    for start, value in enumerate(data):
        if value <= 16 or visited[start]:
            continue
        stack = [start]
        visited[start] = 1
        pixels: list[int] = []
        min_x = width
        min_y = height
        max_x = 0
        max_y = 0
        while stack:
            current = stack.pop()
            pixels.append(current)
            x = current % width
            y = current // width
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            for neighbor in (current - 1, current + 1, current - width, current + width):
                if neighbor < 0 or neighbor >= len(data) or visited[neighbor]:
                    continue
                nx = neighbor % width
                if abs(nx - x) > 1:
                    continue
                if data[neighbor] > 16:
                    visited[neighbor] = 1
                    stack.append(neighbor)
        components.append(
            {
                "pixels": pixels,
                "area": len(pixels),
                "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                "center_x": (min_x + max_x + 1) / 2,
            }
        )
    return components


def component_group_image(
    source: Image.Image,
    components: list[dict[str, object]],
    padding: int = 4,
) -> Image.Image:
    width, height = source.size
    min_x = max(0, min(component["bbox"][0] for component in components) - padding)
    min_y = max(0, min(component["bbox"][1] for component in components) - padding)
    max_x = min(width, max(component["bbox"][2] for component in components) + padding)
    max_y = min(height, max(component["bbox"][3] for component in components) + padding)
    output = Image.new("RGBA", (max_x - min_x, max_y - min_y), (0, 0, 0, 0))
    source_pixels = source.load()
    output_pixels = output.load()
    for component in components:
        for pixel in component["pixels"]:
            x = pixel % width
            y = pixel // width
            output_pixels[x - min_x, y - min_y] = source_pixels[x, y]
    return output


def extract_by_components(strip: Image.Image, frame_count: int) -> list[Image.Image] | None:
    components = connected_components(strip)
    if not components:
        return None
    largest_area = max(component["area"] for component in components)
    seed_threshold = max(120, largest_area * 0.2)
    seeds = [component for component in components if component["area"] >= seed_threshold]
    if len(seeds) < frame_count:
        seeds = sorted(components, key=lambda component: component["area"], reverse=True)[
            :frame_count
        ]
    if len(seeds) < frame_count:
        return None
    seeds = sorted(
        sorted(seeds, key=lambda component: component["area"], reverse=True)[:frame_count],
        key=lambda component: component["center_x"],
    )
    seed_ids = {id(seed) for seed in seeds}
    groups: list[list[dict[str, object]]] = [[seed] for seed in seeds]
    noise_threshold = max(12, largest_area * 0.002)
    for component in components:
        if id(component) in seed_ids or component["area"] < noise_threshold:
            continue
        nearest = min(
            range(len(seeds)),
            key=lambda index: abs(seeds[index]["center_x"] - component["center_x"]),
        )
        groups[nearest].append(component)
    return [fit_to_cell(component_group_image(strip, group)) for group in groups]


def extract_by_slots(strip: Image.Image, frame_count: int) -> list[Image.Image]:
    slot_width = strip.width / frame_count
    frames = []
    for index in range(frame_count):
        left = round(index * slot_width)
        right = round((index + 1) * slot_width)
        frames.append(fit_to_cell(strip.crop((left, 0, right, strip.height))))
    return frames


def checker(size: tuple[int, int], square: int = 16) -> Image.Image:
    image = Image.new("RGB", size, "#ffffff")
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], square):
        for x in range(0, size[0], square):
            if (x // square + y // square) % 2:
                draw.rectangle((x, y, x + square - 1, y + square - 1), fill="#e8e8e8")
    return image


def write_gif(frames: list[Image.Image], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    gif_frames = []
    for frame in frames:
        bg = Image.new("RGBA", frame.size, (255, 255, 255, 0))
        bg.alpha_composite(frame)
        gif_frames.append(bg)
    gif_frames[0].save(
        output,
        save_all=True,
        append_images=gif_frames[1:],
        duration=140,
        loop=0,
        disposal=2,
    )


def build_contact(actions: list[dict[str, object]], frames_root: Path, output: Path) -> None:
    scale = 0.55
    label_h = 24
    cell_w = round(CELL_WIDTH * scale)
    cell_h = round(CELL_HEIGHT * scale)
    rows = len(actions)
    cols = max(action["frames"] for action in actions)
    sheet = Image.new("RGB", (cols * cell_w, rows * (cell_h + label_h)), "#f7f7f7")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for row, action in enumerate(actions):
        action_id = action["id"]
        frame_count = action["frames"]
        y = row * (cell_h + label_h)
        draw.rectangle((0, y, sheet.width, y + label_h - 1), fill="#111111")
        draw.text((6, y + 6), f"{action_id} · {frame_count} frames", fill="#ffffff", font=font)
        for index in range(frame_count):
            frame_path = frames_root / action_id / f"{index:02d}.png"
            if not frame_path.is_file():
                continue
            with Image.open(frame_path) as opened:
                frame = opened.convert("RGBA").resize((cell_w, cell_h), Image.Resampling.LANCZOS)
            bg = checker((cell_w, cell_h))
            bg.paste(frame, (0, 0), frame)
            x = index * cell_w
            sheet.paste(bg, (x, y + label_h))
            draw.rectangle((x, y + label_h, x + cell_w - 1, y + label_h + cell_h - 1), outline="#18a058")
            draw.text((x + 4, y + label_h + 4), str(index), fill="#111111", font=font)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--sources-manifest", default="sources-manifest.json")
    parser.add_argument("--threshold", type=float, default=110.0)
    args = parser.parse_args()

    root = Path(args.root).expanduser().resolve()
    sources_manifest = root / args.sources_manifest
    sources = json.loads(sources_manifest.read_text(encoding="utf-8"))
    actions = sources["actions"]
    frames_root = root / "frames"
    gifs_root = root / "gifs"
    report: dict[str, object] = {"ok": True, "actions": []}

    for action in actions:
        action_id = action["id"]
        frame_count = int(action["frames"])
        source = Path(action["source"]).expanduser().resolve()
        with Image.open(source) as opened:
            strip = remove_chroma(opened, args.threshold)
        frames = extract_by_components(strip, frame_count)
        method = "components"
        if frames is None:
            frames = extract_by_slots(strip, frame_count)
            method = "slots"

        action_frames_root = frames_root / action_id
        action_frames_root.mkdir(parents=True, exist_ok=True)
        frame_infos = []
        for index, frame in enumerate(frames):
            frame_path = action_frames_root / f"{index:02d}.png"
            frame.save(frame_path)
            frame_infos.append(
                {
                    "index": index,
                    "file": str(frame_path),
                    "nontransparentPixels": alpha_count(frame),
                    "bbox": list(frame.getbbox()) if frame.getbbox() else None,
                }
            )
        gif_path = gifs_root / f"miu-{action_id}.gif"
        write_gif(frames, gif_path)
        report["actions"].append(
            {
                "id": action_id,
                "frames": frame_count,
                "source": str(source),
                "method": method,
                "gif": str(gif_path),
                "frameInfos": frame_infos,
            }
        )

    contact = root / "qa" / "phase1-contact-sheet.png"
    build_contact(actions, frames_root, contact)
    report["contactSheet"] = str(contact)
    report_path = root / "qa" / "phase1-review.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "contactSheet": str(contact), "report": str(report_path)}, indent=2))


if __name__ == "__main__":
    main()
