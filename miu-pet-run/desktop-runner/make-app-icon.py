#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "references" / "canonical-base.png"
ICON_DIR = ROOT / "desktop-runner" / "Assets" / "AppIcon.iconset"
PREVIEW = ROOT / "desktop-runner" / "Assets" / "app-icon-1024.png"
ICNS = ROOT / "desktop-runner" / "Assets" / "AppIcon.icns"
STATUS_ICON = ROOT / "desktop-runner" / "Assets" / "StatusIcon.png"
STATUS_ICON_2X = ROOT / "desktop-runner" / "Assets" / "StatusIcon@2x.png"


def remove_magenta_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            is_key = r > 190 and b > 160 and g < 95 and (r - g) > 120 and (b - g) > 100
            if is_key:
                pixels[x, y] = (r, g, b, 0)
    alpha = image.getchannel("A")
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    image.putalpha(alpha)
    return image


def crop_subject(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        raise RuntimeError("No subject found in source icon image")
    left, top, right, bottom = bbox
    pad = 24
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(image.width, right + pad)
    bottom = min(image.height, bottom + pad)
    return image.crop((left, top, right, bottom))


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((36, 36, size - 36, size - 36), radius=radius, fill=255)
    return mask


def vertical_gradient(size: int) -> Image.Image:
    top = (248, 252, 255)
    bottom = (211, 228, 251)
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        r = round(top[0] * (1 - t) + bottom[0] * t)
        g = round(top[1] * (1 - t) + bottom[1] * t)
        b = round(top[2] * (1 - t) + bottom[2] * t)
        for x in range(size):
            pixels[x, y] = (r, g, b, 255)
    return image


def make_icon() -> Image.Image:
    size = 1024
    source = crop_subject(remove_magenta_background(Image.open(SOURCE)))
    subject_height = 760
    subject_width = round(source.width * (subject_height / source.height))
    subject = source.resize((subject_width, subject_height), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    shadow_mask = rounded_rect_mask(size, 210).filter(ImageFilter.GaussianBlur(22))
    shadow = Image.new("RGBA", (size, size), (54, 91, 132, 70))
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_layer.paste(shadow, (0, 18), shadow_mask)
    canvas.alpha_composite(shadow_layer)

    bg_mask = rounded_rect_mask(size, 210)
    bg = vertical_gradient(size)
    bg_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_layer.paste(bg, (0, 0), bg_mask)
    canvas.alpha_composite(bg_layer)

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((36, 36, size - 36, size - 36), radius=210, outline=(166, 190, 218, 220), width=7)
    draw.rounded_rectangle((62, 62, size - 62, size - 62), radius=184, outline=(255, 255, 255, 150), width=5)

    # A quiet desktop-edge cue: productized, but still subordinate to the cat.
    draw.rounded_rectangle((188, 716, 836, 778), radius=31, fill=(113, 157, 211, 42))
    draw.rounded_rectangle((248, 788, 776, 820), radius=16, fill=(93, 132, 184, 34))

    subject_shadow = Image.new("RGBA", subject.size, (37, 64, 92, 96))
    subject_shadow.putalpha(subject.getchannel("A").filter(ImageFilter.GaussianBlur(12)))
    subject_x = (size - subject.width) // 2
    subject_y = 170
    canvas.alpha_composite(subject_shadow, (subject_x, subject_y + 18))
    canvas.alpha_composite(subject, (subject_x, subject_y))

    return canvas


def make_status_icon() -> Image.Image:
    size = 64
    source = crop_subject(remove_magenta_background(Image.open(SOURCE)))
    subject_height = 58
    subject_width = round(source.width * (subject_height / source.height))
    subject = source.resize((subject_width, subject_height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - subject.width) // 2
    y = (size - subject.height) // 2 + 2
    shadow = Image.new("RGBA", subject.size, (16, 24, 32, 90))
    shadow.putalpha(subject.getchannel("A").filter(ImageFilter.GaussianBlur(1.8)))
    canvas.alpha_composite(shadow, (x, y + 2))
    canvas.alpha_composite(subject, (x, y))
    return canvas


def save_iconset(icon: Image.Image) -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    icon.save(PREVIEW)
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    for px, name in sizes:
        flattened = Image.new("RGB", (px, px), (255, 255, 255))
        resized = icon.resize((px, px), Image.Resampling.LANCZOS)
        flattened.paste(resized.convert("RGB"), mask=resized.getchannel("A"))
        flattened.save(ICON_DIR / name)


def save_icns() -> None:
    chunks = [
        ("icp4", ICON_DIR / "icon_16x16.png"),
        ("icp5", ICON_DIR / "icon_32x32.png"),
        ("icp6", ICON_DIR / "icon_32x32@2x.png"),
        ("ic07", ICON_DIR / "icon_128x128.png"),
        ("ic08", ICON_DIR / "icon_256x256.png"),
        ("ic09", ICON_DIR / "icon_512x512.png"),
        ("ic10", ICON_DIR / "icon_512x512@2x.png"),
    ]
    payload = bytearray()
    for code, path in chunks:
        data = path.read_bytes()
        payload.extend(code.encode("ascii"))
        payload.extend((len(data) + 8).to_bytes(4, "big"))
        payload.extend(data)
    ICNS.write_bytes(b"icns" + (len(payload) + 8).to_bytes(4, "big") + payload)


def save_status_icon() -> None:
    icon = make_status_icon()
    icon.resize((18, 18), Image.Resampling.LANCZOS).save(STATUS_ICON)
    icon.resize((36, 36), Image.Resampling.LANCZOS).save(STATUS_ICON_2X)


if __name__ == "__main__":
    save_iconset(make_icon())
    save_icns()
    save_status_icon()
    print(PREVIEW)
    print(ICON_DIR)
    print(ICNS)
    print(STATUS_ICON)
