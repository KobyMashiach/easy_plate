#!/usr/bin/env python3
"""Turns the raw "Hey Shefi" recording into the Play Console demo for the
FOREGROUND_SERVICE_MICROPHONE declaration.

    python3 tools/play_fgs_video/compose_mic.py

Reads store_assets/play/fgs_microphone_raw.mp4, fgs_mic_marks.txt and
fgs_mic_say.aiff (all written by record_mic.sh) and writes fgs_microphone.mp4:
- blurs every other app's notification in the shade (the recording is made on
  a real phone); Easy Plate's own card, whose bounds record_mic.sh noted,
  stays readable,
- burns an English caption per phase,
- lays the spoken wake words (screenrecord has no audio) at the moment they
  were said.
"""
import os, subprocess, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "store_assets", "play")
RAW = os.path.join(OUT, "fgs_microphone_raw.mp4")
MARKS = os.path.join(OUT, "fgs_mic_marks.txt")
SAY = os.path.join(OUT, "fgs_mic_say.aiff")
DST = os.path.join(OUT, "fgs_microphone.mp4")

CAPTIONS = {
    "settings":        "Easy Plate > Settings > \"Hey Shefi\".\nThe user turns on listening for the wake words.",
    "enabled":         "\"Also when the app is closed\" is on, so a\nforeground service of type microphone starts.",
    "shade_service":   "Its ongoing notification: \"Shefi is listening\",\nwith a Stop action.",
    "left_app":        "The user leaves the app.",
    "wake":            "The user says: \"Hey Shefi, how long\ndo I cook rice?\"",
    "thinking":        "The service heard the wake words: a panel\nopens over the other app and Shefi answers.",
    "answer":          "Shefi's answer is shown and read aloud.\nNo audio is recorded or stored.",
    "still_listening": "Listening again: the notification stays\nfor as long as the service runs.",
    "stopped":         "\"Stop\" in the notification ends\nthe foreground service.",
    "shade_clear":     "The notification and the service are gone.",
}

SHADE_TOP = 280      # first pixel row of the notification list (1080 wide)
SHADE_BOTTOM = 2250  # above the shade's own buttons
SHADE_SECONDS = 5.0  # how long each shade shot stays open


def font():
    for f in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/Library/Fonts/Arial Bold.ttf",
              "/System/Library/Fonts/Helvetica.ttc"]:
        if os.path.exists(f):
            return f
    sys.exit("no font found")


def main():
    if not os.path.exists(RAW) or not os.path.exists(MARKS):
        sys.exit("run record_mic.sh first")
    marks, order, bounds = {}, [], {}
    for line in open(MARKS, encoding="utf-8"):
        parts = line.split()
        if len(parts) == 2:
            marks[parts[1]] = float(parts[0]); order.append(parts[1])
        elif len(parts) == 4 and parts[1].startswith("bounds_"):
            bounds[parts[1][7:]] = (int(parts[2]), int(parts[3]))
    dur = float(subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", RAW]).decode().strip())

    # Blur bands: (start, end, top, bottom) in seconds and pixels.
    bands = []
    for phase in ("shade_service", "still_listening"):
        if phase not in marks:
            continue
        s = marks[phase] - 1.5           # the shade opens just before the mark
        e = marks.get("stopped", s + SHADE_SECONDS + 2) if phase == "still_listening" else s + SHADE_SECONDS + 2.5
        top, bottom = bounds.get(phase, (SHADE_TOP, SHADE_TOP))
        # A sliver above the card holds nothing readable, and a blur needs
        # some height to work with.
        if top - SHADE_TOP > 70:
            bands.append((s, e, SHADE_TOP, top))
        bands.append((s, e, bottom, SHADE_BOTTOM))
    if "stopped" in marks:
        # After Stop the card is gone and the others slide up: all of it.
        bands.append((marks["stopped"], marks.get("shade_clear", dur) - 1.0, SHADE_TOP, SHADE_BOTTOM))
    if "shade_clear" in marks:
        bands.append((marks["shade_clear"] - 1.5, dur, SHADE_TOP, SHADE_BOTTOM))

    fnt = font().replace(":", r"\:")
    chain = ["[0:v]setpts=PTS-STARTPTS,fps=30,scale=1080:-2[base]"]
    chain.append(f"[base]split={len(bands) + 1}" + "".join(f"[s{i}]" for i in range(len(bands) + 1)))
    cur = "s0"
    for i, (a, b, top, bottom) in enumerate(bands, start=1):
        h = max(2, bottom - top)
        chain.append(f"[s{i}]crop=1080:{h}:0:{top},boxblur=32:3[r{i}]")
        chain.append(f"[{cur}][r{i}]overlay=0:{top}:enable='between(t,{a:.2f},{b:.2f})'[o{i}]")
        cur = f"o{i}"

    LH, FS, PAD, BOTTOM = 52, 36, 28, 140
    caps = []
    for i, phase in enumerate(order):
        text = CAPTIONS.get(phase)
        if not text:
            continue
        t0 = marks[phase]
        t1 = marks[order[i + 1]] if i + 1 < len(order) else dur
        lines = text.split("\n")
        on = f"enable='between(t,{t0:.2f},{t1:.2f})'"
        box_h = len(lines) * LH + 2 * PAD
        # Captions sit at the top while Shefi's panel fills the bottom.
        top_of_frame = phase in ("wake", "thinking", "answer")
        y0 = f"{BOTTOM}" if top_of_frame else f"ih-{BOTTOM}-{box_h}"
        caps.append(f"drawbox=x=40:y={y0}:w=iw-80:h={box_h}:color=black@0.72:t=fill:{on}")
        for k, line in enumerate(lines):
            txt = os.path.join(OUT, f".capmic_{phase}_{k}.txt")
            with open(txt, "w", encoding="utf-8") as fh:
                fh.write(line)
            y = f"{BOTTOM}+{PAD}+{k * LH}" if top_of_frame else f"h-{BOTTOM}-{box_h}+{PAD}+{k * LH}"
            caps.append(f"drawtext=fontfile='{fnt}':textfile='{txt}':fontsize={FS}:fontcolor=white:x=(w-text_w)/2:y={y}:{on}")
    chain.append(f"[{cur}]" + ",".join(caps) + "[out]")

    cmd = ["ffmpeg", "-y", "-i", RAW]
    audio = os.path.exists(SAY) and "wake" in marks
    if audio:
        delay = int(marks["wake"] * 1000)
        cmd += ["-i", SAY]
        chain.append(f"[1:a]adelay={delay}|{delay},apad,atrim=0:{dur:.2f}[aud]")
    cmd += ["-filter_complex", ";".join(chain), "-map", "[out]"]
    cmd += ["-map", "[aud]", "-c:a", "aac", "-b:a", "128k"] if audio else ["-an"]
    cmd += ["-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
            "-r", "30", "-movflags", "+faststart", "-t", f"{dur:.2f}", DST]
    subprocess.check_call(cmd)
    for f in glob.glob(os.path.join(OUT, ".capmic_*.txt")):
        os.remove(f)
    print("wrote", DST)


if __name__ == "__main__":
    main()
