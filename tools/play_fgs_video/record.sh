#!/bin/bash
# Records the Play Console demo of FOREGROUND_SERVICE_SPECIAL_USE (cook-mode
# timer) from a phone over adb. Start it with the app open on a recipe page
# whose "להתחיל לבשל" button is visible, signed in as a premium account.
#
#   tools/play_fgs_video/record.sh            # Hebrew UI labels (default)
#
# Output: store_assets/play/fgs_special_use_raw.mp4 + fgs_marks.txt (the
# second each phase started, for the caption pass in compose.py).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/store_assets/play"; mkdir -p "$OUT"
PKG=com.KHEasyDev.easy_plate
TMP="${TMPDIR:-/tmp}/fgs_ui.xml"

dump() { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb pull /sdcard/ui.xml "$TMP" >/dev/null 2>&1; }
# bounds of the first node whose text/content-desc contains $1 → "cx cy"
find_text() {
  dump
  python3 -I - "$TMP" "$1" <<'PY'
import re,sys,html
x=open(sys.argv[1],encoding='utf-8').read(); want=sys.argv[2]
for m in re.finditer(r'<node[^>]*?(?:text|content-desc)="([^"]+)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if want in html.unescape(m.group(1)):
        x1,y1,x2,y2=map(int,m.group(2,3,4,5)); print((x1+x2)//2,(y1+y2)//2); break
PY
}
tap_text() {  # tap_text <label> [scroll tries]
  local tries="${2:-0}" pos=""
  pos=$(find_text "$1")
  if [ -z "$pos" ]; then
    # Starting screenrecord re-lays the page out and can shift the scroll
    # position: look a little above first, then below.
    adb shell input swipe 540 900 540 1500 300; sleep 0.8; pos=$(find_text "$1")
  fi
  for ((i=0;i<tries;i++)); do
    [ -n "$pos" ] && break
    adb shell input swipe 540 1700 540 900 300; sleep 0.8; pos=$(find_text "$1")
  done
  [ -n "$pos" ] || { echo "!! '$1' not on screen"; return 1; }
  adb shell input tap $pos; echo "   tap '$1' @ $pos"
}
T0=0; mark() { local now; now=$(python3 -c 'import time;print(round(time.time(),2))'); echo "$(python3 -c "print(round($now-$T0,2))") $1" | tee -a "$OUT/fgs_marks.txt"; }

adb get-state >/dev/null 2>&1 || { echo "No phone found."; exit 1; }
[ -n "$(find_text "להתחיל לבשל")" ] || { echo "Open a recipe page with the start-cooking button visible first."; exit 1; }

# Clean status bar for the video.
adb shell settings put global sysui_demo_allowed 1 >/dev/null
demo() { adb shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }
demo -e command enter; demo -e command clock -e hhmm 0941
demo -e command battery -e level 100 -e plugged false
demo -e command network -e wifi show -e level 4
demo -e command notifications -e visible false
trap 'demo -e command exit' EXIT

: > "$OUT/fgs_marks.txt"
echo "recording…"
adb shell screenrecord --bit-rate 8000000 --time-limit 90 /sdcard/fgs.mp4 &
REC=$!
sleep 1.5; T0=$(python3 -c 'import time;print(round(time.time(),2))')
mark recipe
sleep 2.5
tap_text "להתחיל לבשל" 2; mark cook_mode; sleep 3.5
# Walk to the first step that offers a timer (the "next" button never moves,
# so it is located once and then tapped blind).
NEXT=$(find_text "לשלב הבא")
for ((s=0;s<8;s++)); do
  [ -n "$(find_text "להפעיל טיימר")" ] && break
  adb shell input tap $NEXT; sleep 1.1
done
mark timer_step; sleep 1.5
# The timer card is one merged semantics node ("טיימר / 15:00 / להפעיל טיימר"),
# so the label's centre is the progress bar; the button sits ~150 px above the
# card's bottom edge. Verified: a running timer relabels the button "השהיה".
timer_button_pos() {
  dump
  python3 -I - "$TMP" <<'PY'
import re,sys,html
x=open(sys.argv[1],encoding='utf-8').read()
for m in re.finditer(r'<node[^>]*?(?:text|content-desc)="([^"]+)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if "להפעיל טיימר" in html.unescape(m.group(1)):
        x1,y1,x2,y2=map(int,m.group(2,3,4,5))
        print((x1+x2)//2, (y1+y2)//2 if y2-y1<300 else y2-150); break
PY
}
for ((s=0;s<4;s++)); do
  POS=$(timer_button_pos); [ -n "$POS" ] || break
  adb shell input tap $POS; echo "   tap timer @ $POS"; sleep 1.5
  [ -n "$(find_text "השהיה")" ] && break
done
mark timer_started; sleep 4
# Another app instead of the launcher: the home screen carries personal widgets.
adb shell monkey -p com.sec.android.app.clockpackage -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; mark home; sleep 2.5
shade_open()  { adb shell input swipe 540 5 540 1500 400; }   # `cmd statusbar expand-notifications` is flaky on One UI
shade_close() { adb shell input swipe 540 1500 540 5 300; }
shade_open; mark shade; sleep 7
shade_close; sleep 1.5
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; mark back_in_app; sleep 4
tap_text "סיימתי לבשל" >/dev/null 2>&1 && mark finished || true
sleep 3
adb shell input tap 540 1413; sleep 1.5   # "סיום" on the בתיאבון sheet (1080x2340)
adb shell monkey -p com.sec.android.app.clockpackage -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 1.5
shade_open; mark shade_clear; sleep 4
shade_close; sleep 1
pkill -INT -f "screenrecord" 2>/dev/null || true
adb shell pkill -INT screenrecord 2>/dev/null || true
wait $REC 2>/dev/null || true
sleep 1
adb pull /sdcard/fgs.mp4 "$OUT/fgs_special_use_raw.mp4" >/dev/null
adb shell rm /sdcard/fgs.mp4
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "saved $OUT/fgs_special_use_raw.mp4"; cat "$OUT/fgs_marks.txt"
