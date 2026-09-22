#!/usr/bin/env python3
"""Turns raw app screenshots into store-listing images: the whole phone,
frame and all, as large as it fits, over a two-colour gradient, with a
two-line caption in heavy outlined type across the bottom.

  python3 tools/store_screenshots/compose.py                  # everything
  python3 tools/store_screenshots/compose.py he               # one locale
  python3 tools/store_screenshots/compose.py he --store play_phone

Reads   store_assets/raw/<locale>/<name>.png
        tools/store_screenshots/captions.json  (texts and colours)
Writes  store_assets/listing/<store>/<locale>/<name>.png

A raw file with no caption entry is skipped with a note. Needs Pillow built
with raqm, or Hebrew comes out reversed.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "store_assets" / "raw"
OUT = ROOT / "store_assets" / "listing"
CAPTIONS = Path(__file__).with_name("captions.json")

# What each store asks for. Play takes 9:16 phones; the App Store wants the
# 6.9" and 6.5" iPhone classes exactly, and — because the iOS target builds
# for iPad too (TARGETED_DEVICE_FAMILY "1,2") — a 13" iPad set as well.
TARGETS = {
    "play_phone": (1080, 1920),
    "appstore_6_9": (1320, 2868),
    "appstore_6_5": (1242, 2688),
    "appstore_ipad_13": (2064, 2752),
}

# Heaviest first, as (path, named weight or None). A store caption is set in
# the plain grotesque rather than the rounded one: rounded reads playful,
# and the brief was restraint.
FONTS = {
    "he": [
        ("/System/Library/Fonts/SFHebrewRounded.ttf", "Black"),
        ("/System/Library/Fonts/SFHebrewRounded.ttf", "Heavy"),
        ("/System/Library/Fonts/SFHebrew.ttf", "Black"),
        ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", None),
    ],
    "en": [
        ("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", None),
        ("/System/Library/Fonts/Supplemental/Arial Black.ttf", None),
    ],
}
# A face "has" a letter when it draws something other than its own
# missing-glyph box — compared against a code point no font carries.
PROBE = {"he": "ש", "en": "A"}
MISSING = "￿"

WHITE = (255, 255, 255)
YELLOW = (255, 221, 51)
# The outline and the shadow under it.
INK = (28, 16, 64)


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def darken(colour, factor):
    return tuple(max(0, min(255, round(c * factor))) for c in colour)


def covers(font, text):
    """Whether the face can draw every character in [text] — a missing one
    comes out as the font's own empty box, which is why it is compared
    against a code point no font carries."""
    blank = bytes(font.getmask(MISSING))
    for ch in text:
        if ch.isspace():
            continue
        mask = font.getmask(ch)
        if mask.getbbox() is None or bytes(mask) == blank:
            return False
    return True


def font_for(locale, size, text=""):
    """The heaviest face that can draw [text], or None when none can. Only
    one face on macOS carries both Hebrew and Latin, so a Hebrew caption
    naming PRO falls back to it for both its lines rather than mixing two
    faces in one caption."""
    wanted = PROBE.get(locale, "A") + text
    for path, variation in FONTS.get(locale, FONTS["en"]):
        if not Path(path).exists():
            continue
        try:
            font = ImageFont.truetype(path, size, layout_engine=ImageFont.Layout.RAQM)
            if variation is not None:
                names = [
                    n.decode() if isinstance(n, bytes) else n
                    for n in font.get_variation_names()
                ]
                if variation not in names:
                    continue
                font.set_variation_by_name(variation)
        except OSError:
            continue
        if covers(font, wanted):
            return font
    return None


def gradient(size, top, bottom):
    w, h = size
    column = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        column.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return column.resize((w, h))


def rounded(image, radius):
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, image.width, image.height], radius, fill=255)
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def phone(shot, width):
    """The whole screenshot in a dark bezel, scaled to [width] overall. The
    frame is drawn complete, bottom edge included."""
    bezel = max(8, round(width * 0.016))
    inner = width - 2 * bezel
    scale = inner / shot.width
    shot = shot.resize((inner, round(shot.height * scale)), Image.LANCZOS)
    radius = round(inner * 0.052)
    body = Image.new("RGBA", (width, shot.height + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle(
        [0, 0, body.width, body.height], radius + bezel, fill=(18, 14, 34, 255)
    )
    body.alpha_composite(rounded(shot, radius), (bezel, bezel))
    return body


def caption(canvas, locale, lines, area_top, area_h):
    w, h = canvas.size
    draw = ImageDraw.Draw(canvas)

    words = "".join(lines)
    if font_for(locale, 64, words) is None:
        sys.exit(
            f"No {locale} caption font can draw every character of {lines!r}. "
            "Reword it in captions.json, or add a face that carries them."
        )

    direction = "rtl" if locale == "he" else "ltr"
    size = round(w * 0.105)
    while size > 24:
        font = font_for(locale, size, words)
        stroke = max(4, size // 9)
        if all(
            draw.textbbox((0, 0), line, font=font, direction=direction, stroke_width=stroke)[2]
            <= round(w * 0.92)
            for line in lines
        ):
            break
        size -= 4

    boxes = [
        draw.textbbox((0, 0), l, font=font, direction=direction, stroke_width=stroke)
        for l in lines
    ]
    gap = round(font.size * 0.16)
    total = sum(b[3] - b[1] for b in boxes) + gap * (len(lines) - 1)
    y = area_top + (area_h - total) // 2

    for line, box, fill in zip(lines, boxes, [WHITE, YELLOW]):
        x = (w - (box[2] - box[0])) // 2 - box[0]
        # The outline drawn once more, offset down, reads as a shadow and
        # lifts the words off whatever colour is behind them.
        draw.text(
            (x, y - box[1] + stroke),
            line,
            font=font,
            fill=INK,
            direction=direction,
            stroke_width=stroke,
            stroke_fill=INK,
        )
        draw.text(
            (x, y - box[1]),
            line,
            font=font,
            fill=fill,
            direction=direction,
            stroke_width=stroke,
            stroke_fill=INK,
        )
        y += (box[3] - box[1]) + gap


def compose(shot_path, locale, spec, size):
    w, h = size
    top, bottom = (hex_rgb(c) for c in spec["bg"])
    canvas = gradient(size, top, bottom).convert("RGBA")

    shot = Image.open(shot_path).convert("RGB")
    crop = spec.get("crop_top", 0)
    if crop:
        shot = shot.crop((0, crop, shot.width, shot.height))

    # The caption's room at the bottom; everything above it belongs to the
    # phone, sized so the whole screen and its frame fit with nothing cut.
    area_h = round(h * 0.19)
    area_top = h - area_h
    margin_top = round(h * 0.025)
    available = area_top - margin_top - round(h * 0.012)

    landscape = shot.width > shot.height
    if landscape:
        width = round(w * 0.96)
    else:
        # Solve the width from the height the screenshot may occupy: the
        # bezel is a fraction of the width, so a few passes are enough.
        width = round(w * 0.8)
        for _ in range(3):
            bezel = max(8, round(width * 0.016))
            inner_w = (available - 2 * bezel) * shot.width / shot.height
            width = min(round(w * 0.86), round(inner_w + 2 * bezel))
        # A wide canvas (the iPad set) would otherwise leave the phone
        # stranded in the middle; the caption grows with it instead.
        width = max(width, round(w * 0.42))
    device = phone(shot, width)
    while device.height > available and width > 200:
        width -= 12
        device = phone(shot, width)

    x = (w - device.width) // 2
    y = margin_top + max(0, (available - device.height) // 2)

    blur = round(w * 0.022)
    silhouette = Image.new("RGBA", device.size, (0, 0, 0, 0))
    silhouette.putalpha(device.getchannel("A").point(lambda a: a * 110 // 255))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow.paste(silhouette, (x, y + blur), silhouette)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(device, (x, y))

    caption(canvas, locale, spec[locale], area_top, area_h)
    return canvas.convert("RGB")


def main():
    if not features.check("raqm"):
        sys.exit("Pillow was built without raqm: Hebrew would come out reversed.")
    args = sys.argv[1:]
    stores = list(TARGETS)
    if "--store" in args:
        i = args.index("--store")
        stores = args[i + 1].split(",")
        unknown = [s for s in stores if s not in TARGETS]
        if unknown:
            sys.exit(f"Unknown store(s) {unknown}; pick from {list(TARGETS)}")
        del args[i : i + 2]
    spec = json.loads(CAPTIONS.read_text(encoding="utf-8"))["shots"]
    locales = args or sorted(p.name for p in RAW.iterdir() if p.is_dir())
    made = 0
    for locale in locales:
        for shot in sorted((RAW / locale).glob("*.png")):
            entry = spec.get(shot.stem)
            if entry is None or locale not in entry:
                print(f"skip {locale}/{shot.name}: no caption in captions.json")
                continue
            for store in stores:
                out = OUT / store / locale / shot.name
                out.parent.mkdir(parents=True, exist_ok=True)
                compose(shot, locale, entry, TARGETS[store]).save(out, optimize=True)
                made += 1
            print(f"ok   {locale}/{shot.name}")
    print(f"{made} images in {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
