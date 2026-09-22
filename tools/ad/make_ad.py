#!/usr/bin/env python3
"""Builds the 30-second TikTok ad from the store screenshots.

  python3 tools/ad/make_ad.py

Reads   tools/ad/ad_script.json        (the beats, on-screen text, voiceover)
        store_assets/raw/<locale>/*.png (the same screens the store listing uses)
Writes  store_assets/ad/ad_<locale>_30s.mp4           video + voice + music
        store_assets/ad/ad_<locale>_30s_no_voice.mp4  video + music only
        store_assets/ad/ad_<locale>_script.txt        the read-aloud script with timings

The voice is macOS's own Hebrew speaker, a stand-in so the cut is timed to
real speech; swap in a recorded read (or TikTok's own voice) over the
no-voice cut. The music is synthesised here, so nothing in the file is
anyone else's to license.
"""
import json
import math
import shutil
import struct
import subprocess
import sys
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "store_screenshots"))
import compose  # noqa: E402  (the store composer: gradient, phone frame, fonts)

from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(__file__).with_name("ad_script.json")
RAW = ROOT / "store_assets" / "raw"
OUT = ROOT / "store_assets" / "ad"
WORK = OUT / ".work"

SIZE = (1080, 1920)
RATE = 44100
# The deep brand purple, and the warm end each beat's background drifts to.
BG_TOP = "#4A2FC4"
BG_BOTTOM = "#8B6BFF"
WHITE = (255, 255, 255)
YELLOW = (255, 221, 51)
INK = (28, 16, 64)


# --------------------------------------------------------------------------
# picture
# --------------------------------------------------------------------------

def ease(t):
    """Smooth in and out, for motion that never starts or stops abruptly."""
    return t * t * (3 - 2 * t)


def beat_background(index, total):
    """The gradient drifts through the palette across the cut, so the ad
    reads as one piece rather than ten unrelated cards."""
    hue = index / max(1, total - 1)
    top = tuple(
        round(a + (b - a) * hue)
        for a, b in zip(compose.hex_rgb(BG_TOP), compose.hex_rgb("#B8398A"))
    )
    bottom = tuple(
        round(a + (b - a) * hue)
        for a, b in zip(compose.hex_rgb(BG_BOTTOM), compose.hex_rgb("#FF9FD0"))
    )
    return compose.gradient(SIZE, top, bottom).convert("RGBA")


def load_phone(shot, locale):
    path = RAW / locale / f"{shot}.png"
    image = Image.open(path).convert("RGB")
    # Device captures carry a status bar; the rendered ones do not.
    if image.height == 2340:
        image = image.crop((0, 74, image.width, image.height))
    return compose.phone(image, round(SIZE[0] * 0.70))


def scrim(canvas):
    """A dark wash rising from the bottom edge, so the words read over
    whatever colour or screenshot happens to be behind them."""
    w, h = canvas.size
    band = round(h * 0.34)
    column = Image.new("RGBA", (1, band), (0, 0, 0, 0))
    for y in range(band):
        t = (y / max(1, band - 1)) ** 1.5
        column.putpixel((0, y), (12, 6, 30, round(165 * t)))
    canvas.alpha_composite(column.resize((w, band)), (0, h - band))


def caption(canvas, lines, locale, subs=None, alpha=255):
    w, h = canvas.size
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    words = "".join(lines)
    size = round(w * 0.095)
    while size > 24:
        font = compose.font_for(locale, size, words)
        # Thinner than the store frames': at this size a heavier outline
        # closes the counters of Hebrew letters into a solid block.
        stroke = max(3, size // 13)
        if font is None:
            sys.exit(f"No {locale} font can draw {lines!r}")
        if all(
            draw.textbbox((0, 0), l, font=font, stroke_width=stroke)[2] <= round(w * 0.9)
            for l in lines
        ):
            break
        size -= 4
    direction = "rtl" if locale == "he" else "ltr"
    boxes = [
        draw.textbbox((0, 0), l, font=font, direction=direction, stroke_width=stroke)
        for l in lines
    ]
    gap = round(size * 0.16)
    total = sum(b[3] - b[1] for b in boxes) + gap * (len(lines) - 1)
    y = h - round(h * (0.115 if subs else 0.06)) - total
    for line, box, fill in zip(lines, boxes, [WHITE, YELLOW]):
        x = (w - (box[2] - box[0])) // 2 - box[0]
        draw.text((x, y - box[1] + stroke), line, font=font, fill=INK,
                  direction=direction, stroke_width=stroke, stroke_fill=INK)
        draw.text((x, y - box[1]), line, font=font, fill=fill,
                  direction=direction, stroke_width=stroke, stroke_fill=INK)
        y += (box[3] - box[1]) + gap
    # A quieter line under the headline, for the features the read cannot
    # reach in thirty seconds.
    for sub in reversed(subs or []):
        small = compose.font_for(locale, round(size * 0.30), sub)
        if small is None:
            continue
        box = draw.textbbox((0, 0), sub, font=small, direction=direction)
        y_sub = h - round(h * 0.022) - (box[3] - box[1])
        x = (w - (box[2] - box[0])) // 2 - box[0]
        draw.text((x, y_sub - box[1]), sub, font=small, fill=WHITE, direction=direction)
        h -= (box[3] - box[1]) + round(size * 0.12)

    if alpha < 255:
        layer.putalpha(layer.getchannel("A").point(lambda a: a * alpha // 255))
    canvas.alpha_composite(layer)


def beat_frame(beat, index, total, progress, locale, cache):
    """One frame of a beat: the phone drifting slowly upward and closer."""
    canvas = beat_background(index, total).copy()

    if beat["shot"] is not None:
        device = cache.setdefault(beat["shot"], load_phone(beat["shot"], locale))
        scale = 1.0 + 0.05 * progress
        size = (round(device.width * scale), round(device.height * scale))
        frame = device.resize(size, Image.LANCZOS)
        x = (SIZE[0] - frame.width) // 2
        # Starts a little low and rises; the caption keeps the bottom.
        y = round(SIZE[1] * 0.035 - SIZE[1] * 0.018 * progress)
        blur = 26
        shadow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
        silhouette = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        silhouette.putalpha(frame.getchannel("A").point(lambda a: a * 120 // 255))
        shadow.paste(silhouette, (x, y + blur), silhouette)
        canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
        canvas.alpha_composite(frame, (x, y))
    else:
        icon = cache.setdefault("_icon", Image.open(ROOT / "assets" / "app_icon.png").convert("RGBA"))
        side = round(SIZE[0] * (0.42 + 0.03 * progress))
        art = icon.resize((side, side), Image.LANCZOS)
        canvas.alpha_composite(art, ((SIZE[0] - side) // 2, round(SIZE[1] * 0.26)))

    scrim(canvas)
    caption(canvas, beat["text"], locale, subs=beat.get("sub"))
    return canvas.convert("RGB")


def render_video(spec, locale, path):
    fps, duration = spec["fps"], spec["duration"]
    beats = spec["beats"]
    frames = round(fps * duration)
    fade = 0.28  # seconds of cross-fade between beats
    cache = {}

    proc = subprocess.Popen(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{SIZE[0]}x{SIZE[1]}",
         "-r", str(fps), "-i", "-",
         "-c:v", "libx264", "-preset", "medium", "-crf", "20",
         "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(path)],
        stdin=subprocess.PIPE,
    )

    def bounds(i):
        start = beats[i]["at"]
        end = beats[i + 1]["at"] if i + 1 < len(beats) else duration
        return start, end

    for f in range(frames):
        t = f / fps
        index = max(i for i in range(len(beats)) if beats[i]["at"] <= t)
        start, end = bounds(index)
        progress = ease(min(1.0, (t - start) / max(0.001, end - start)))
        frame = beat_frame(beats[index], index, len(beats), progress, locale, cache)

        # The first moments of a beat dissolve out of the one before it.
        if index > 0 and t - start < fade:
            prev_start, prev_end = bounds(index - 1)
            prev_progress = ease(min(1.0, (t - prev_start) / max(0.001, prev_end - prev_start)))
            previous = beat_frame(beats[index - 1], index - 1, len(beats), prev_progress, locale, cache)
            frame = Image.blend(previous, frame, ease((t - start) / fade))

        proc.stdin.write(frame.tobytes())
        if f % 60 == 0:
            print(f"  frame {f}/{frames}", flush=True)

    proc.stdin.close()
    if proc.wait() != 0:
        sys.exit("ffmpeg failed while writing the video")


# --------------------------------------------------------------------------
# sound
# --------------------------------------------------------------------------

def write_music(path, duration):
    """A simple four-chord bed, synthesised: soft plucks over a pad and a
    quiet pulse. Nobody's rights are involved."""
    # A minor, F, C, G — two seconds a chord, under a spoken voice.
    progression = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
    bar = 2.0
    samples = int(RATE * duration)
    out = [0.0] * samples

    def freq(midi):
        return 440.0 * (2 ** ((midi - 69) / 12))

    def add(start, dur, f, gain, decay, harmonics=(1.0, 0.35, 0.12)):
        a = int(start * RATE)
        n = int(dur * RATE)
        for i in range(n):
            if a + i >= samples:
                break
            t = i / RATE
            env = math.exp(-decay * t) * min(1.0, t * 220)
            v = 0.0
            for k, weight in enumerate(harmonics, start=1):
                v += weight * math.sin(2 * math.pi * f * k * t)
            out[a + i] += v * env * gain

    bars = int(duration / bar) + 1
    for b in range(bars):
        chord = progression[b % len(progression)]
        base = b * bar
        # A pad: the chord held softly for the whole bar.
        for note in chord:
            add(base, bar, freq(note - 12), 0.055, 1.1, harmonics=(1.0, 0.2))
        # Plucks: the chord walked up in eighths.
        for step in range(8):
            note = chord[step % len(chord)] + (12 if step >= 4 else 0)
            add(base + step * bar / 8, bar / 4, freq(note), 0.085, 7.0)
        # A soft pulse on the bar and the half.
        for beat in (0.0, bar / 2):
            add(base + beat, 0.16, 62.0, 0.16, 26.0, harmonics=(1.0,))

    # Fade in and out so it never clicks, and stay well under the voice.
    fade = int(RATE * 1.2)
    peak = max(1e-6, max(abs(v) for v in out))
    scale = 0.5 / peak
    with wave.open(str(path), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        data = bytearray()
        for i, v in enumerate(out):
            g = scale
            if i < fade:
                g *= i / fade
            if i > samples - fade:
                g *= max(0.0, (samples - i) / fade)
            data += struct.pack("<h", max(-32767, min(32767, int(v * g * 32767))))
        f.writeframes(bytes(data))


def speak(text, path, rate):
    aiff = path.with_suffix(".aiff")
    subprocess.run(["say", "-v", "Carmit", "-r", str(rate), "-o", str(aiff), text], check=True)
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(aiff),
         "-ar", str(RATE), "-ac", "1", str(path)],
        check=True,
    )
    aiff.unlink()
    return float(
        subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", str(path)],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    )


def render_voice(spec, lines_dir):
    """One clip per spoken line, each fitted to the room it has before the
    next one starts — the read speeds up rather than the cut being recut."""
    spoken = [(b["at"], b["say"]) for b in spec["beats"] if b["say"]]
    clips = []
    for i, (at, text) in enumerate(spoken):
        nxt = spoken[i + 1][0] if i + 1 < len(spoken) else spec["duration"]
        room = nxt - at - 0.15
        path = lines_dir / f"line_{i}.wav"
        rate = 180
        length = speak(text, path, rate)
        if length > room:
            rate = min(320, int(rate * length / room) + 6)
            length = speak(text, path, rate)
        if length > room:
            print(f"  ! line {i} runs {length - room:.2f}s long even at {rate} wpm")
        clips.append((at, path, length, rate))
    return clips


def mux(video, music, clips, out_path, with_voice):
    inputs = ["-i", str(video), "-i", str(music)]
    filters = ["[1:a]volume=%.2f[bed]" % (0.5 if with_voice else 0.85)]
    mixes = ["[bed]"]
    for i, (at, path, _, _) in enumerate(clips if with_voice else []):
        inputs += ["-i", str(path)]
        filters.append(f"[{i + 2}:a]adelay={int(at * 1000)}|{int(at * 1000)},volume=1.6[v{i}]")
        mixes.append(f"[v{i}]")
    filters.append(
        "".join(mixes) + f"amix=inputs={len(mixes)}:normalize=0:dropout_transition=0,"
        "alimiter=limit=0.95,aresample=44100[a]"
    )
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", *inputs,
         "-filter_complex", ";".join(filters),
         "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
         "-shortest", str(out_path)],
        check=True,
    )


def write_script_text(spec, clips, path):
    locale = spec["locale"]
    lines = [
        f"Easy Plate — TikTok ad, {spec['duration']:.0f}s, {locale}",
        "",
        "TIME   ON SCREEN                     VOICEOVER",
    ]
    spoken = {round(at, 2): (p, d, r) for at, p, d, r in clips}
    for beat in spec["beats"]:
        say = beat["say"] or ""
        clip = spoken.get(round(beat["at"], 2))
        length = f" [{clip[1]:.1f}s @ {clip[2]} wpm]" if clip else ""
        lines.append(
            f"{beat['at']:05.2f}  {' / '.join(beat['text']):28}  {say}{length}"
        )
    lines += [
        "",
        "The voice in the file is macOS's Hebrew speaker, a stand-in for timing.",
        "Record the lines above, or lay TikTok's own voice over the _no_voice cut.",
        "The music is synthesised by make_ad.py and carries no licence.",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    spec = json.loads(SCRIPT.read_text(encoding="utf-8"))
    locale = spec["locale"]
    WORK.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    print("video…")
    silent = WORK / "silent.mp4"
    render_video(spec, locale, silent)

    print("music…")
    music = WORK / "music.wav"
    write_music(music, spec["duration"])

    print("voice…")
    clips = render_voice(spec, WORK)

    print("mixing…")
    mux(silent, music, clips, OUT / f"ad_{locale}_30s.mp4", with_voice=True)
    mux(silent, music, clips, OUT / f"ad_{locale}_30s_no_voice.mp4", with_voice=False)
    write_script_text(spec, clips, OUT / f"ad_{locale}_script.txt")
    shutil.rmtree(WORK, ignore_errors=True)
    print(f"done → {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
