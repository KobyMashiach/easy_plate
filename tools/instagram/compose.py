#!/usr/bin/env python3
"""Instagram images for EasyPlate, drawn in the store-screenshot look
(purple background, Rubik Black captions, the handset, the food props).

  python3 tools/instagram/compose.py                 # every post
  python3 tools/instagram/compose.py 003_week_plan   # one post

Reads   tools/instagram/posts/<id>/post.json
        store_assets/raw_panorama/<locale>/<raw>.png   (app screen only)
Writes  tools/instagram/posts/<id>/out/NN.jpg
          feed / carousel  1080x1350 (4:5, the tallest a feed post may be)
          story            1080x1920

Slide kinds in post.json:
  {"kind": "cover", "lines": [...], "sub": "...", "props": [...]}
  {"kind": "screen", "raw": "03_ai_import", "lines": [...], "props": [...]}
  {"kind": "cta", "lines": [...], "sub": "..."}
The last caption line is set in the accent yellow, as on the store images.
Instagram only takes JPEG for images, so everything is written as .jpg.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, features

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / "tools" / "store_screenshots"))
import panorama as P  # noqa: E402  (phone frame, fonts, props)

POSTS = HERE / "posts"
RAW = ROOT / "store_assets" / "raw_panorama"
ICON = ROOT / "assets" / "app_icon.png"
SIZES = {"feed": (1080, 1350), "story": (1080, 1920)}
BG = P.hex_rgb("#8E7CF3")
YELLOW = (255, 226, 92)
WHITE = (255, 255, 255)

# Where a prop may lie: (x, y) as fractions of the canvas, its size as a
# fraction of the width, and an angle. Picked by index from the slide.
CTA_SPOTS = [(-0.10, 0.80, 0.30, -18), (0.82, 0.82, 0.26, 22)]
SPOTS = [(-0.06, 0.62, 0.34, -18), (0.80, 0.70, 0.30, 22), (0.78, -0.04, 0.26, 35), (-0.08, 0.02, 0.24, -30)]


def background(W, H):
    img = Image.new("RGBA", (W, H), BG + (255,))
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse([-W * 0.3, H * 0.05, W * 1.3, H * 0.95], fill=46)
    white = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    white.putalpha(glow.filter(ImageFilter.GaussianBlur(W * 0.18)))
    img.alpha_composite(white)
    return img


def fit(lines, width, max_h, locale):
    return P.caption_size(lines, width, max_h, locale)


def centred(canvas, lines, y_top, size, locale, accent=True):
    """Centred caption with the same soft shadow as the store images."""
    d = ImageDraw.Draw(canvas)
    direction = "rtl" if locale == "he" else "ltr"
    font = P.display(locale, size)
    lead = size * 1.02
    cx = canvas.width / 2
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    for i, line in enumerate(lines):
        sd.text((cx, y_top + i * lead + size * 0.05), line, font=font, fill=(45, 20, 110, 120), anchor="ma", direction=direction)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(size * 0.05)))
    for i, line in enumerate(lines):
        fill = YELLOW if accent and i == len(lines) - 1 and len(lines) > 1 else WHITE
        d.text((cx, y_top + i * lead), line, font=font, fill=fill, anchor="ma", direction=direction)
    return y_top + len(lines) * lead


def sub_text(canvas, text, y, size, locale):
    d = ImageDraw.Draw(canvas)
    font = P.rubik(size, "Medium")
    d.text((canvas.width / 2, y), text, font=font, fill=(255, 255, 255, 235), anchor="ma",
           direction="rtl" if locale == "he" else "ltr")


def props(canvas, names, spots=SPOTS):
    W, H = canvas.size
    for i, name in enumerate(names or []):
        x, y, s, a = spots[i % len(spots)]
        im = P.prop_image(name, round(W * s), a)
        P.paste_clipped(canvas, im, W * x, H * y, shadow_blur=round(W * 0.015), strength=0.30)


def lines_for(slide, locale):
    lines = slide["lines"]
    return lines if locale == "he" else [l.upper() for l in lines]


def screen_slide(slide, size, locale, device):
    W, H = size
    canvas = background(W, H)
    props(canvas, slide.get("props"))
    lines = lines_for(slide, locale)
    cap_h = H * (0.25 if H < 1600 else 0.20)
    s = fit(lines, W * 0.86, cap_h, locale)
    top = H * 0.055
    bottom = centred(canvas, lines, top, s, locale)
    raw = Image.open(RAW / locale / f"{slide['raw']}.png")
    pw = round(W * (0.60 if H < 1600 else 0.70))
    ph = P.phone(raw, pw, device, locale == "he")
    # The handset runs off the bottom edge: the top of the screen is what
    # carries the message, and a cut phone reads as "there is more".
    P.paste_clipped(canvas, ph, (W - pw) / 2, bottom + H * 0.03, shadow_blur=round(W * 0.03), strength=0.35)
    return canvas


def cover_slide(slide, size, locale):
    W, H = size
    canvas = background(W, H)
    props(canvas, slide.get("props"))
    lines = lines_for(slide, locale)
    s = fit(lines, W * 0.84, H * 0.42, locale)
    block = len(lines) * s * 1.02 + (s * 0.6 if slide.get("sub") else 0)
    y = (H - block) / 2 - H * 0.03
    end = centred(canvas, lines, y, s, locale)
    if slide.get("sub"):
        sub_text(canvas, slide["sub"], end + s * 0.25, round(W * 0.045), locale)
    swipe = "החליקו לעוד" if locale == "he" else "Swipe for more"
    if slide.get("swipe", True):
        sub_text(canvas, swipe, H * 0.90, round(W * 0.038), locale)
    return canvas


def cta_slide(slide, size, locale):
    W, H = size
    canvas = background(W, H)
    props(canvas, slide.get("props"), CTA_SPOTS)
    icon_w = round(W * 0.30)
    icon = Image.open(ICON).convert("RGBA").resize((icon_w, icon_w), Image.LANCZOS)
    icon.putalpha(P.rounded_mask(icon.size, round(icon_w * 0.22)))
    y_icon = H * 0.16
    P.paste_clipped(canvas, icon, (W - icon_w) / 2, y_icon, shadow_blur=round(W * 0.02), strength=0.35)
    lines = lines_for(slide, locale)
    s = fit(lines, W * 0.66, H * 0.22, locale)
    end = centred(canvas, lines, y_icon + icon_w + H * 0.06, s, locale)
    if slide.get("sub"):
        sub_text(canvas, slide["sub"], end + s * 0.3, round(W * 0.045), locale)
    return canvas


def render(post_dir):
    spec = json.loads((post_dir / "post.json").read_text(encoding="utf-8"))
    locale = spec.get("locale", "he")
    device = spec.get("device", "iphone")
    size = SIZES["story" if spec["type"] == "story" else "feed"]
    out = post_dir / "out"
    out.mkdir(exist_ok=True)
    for old in out.glob("*.jpg"):
        old.unlink()
    for i, slide in enumerate(spec.get("slides", [])):
        kind = slide.get("kind", "screen")
        if kind == "cover":
            img = cover_slide(slide, size, locale)
        elif kind == "cta":
            img = cta_slide(slide, size, locale)
        else:
            img = screen_slide(slide, size, locale, device)
        img.convert("RGB").save(out / f"{i + 1:02d}.jpg", quality=92, optimize=True)
    print(f"ok   {post_dir.name}: {len(spec.get('slides', []))} images")


def main():
    if not features.check("raqm"):
        sys.exit("Pillow was built without raqm: Hebrew would come out reversed.")
    ids = sys.argv[1:]
    dirs = [POSTS / i for i in ids] if ids else sorted(p for p in POSTS.iterdir() if (p / "post.json").exists())
    for d in dirs:
        render(d)


if __name__ == "__main__":
    main()
