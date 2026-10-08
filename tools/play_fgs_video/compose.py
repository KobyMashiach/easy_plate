#!/usr/bin/env python3
"""Turns the raw cook-mode recording into the Play Console demo for the
FOREGROUND_SERVICE_SPECIAL_USE declaration.

    python3 tools/play_fgs_video/compose.py

Reads store_assets/play/fgs_special_use_raw.mp4 and fgs_marks.txt (written by
record.sh: "<second> <phase>" per line) and writes fgs_special_use.mp4:
- cuts the dead stretch while the script walks to the timer step,
- blurs the other apps' notifications in the shade (the recording is made on
  a real phone; only Easy Plate's own card stays readable),
- burns an English caption per phase.
"""
import os, subprocess, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "store_assets", "play")
RAW = os.path.join(OUT, "fgs_special_use_raw.mp4")
MARKS = os.path.join(OUT, "fgs_marks.txt")
DST = os.path.join(OUT, "fgs_special_use.mp4")

CAPTIONS = {
    "recipe":        "Easy Plate: a recipe page.\nTap \"Start cooking\" to open cook mode.",
    "cook_mode":     "Cook mode: step-by-step cooking.\nSteps with a duration offer a kitchen timer.",
    "timer_step":    "This step has a timer.",
    "timer_started": "Timer started. A foreground service\n(type specialUse, subtype cooking_timer)\nkeeps the timer running.",
    "home":          "The user leaves the app\nwhile the timer runs.",
    "shade":         "The service's ongoing notification shows\nthe running timer, counting down\nwhile the app is in the background.",
    "back_in_app":   "Back in the app: the timer kept running.",
    "finished":      "\"Done cooking\" ends the session\nand stops the foreground service.",
    "shade_clear":   "No running timer: the notification\nand the foreground service are gone.",
}

# Seconds of the shade phases, relative to their mark, in which other apps'
# notifications are on screen, with the top of the blurred band (px at 1080
# wide). Easy Plate's own card is the first one and stays above the band.
SHADE_HOLD, SHADE_CLOSE = 6.9, 1.4
BLUR_BOTTOM = 1750


def font():
    for f in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/Library/Fonts/Arial Bold.ttf",
              "/System/Library/Fonts/Helvetica.ttc"]:
        if os.path.exists(f):
            return f
    sys.exit("no font found")


def main():
    if not os.path.exists(RAW) or not os.path.exists(MARKS):
        sys.exit("run record.sh first")
    marks = {}
    order = []
    for line in open(MARKS, encoding="utf-8"):
        parts = line.split()
        if len(parts) == 2:
            marks[parts[1]] = float(parts[0]); order.append(parts[1])
    dur = float(subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", RAW]).decode().strip())

    # The walk to the timer step is scripted and slow; keep its first and last second.
    cuts = []
    if "cook_mode" in marks and "timer_step" in marks:
        a, b = marks["cook_mode"] + 4.5, marks["timer_step"] - 1.0
        if b > a:
            cuts.append((a, b))

    def remap(t):
        for a, b in cuts:
            if t >= b:
                t -= (b - a)
            elif t > a:
                t = a
        return t

    fnt = font().replace(":", r"\:")
    keep = "*".join(f"not(between(t,{a:.2f},{b:.2f}))" for a, b in cuts) or "1"
    # screenrecord writes a frame only when the screen changes, so the timeline
    # is kept by shifting timestamps after the cut, never by renumbering frames.
    shift = "PTS"
    for a, b in cuts:
        shift = f"if(gte(T\\,{b:.2f})\\,PTS-{b - a:.2f}/TB\\,{shift})"
    chain = [f"[0:v]setpts=PTS-STARTPTS,select='{keep}',setpts='{shift}',scale=1080:-2[base]"]

    # Blur bands: (start, end, top) in raw seconds.
    bands = []
    if "shade" in marks:
        s = marks["shade"]
        bands.append((s, s + SHADE_HOLD, 500))                      # under Easy Plate's card
        bands.append((s + SHADE_HOLD, s + SHADE_HOLD + SHADE_CLOSE, 150))  # cards slide up while closing
    if "shade_clear" in marks:
        s = marks["shade_clear"]
        bands.append((s, s + 3.9, 280))                              # no Easy Plate card: the whole list
        bands.append((s + 3.9, dur, 150))
    n = len(bands)
    chain.append(f"[base]split={n + 1}" + "".join(f"[s{i}]" for i in range(n + 1)))
    cur = "s0"
    for i, (a, b, top) in enumerate(bands, start=1):
        h = BLUR_BOTTOM - top
        chain.append(f"[s{i}]crop=1080:{h}:0:{top},boxblur=30:3[r{i}]")
        chain.append(f"[{cur}][r{i}]overlay=0:{top}:enable='between(t,{remap(a):.2f},{remap(b):.2f})'[o{i}]")
        cur = f"o{i}"

    LH, FS, PAD, BOTTOM = 52, 36, 28, 120
    caps = []
    for i, phase in enumerate(order):
        text = CAPTIONS.get(phase)
        if not text:
            continue
        t0 = remap(marks[phase])
        t1 = remap(marks[order[i + 1]]) if i + 1 < len(order) else remap(dur)
        lines = text.split("\n")
        on = f"enable='between(t,{t0:.2f},{t1:.2f})'"
        box_h = len(lines) * LH + 2 * PAD
        caps.append(f"drawbox=x=40:y=ih-{BOTTOM}-{box_h}:w=iw-80:h={box_h}:color=black@0.72:t=fill:{on}")
        for k, line in enumerate(lines):
            txt = os.path.join(OUT, f".cap_{phase}_{k}.txt")
            with open(txt, "w", encoding="utf-8") as fh:
                fh.write(line)
            y = f"h-{BOTTOM}-{box_h}+{PAD}+{k * LH}"
            caps.append(f"drawtext=fontfile='{fnt}':textfile='{txt}':fontsize={FS}:fontcolor=white:x=(w-text_w)/2:y={y}:{on}")
    chain.append(f"[{cur}]" + ",".join(caps) + "[out]")

    cmd = ["ffmpeg", "-y", "-i", RAW, "-filter_complex", ";".join(chain), "-map", "[out]",
           "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
           "-r", "30", "-movflags", "+faststart", "-an", DST]
    subprocess.check_call(cmd)
    for f in glob.glob(os.path.join(OUT, ".cap_*.txt")):
        os.remove(f)
    print("wrote", DST, "cuts:", cuts)


if __name__ == "__main__":
    main()
