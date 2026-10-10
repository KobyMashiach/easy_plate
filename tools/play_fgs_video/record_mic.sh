#!/bin/bash
# Records the Play Console demo of FOREGROUND_SERVICE_MICROPHONE ("Hey Shefi")
# from a phone over adb. Start it with the app open on Settings > "היי שפי",
# the main switch OFF, "also when the app is closed" ON, the microphone and
# "display over other apps" granted, signed in as a premium account. The Mac
# must be next to the phone: it says the wake words out loud (macOS "say",
# Hebrew voice Carmit).
#
# Output: store_assets/play/fgs_microphone_raw.mp4 + fgs_mic_marks.txt
# ("<second> <phase>" per line, plus "<second> bounds_<phase> y1 y2" for the
# app's own notification card in each shade shot, which compose_mic.py keeps
# sharp while blurring the rest).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/store_assets/play"; mkdir -p "$OUT"
PKG=com.KHEasyDev.easy_plate
CLOCK=com.sec.android.app.clockpackage
TMP="${TMPDIR:-/tmp}/fgs_mic_ui.xml"
MARKS="$OUT/fgs_mic_marks.txt"
SAY_TEXT="${SAY_TEXT:-היי שפי, כמה זמן מבשלים אורז?}"

dump() { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb pull /sdcard/ui.xml "$TMP" >/dev/null 2>&1; }
# "x1 y1 x2 y2" of the first node whose text/content-desc contains $1
find_bounds() {
  dump
  python3 -I - "$TMP" "$1" <<'PY'
import re,sys,html
x=open(sys.argv[1],encoding='utf-8').read(); want=sys.argv[2]
for m in re.finditer(r'<node[^>]*?(?:text|content-desc)="([^"]+)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',x):
    if want in html.unescape(m.group(1)):
        print(*m.group(2,3,4,5)); break
PY
}
center() { read -r x1 y1 x2 y2 <<<"$1"; echo $(((x1+x2)/2)) $(((y1+y2)/2)); }
T0=0
now() { python3 -c 'import time;print(round(time.time(),2))'; }
mark() { echo "$(python3 -c "print(round($(now)-$T0,2))") $*" | tee -a "$MARKS"; }
shade_open()  { adb shell input swipe 540 5 540 1500 400; sleep 1.2; }
shade_close() { adb shell input swipe 540 1500 540 5 300; sleep 0.8; }
# The app's notification card in the open shade: from its title down to the
# Stop action, padded a little.
# Expands Easy Plate's card (the shade shows it collapsed, Stop hidden):
# its chevron sits at the row's end, level with the title.
expand_card() {
  local t; t=$(find_bounds "שפי מקשיב"); [ -n "$t" ] || return 0
  read -r _ ty1 _ ty2 <<<"$t"
  adb shell input tap 975 $(((ty1+ty2)/2+10)); sleep 1.2
}
card_bounds() {
  local t s
  t=$(find_bounds "שפי מקשיב"); s=$(find_bounds "להפסיק")
  [ -n "$t" ] || return 0
  read -r _ ty1 _ _ <<<"$t"
  if [ -n "$s" ]; then read -r _ _ _ sy2 <<<"$s"; else sy2=$((ty1+260)); fi
  echo $((ty1-70)) $((sy2+30))
}

adb get-state >/dev/null 2>&1 || { echo "No phone found."; exit 1; }
# The main switch's label holds quote marks that uiautomator does not
# escape, so the page is recognised by the next card and the switch is
# taken at its place on a 1080x2340 screen (the card's start edge).
[ -n "$(find_bounds 'גם כשהאפליקציה סגורה')" ] || { echo "Open Settings > היי שפי first."; exit 1; }
TOGGLE="${TOGGLE:-193 1278}"

adb shell settings put global sysui_demo_allowed 1 >/dev/null
demo() { adb shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }
demo -e command enter; demo -e command clock -e hhmm 0941
demo -e command battery -e level 100 -e plugged false
demo -e command network -e wifi show -e level 4
demo -e command notifications -e visible false
trap 'demo -e command exit' EXIT

: > "$MARKS"
echo "recording…"
adb shell screenrecord --bit-rate 8000000 --time-limit 120 /sdcard/fgs_mic.mp4 &
REC=$!
sleep 1.5; T0=$(now)
mark settings; sleep 3
adb shell input tap $TOGGLE; echo "   tap switch @ $TOGGLE"; mark enabled; sleep 3.5
shade_open; expand_card; mark shade_service; B=$(card_bounds); [ -n "$B" ] && mark bounds_shade_service $B; sleep 5
shade_close; sleep 0.5
adb shell monkey -p $CLOCK -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; mark left_app; sleep 3
# A word first: the listener restarts between recognition sessions, and
# speech that starts inside that gap loses its first words.
say -v Carmit "בסדר"; mark wake; say -v Carmit -r 150 "$SAY_TEXT"
sleep 4; mark thinking
# The floating panel is not in uiautomator's tree, so the answer is waited
# for by time: Shefi answers within seconds, reads it out, and the panel
# closes six seconds after the voice ends.
sleep 7; mark answer; sleep 15
shade_open; expand_card; mark still_listening; B=$(card_bounds); [ -n "$B" ] && mark bounds_still_listening $B; sleep 4
STOP=$(find_bounds "להפסיק")
if [ -n "$STOP" ]; then adb shell input tap $(center "$STOP"); echo "   tap stop"; fi
mark stopped; sleep 3
shade_close; sleep 0.5
shade_open; mark shade_clear; sleep 4
shade_close; sleep 1
adb shell pkill -INT screenrecord 2>/dev/null || true
wait $REC 2>/dev/null || true
sleep 1
adb pull /sdcard/fgs_mic.mp4 "$OUT/fgs_microphone_raw.mp4" >/dev/null
adb shell rm /sdcard/fgs_mic.mp4
say -v Carmit -r 150 -o "$OUT/fgs_mic_say.aiff" "$SAY_TEXT"
echo "saved $OUT/fgs_microphone_raw.mp4"; cat "$MARKS"
