#!/usr/bin/env python3
"""Store screenshots as one continuous strip: eight app screens on a soft
purple background, with food lying across the joins and hand-drawn arrows
leading from each screen to the next. The strip is cut into eight store
images, so swiping through the listing reads as one picture.

  python3 tools/store_screenshots/panorama.py                 # everything
  python3 tools/store_screenshots/panorama.py he --device iphone
  python3 tools/store_screenshots/panorama.py en --preview    # + the whole strip

Reads   store_assets/raw_panorama/<locale>/<NN_name>.png   app screen only:
          no status bar and no navigation bar (capture_panorama.sh crops them)
        tools/store_screenshots/panorama.json   order, captions, props
        tools/store_screenshots/props/*.png     the cut-out food (CREDITS.txt)
Writes  store_assets/listing_panorama/<device>/<locale>/NN.png
          iphone  1320x2868  App Store 6.9", iPhone frame + iOS status bar
          android 1080x1920  Google Play phone, Galaxy frame + Android bar

Hebrew reads from the right: its first screen is the rightmost slice of the
strip and the arrows point left, the way the stores lay out an RTL listing.
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, features

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
RAW = ROOT / "store_assets" / "raw_panorama"
OUT = ROOT / "store_assets" / "listing_panorama"
SPEC = HERE / "panorama.json"
PROPS = HERE / "props"
RUBIK = HERE / "fonts" / "Rubik.ttf"
# English captions are set in a poster face, in capitals, the way food ads
# shout; Hebrew has no capitals and stays in Rubik Black.
ARCHIVO = HERE / "fonts" / "ArchivoBlack-Regular.ttf"
SF = "/System/Library/Fonts/SFNS.ttf"

DEVICES = {"iphone": (1320, 2868), "android": (1080, 1920)}

# The phone's screen, height over width.
SCREEN_RATIO = 2.165


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def rubik(size, weight="Black"):
    font = ImageFont.truetype(str(RUBIK), size, layout_engine=ImageFont.Layout.RAQM)
    font.set_variation_by_name(weight)
    return font


def display(locale, size):
    if locale == "he":
        return rubik(size)
    return ImageFont.truetype(str(ARCHIVO), size, layout_engine=ImageFont.Layout.RAQM)


def sf(size, weight="Semibold"):
    font = ImageFont.truetype(SF, size)
    try:
        font.set_variation_by_name(weight)
    except (OSError, ValueError):
        pass
    return font


def rounded_mask(size, radius, scale=4):
    w, h = size
    big = Image.new("L", (w * scale, h * scale), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        [0, 0, w * scale - 1, h * scale - 1], radius * scale, fill=255
    )
    return big.resize(size, Image.LANCZOS)


# ---------------------------------------------------------------- status bars


def ios_status_bar(width, height, ink, rtl):
    """Clock, signal, wifi and battery as an iPhone draws them. In a
    right-to-left phone the clock sits on the right."""
    bar = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(bar)
    u = width / 393  # one iPhone point
    cy = height * 0.56
    font = sf(round(17 * u))
    clock_x = 52 * u if not rtl else width - 52 * u
    d.text((clock_x, cy), "9:41", font=font, fill=ink, anchor="mm")

    icons_center = width - 62 * u if not rtl else 62 * u
    # Signal: four rising bars.
    x0 = icons_center - 34 * u
    for i in range(4):
        bh = (4.5 + i * 2.6) * u
        bx = x0 + i * 5 * u
        d.rounded_rectangle(
            [bx, cy + 5.5 * u - bh, bx + 3.2 * u, cy + 5.5 * u], 1 * u, fill=ink
        )
    # Wifi: three arcs and a dot.
    wx, wy = icons_center + 1 * u, cy + 5 * u
    for r in (11.5, 7.8, 4.1):
        d.pieslice(
            [wx - r * u, wy - r * u, wx + r * u, wy + r * u], 225, 315, fill=ink
        )
        inner = r - 2.2
        if inner > 0:
            d.pieslice(
                [wx - inner * u, wy - inner * u, wx + inner * u, wy + inner * u],
                225,
                315,
                fill=(0, 0, 0, 0),
            )
    # Battery: outline, fill and the nub.
    bx = icons_center + 16 * u
    d.rounded_rectangle(
        [bx, cy - 6 * u, bx + 25 * u, cy + 6 * u], 4 * u, outline=ink + (110,) if len(ink) == 3 else ink, width=max(1, round(1.2 * u))
    )
    d.rounded_rectangle([bx + 2.2 * u, cy - 3.8 * u, bx + 22.8 * u, cy + 3.8 * u], 2.2 * u, fill=ink)
    d.rounded_rectangle([bx + 26.2 * u, cy - 2.2 * u, bx + 27.8 * u, cy + 2.2 * u], 1 * u, fill=ink)
    return bar


def android_status_bar(width, height, ink, rtl):
    bar = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(bar)
    u = width / 412  # one Android dp on a 412dp-wide phone
    cy = height * 0.52
    font = sf(round(14 * u), "Medium")
    clock_x = 26 * u if not rtl else width - 26 * u
    d.text((clock_x, cy), "9:41", font=font, fill=ink, anchor="lm" if not rtl else "rm")
    right = width - 22 * u if not rtl else 22 * u + 44 * u
    # Battery, a filled upright pill.
    bx = right - 9 * u
    d.rounded_rectangle([bx, cy - 7 * u, bx + 8 * u, cy + 7 * u], 1.6 * u, fill=ink)
    d.rectangle([bx + 2.5 * u, cy - 8.4 * u, bx + 5.5 * u, cy - 7 * u], fill=ink)
    # Signal, a solid triangle.
    sx = bx - 8 * u
    d.polygon([(sx, cy + 6 * u), (sx, cy - 7 * u), (sx - 13 * u, cy + 6 * u)], fill=ink)
    # Wifi, a filled fan.
    wx, wy = sx - 26 * u, cy + 6 * u
    d.pieslice([wx - 13 * u, wy - 13 * u, wx + 13 * u, wy + 13 * u], 225, 315, fill=ink)
    return bar


def luminance(rgb):
    r, g, b = rgb[:3]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


# ---------------------------------------------------------------- devices


def screen(raw, width, device, rtl):
    """The app screen at [width], with the platform's status bar painted
    above it in the colour of the app's own top edge."""
    height = round(width * SCREEN_RATIO)
    bar_h = round(width * (0.137 if device == "iphone" else 0.085))
    shot = raw.convert("RGB")
    scale = width / shot.width
    shot = shot.resize((width, round(shot.height * scale)), Image.LANCZOS)
    top = shot.getpixel((width // 2, 2))
    bottom = shot.getpixel((width // 2, shot.height - 3))
    out = Image.new("RGB", (width, height), bottom)
    out.paste(Image.new("RGB", (width, bar_h), top), (0, 0))
    out.paste(shot.crop((0, 0, width, min(shot.height, height - bar_h))), (0, bar_h))
    ink = (20, 20, 24) if luminance(top) > 140 else (250, 250, 252)
    painter = ios_status_bar if device == "iphone" else android_status_bar
    bar = painter(width, bar_h, ink, rtl)
    out = out.convert("RGBA")
    out.alpha_composite(bar)
    d = ImageDraw.Draw(out)
    if device == "iphone":
        # The home indicator.
        hw, hh = width * 0.36, width * 0.013
        hy = height - width * 0.024
        hink = (20, 20, 24, 230) if luminance(bottom) > 140 else (250, 250, 252, 230)
        d.rounded_rectangle([width / 2 - hw / 2, hy - hh, width / 2 + hw / 2, hy], hh / 2, fill=hink)
    else:
        hw, hh = width * 0.30, width * 0.010
        hy = height - width * 0.022
        hink = (60, 60, 66, 200) if luminance(bottom) > 140 else (230, 230, 235, 200)
        d.rounded_rectangle([width / 2 - hw / 2, hy - hh, width / 2 + hw / 2, hy], hh / 2, fill=hink)
    return out


def phone(raw, width, device, rtl):
    """The whole handset at [width]: frame, buttons, camera cut-out."""
    if device == "iphone":
        rim, bezel = 0.010, 0.030
        radius_k, button_k = 0.155, 0.010
    else:
        rim, bezel = 0.008, 0.020
        radius_k, button_k = 0.090, 0.008
    pad = round(width * button_k)  # room for the side buttons
    body_w = width - 2 * pad
    rim_px = max(2, round(body_w * rim))
    bezel_px = round(body_w * bezel)
    inner_w = body_w - 2 * (rim_px + bezel_px)
    scr = screen(raw, inner_w, device, rtl)
    body_h = scr.height + 2 * (rim_px + bezel_px)
    radius = round(body_w * radius_k)

    out = Image.new("RGBA", (width, body_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    metal = (150, 148, 160) if device == "iphone" else (60, 62, 70)
    # Side buttons first so the body covers their inner half.
    bw = pad + rim_px
    if device == "iphone":
        for top, length in ((0.17, 0.05), (0.25, 0.09), (0.36, 0.09)):
            d.rounded_rectangle([0, body_h * top, bw * 2, body_h * (top + length)], bw, fill=metal)
        d.rounded_rectangle([width - bw * 2, body_h * 0.27, width, body_h * 0.41], bw, fill=metal)
    else:
        d.rounded_rectangle([width - bw * 2, body_h * 0.20, width, body_h * 0.30], bw, fill=metal)
        d.rounded_rectangle([width - bw * 2, body_h * 0.33, width, body_h * 0.39], bw, fill=metal)

    body = Image.new("RGBA", (body_w, body_h), metal + (255,))
    body.putalpha(rounded_mask((body_w, body_h), radius))
    black = Image.new("RGBA", (body_w - 2 * rim_px, body_h - 2 * rim_px), (12, 12, 14, 255))
    black.putalpha(rounded_mask(black.size, radius - rim_px))
    body.alpha_composite(black, (rim_px, rim_px))
    # A faint highlight along the metal edge.
    hl = Image.new("RGBA", (body_w, body_h), (255, 255, 255, 0))
    ImageDraw.Draw(hl).rounded_rectangle(
        [1, 1, body_w - 2, body_h - 2], radius, outline=(255, 255, 255, 70), width=max(1, rim_px // 2)
    )
    body.alpha_composite(hl)
    scr_mask = rounded_mask(scr.size, radius - rim_px - bezel_px)
    scr.putalpha(ImageChops.multiply(scr.getchannel("A"), scr_mask))
    body.alpha_composite(scr, (rim_px + bezel_px, rim_px + bezel_px))

    bd = ImageDraw.Draw(body)
    sx = rim_px + bezel_px
    if device == "iphone":
        iw, ih = inner_w * 0.315, inner_w * 0.093
        iy = sx + inner_w * 0.028
        bd.rounded_rectangle(
            [body_w / 2 - iw / 2, iy, body_w / 2 + iw / 2, iy + ih], ih / 2, fill=(0, 0, 0, 255)
        )
        lens = ih * 0.36
        lx = body_w / 2 + iw / 2 - ih * 0.55
        bd.ellipse([lx - lens / 2, iy + ih / 2 - lens / 2, lx + lens / 2, iy + ih / 2 + lens / 2], fill=(22, 24, 40, 255))
    else:
        r = inner_w * 0.022
        cy = sx + inner_w * 0.042
        bd.ellipse([body_w / 2 - r, cy - r, body_w / 2 + r, cy + r], fill=(0, 0, 0, 255))
    out.alpha_composite(body, (pad, 0))
    return out


def shadowed(layer, canvas, xy, blur, strength=0.32, drop=None):
    """Pastes [layer] with a soft shadow under it."""
    x, y = xy
    drop = blur * 0.6 if drop is None else drop
    a = layer.getchannel("A").point(lambda v: round(v * strength))
    pad = blur * 3
    sh = Image.new("L", (layer.width + 2 * pad, layer.height + 2 * pad), 0)
    sh.paste(a, (pad, pad))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    tint = Image.new("RGBA", sh.size, (40, 20, 90, 0))
    tint.putalpha(sh)
    canvas.alpha_composite(tint, (round(x - pad), round(y - pad + drop)), )
    canvas.alpha_composite(layer, (round(x), round(y)))


def paste_clipped(canvas, layer, x, y, shadow_blur=None, strength=0.32):
    """alpha_composite that tolerates a layer hanging off any edge."""
    big = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    if shadow_blur:
        pad = shadow_blur * 3
        a = layer.getchannel("A").point(lambda v: round(v * strength))
        sh = Image.new("L", (layer.width + 2 * pad, layer.height + 2 * pad), 0)
        sh.paste(a, (pad, pad))
        sh = sh.filter(ImageFilter.GaussianBlur(shadow_blur))
        tint = Image.new("RGBA", sh.size, (40, 20, 90, 0))
        tint.putalpha(sh)
        big.paste(tint, (round(x - pad), round(y - pad + shadow_blur * 0.7)), tint)
        canvas.alpha_composite(big)
        big = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    big.paste(layer, (round(x), round(y)), layer)
    canvas.alpha_composite(big)


# ---------------------------------------------------------------- props


def prop_image(name, size, angle):
    im = Image.open(PROPS / f"{name}.png").convert("RGBA")
    scale = size / max(im.size)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    if angle:
        im = im.rotate(angle, resample=Image.BICUBIC, expand=True)
    return im


NOTES = {
    "grocery_note": {
        "he": ("רשימת קניות", [("", "עגבניות"), ("", "אבוקדו"), ("", "לימון"), ("", "פסטה"), ("", "שום")]),
        "en": ("Shopping list", [("", "Tomatoes"), ("", "Avocado"), ("", "Lemons"), ("", "Pasta"), ("", "Garlic")]),
    },
    "menu_note": {
        "he": ("תפריט שבועי", [("א׳", "שקשוקה"), ("ב׳", "מרק עדשים"), ("ג׳", "שניצל ופירה"), ("ד׳", "פסטה ברוטב"), ("ה׳", "קציצות ואורז")]),
        "en": ("Weekly menu", [("Mon", "Shakshuka"), ("Tue", "Lentil soup"), ("Wed", "Schnitzel"), ("Thu", "Pasta"), ("Fri", "Meatballs")]),
    },
}


def paper_note(kind, size, locale, angle):
    """A notepad page — the shopping list with ticks, or the week's menu
    with its days — drawn rather than photographed so it is written in the
    listing's language."""
    w, h = round(size * 0.78), round(size)
    note = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    paper = Image.new("RGBA", (w, h), (255, 251, 238, 255))
    paper.putalpha(rounded_mask((w, h), round(w * 0.04)))
    note.alpha_composite(paper)
    d = ImageDraw.Draw(note)
    rtl = locale == "he"
    direction = "rtl" if rtl else "ltr"
    title, rows = NOTES[kind]["he" if rtl else "en"]
    margin = w * 0.11
    for i in range(7):
        y = h * (0.27 + i * 0.105)
        d.line([(w * 0.05, y + h * 0.05), (w * 0.95, y + h * 0.05)], fill=(170, 200, 230, 255), width=max(1, round(w * 0.006)))
    tx = w - margin if rtl else margin
    d.text((tx, h * 0.15), title, font=rubik(round(w * 0.105), "Bold"), fill=(60, 40, 120), anchor="rm" if rtl else "lm", direction=direction)
    font = rubik(round(w * 0.085), "Medium")
    day_font = rubik(round(w * 0.075), "Bold")
    for i, (day, item) in enumerate(rows):
        y = h * (0.27 + i * 0.105) + h * 0.015
        box = w * 0.075
        lead = w - margin if rtl else margin
        if kind == "grocery_note":
            bx = lead - box if rtl else lead
            d.rounded_rectangle([bx, y - box / 2, bx + box, y + box / 2], box * 0.2, outline=(90, 70, 170), width=max(2, round(w * 0.01)))
            done = i in (0, 2)
            if done:
                d.line([(bx + box * 0.2, y), (bx + box * 0.45, y + box * 0.28), (bx + box * 0.85, y - box * 0.35)], fill=(20, 170, 120), width=max(2, round(w * 0.014)))
            ix = bx - box * 0.45 if rtl else bx + box * 1.45
        else:
            done = False
            d.text((lead, y), day, font=day_font, fill=(110, 80, 220), anchor="rm" if rtl else "lm", direction=direction)
            ix = lead - w * 0.17 if rtl else lead + w * 0.20
        d.text((ix, y), item, font=font, fill=(150, 145, 170) if done else (50, 45, 70), anchor="rm" if rtl else "lm", direction=direction)
        if done:
            tw = d.textlength(item, font=font, direction=direction)
            sx0 = ix - tw if rtl else ix
            d.line([(sx0, y), (sx0 + tw, y)], fill=(150, 145, 170), width=max(2, round(w * 0.008)))
    return note.rotate(angle, resample=Image.BICUBIC, expand=True)


# ---------------------------------------------------------------- arrows


def bezier(p0, p1, p2, steps=60):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


ARROW = (255, 214, 0, 255)


def arrow(canvas, start, end, bend, width):
    """A strong yellow hand-drawn arrow from [start] to [end], bowed by [bend]
    (a fraction of its length, positive = bowed downwards)."""
    sx, sy = start
    ex, ey = end
    mx, my = (sx + ex) / 2, (sy + ey) / 2
    length = math.hypot(ex - sx, ey - sy)
    nx, ny = -(ey - sy) / length, (ex - sx) / length
    if ny < 0:
        nx, ny = -nx, -ny
    ctrl = (mx + nx * bend * length, my + ny * bend * length)
    pts = bezier(start, ctrl, end)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.line(pts, fill=ARROW, width=width, joint="curve")
    r = width / 2
    for p in (pts[0], pts[-1]):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=ARROW)
    # The head: two strokes back from the tip along the curve's last heading.
    tx, ty = pts[-1]
    px, py = pts[-6]
    ang = math.atan2(ty - py, tx - px)
    head = width * 4.2
    for side in (-1, 1):
        a = ang + math.pi + side * 0.62
        hx, hy = tx + head * math.cos(a), ty + head * math.sin(a)
        d.line([(tx, ty), (hx, hy)], fill=ARROW, width=width)
        d.ellipse([hx - r, hy - r, hx + r, hy + r], fill=ARROW)
    # A tight dark shadow so the yellow holds against white screens too.
    sh = layer.getchannel("A").point(lambda v: v * 110 // 255).filter(ImageFilter.GaussianBlur(width * 0.6))
    tint = Image.new("RGBA", canvas.size, (40, 20, 90, 0))
    tint.putalpha(sh)
    canvas.alpha_composite(tint, (0, round(width * 0.35)))
    canvas.alpha_composite(layer)


# ---------------------------------------------------------------- captions


def caption_size(lines, width, max_h, locale):
    """The largest type that fits [lines] in [width] x [max_h]."""
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    direction = "rtl" if locale == "he" else "ltr"
    size = round(max_h / (len(lines) * 0.98))
    while size > 20:
        font = display(locale, size)
        widest = max(d.textlength(line, font=font, direction=direction) for line in lines)
        if widest <= width:
            break
        size -= 4
    return size


def caption(canvas, lines, x0, x1, y_top, size, locale, accent_line):
    d = ImageDraw.Draw(canvas)
    rtl = locale == "he"
    direction = "rtl" if rtl else "ltr"
    font = display(locale, size)
    lead = size * 0.98
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    for i, line in enumerate(lines):
        y = y_top + i * lead
        x = x1 if rtl else x0
        anchor = "ra" if rtl else "la"
        sd.text((x, y + size * 0.05), line, font=font, fill=(45, 20, 110, 120), anchor=anchor, direction=direction)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(size * 0.05)))
    for i, line in enumerate(lines):
        y = y_top + i * lead
        x = x1 if rtl else x0
        anchor = "ra" if rtl else "la"
        fill = (255, 226, 92) if i == accent_line else (255, 255, 255)
        d.text((x, y), line, font=font, fill=fill, anchor=anchor, direction=direction)
    return y_top + len(lines) * lead


# ---------------------------------------------------------------- the strip


def caption_lines(shot, locale):
    lines = shot[locale] if locale in shot else shot["en"]
    return lines if locale == "he" else [line.upper() for line in lines]


def build_strip(locale, device, spec):
    W, H = DEVICES[device]
    shots = spec["shots"]
    n = len(shots)
    rtl = locale == "he"
    bg = hex_rgb(spec["background"])
    strip = Image.new("RGBA", (W * n, H), bg + (255,))

    # A very soft vertical glow keeps the flat colour from looking dead,
    # and it runs the full strip so no seam shows between slices.
    glow = Image.new("L", (1, H))
    for y in range(H):
        t = y / (H - 1)
        glow.putpixel((0, y), round(34 * (1 - abs(t - 0.45) / 0.55) if abs(t - 0.45) < 0.55 else 0))
    light = Image.new("RGBA", strip.size, (255, 255, 255, 0))
    light.putalpha(glow.resize(strip.size))
    strip.alpha_composite(light)

    def pos(i):
        return n - 1 - i if rtl else i

    def panel_x(i):
        return pos(i) * W

    def boundary_x(i):
        """The join between reading-order shots i and i+1 (i = -1 or n-1
        are the strip's outer edges)."""
        if rtl:
            return W * (n - 1 - i)
        return W * (i + 1)

    # Captions alternate: above an upright phone that runs off the bottom
    # edge, then below a tilted phone that hangs from the top. Each caption
    # gets its own size (the fit, scaled by a fixed rhythm), so the set does
    # not read as one repeated template.
    margin = W * 0.085
    cap_h = H * 0.17
    rhythm = [1.0, 0.90, 0.95, 0.88, 1.0, 0.90, 0.94, 0.88]
    layouts = []
    for i, shot in enumerate(shots):
        lines = caption_lines(shot, locale)
        size = round(caption_size(lines, W - 2 * margin, cap_h, locale) * rhythm[i % len(rhythm)])
        block = len(lines) * size * 0.98
        if i % 2 == 0:
            cap_y = H * 0.05
            ph_w = W * (0.74 if device == "iphone" else 0.68)
            layouts.append(dict(kind="top", size=size, cap_y=cap_y, angle=0, ph_w=round(ph_w),
                                py=cap_y + block + H * 0.03, room=None))
        else:
            cap_y = H * 0.955 - block
            top = H * 0.04
            room = cap_y - H * 0.03 - top
            ph_w = min(W * (0.72 if device == "iphone" else 0.66), room / (SCREEN_RATIO * 1.13))
            angle = (5 if i % 4 == 1 else -5) * (-1 if rtl else 1)
            layouts.append(dict(kind="bottom", size=size, cap_y=cap_y, angle=angle, ph_w=round(ph_w),
                                py=top, room=room))

    unit = min(W, H * 0.46)

    def place_props(front):
        for p in spec["props"]:
            if bool(p.get("front")) != front:
                continue
            bx = boundary_x(p["after"]) + (p.get("dx", 0) * unit) * (-1 if rtl else 1)
            y = H * p["y"]
            size = unit * p["size"]
            angle = p.get("angle", 0) * (-1 if rtl else 1)
            if p["name"] in NOTES:
                im = paper_note(p["name"], size, locale, angle)
            else:
                im = prop_image(p["name"], size, angle)
            paste_clipped(strip, im, bx - im.width / 2, y - im.height / 2,
                          shadow_blur=round(unit * 0.025), strength=0.38)

    # Food lies under the phones; a prop marked "front" (the paper notes)
    # sits over the phones' edges, the way a note lies on a counter.
    place_props(front=False)

    # Phones and captions.
    for i, (shot, lay) in enumerate(zip(shots, layouts)):
        raw_path = RAW / locale / f"{shot['raw']}.png"
        if not raw_path.exists():
            raw_path = RAW / "he" / f"{shot['raw']}.png"
        ph = phone(Image.open(raw_path), lay["ph_w"], device, rtl)
        if lay["angle"]:
            ph = ph.rotate(lay["angle"], resample=Image.BICUBIC, expand=True)
        if lay["room"] and ph.height > lay["room"]:
            k = lay["room"] / ph.height
            ph = ph.resize((round(ph.width * k), round(ph.height * k)), Image.LANCZOS)
        px = panel_x(i) + (W - ph.width) / 2
        paste_clipped(strip, ph, px, lay["py"], shadow_blur=round(W * 0.03), strength=0.42)
        lines = caption_lines(shot, locale)
        caption(strip, lines, panel_x(i) + margin, panel_x(i) + W - margin,
                lay["cap_y"], lay["size"], locale, accent_line=len(lines) - 1)

    place_props(front=True)

    # Arrows across each join, from one phone's edge to the next.
    aw = max(6, round(W * 0.011))
    d = -1 if rtl else 1
    for i in range(n - 1):
        bx = boundary_x(i)
        span = W * 0.34
        y_from = H * (0.50 if i % 2 == 0 else 0.46)
        y_to = H * (0.46 if i % 2 == 0 else 0.50)
        arrow(strip, (bx - d * span / 2, y_from), (bx + d * span / 2, y_to), bend=0.30, width=aw)

    return strip.convert("RGB")


def main():
    if not features.check("raqm"):
        sys.exit("Pillow was built without raqm: Hebrew would come out reversed.")
    args = sys.argv[1:]
    devices = list(DEVICES)
    preview = "--preview" in args
    if preview:
        args.remove("--preview")
    if "--device" in args:
        i = args.index("--device")
        devices = args[i + 1].split(",")
        del args[i : i + 2]
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    locales = args or ["he", "en"]
    for device in devices:
        W, H = DEVICES[device]
        for locale in locales:
            strip = build_strip(locale, device, spec)
            out = OUT / device / locale
            out.mkdir(parents=True, exist_ok=True)
            n = len(spec["shots"])
            rtl = locale == "he"
            for i in range(n):
                p = n - 1 - i if rtl else i
                strip.crop((p * W, 0, (p + 1) * W, H)).save(out / f"{i + 1:02d}.png", optimize=True)
            if preview:
                small = strip.resize((strip.width // 4, strip.height // 4), Image.LANCZOS)
                small.save(OUT / f"strip_{device}_{locale}.jpg", quality=88)
            print(f"ok   {device}/{locale}: {n} images")


if __name__ == "__main__":
    main()
