#!/bin/bash
# Captures the raw store screenshots from a phone over adb, one screen at a
# time, into store_assets/raw/<locale>/. Run it with the app open and the
# phone's language set to the locale you are capturing:
#
#   tools/store_screenshots/capture.sh he
#   tools/store_screenshots/capture.sh en
#
# For each shot it says which screen to open and waits for Enter. The page
# turn is taken automatically: it drags a page slowly across the open book
# and grabs the screen while the leaf is in the air.
set -euo pipefail

LOCALE="${1:-he}"
OUT="$(cd "$(dirname "$0")/../.." && pwd)/store_assets/raw/$LOCALE"
mkdir -p "$OUT"

adb get-state >/dev/null 2>&1 || { echo "No phone found. Connect it and allow USB debugging."; exit 1; }

# The clock, battery and signal as a store screenshot wants them.
adb shell settings put global sysui_demo_allowed 1 >/dev/null
demo() { adb shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }
demo -e command enter
demo -e command clock -e hhmm 0941
demo -e command battery -e level 100 -e plugged false
demo -e command network -e wifi show -e level 4
demo -e command notifications -e visible false
trap 'demo -e command exit' EXIT

shot() {
  adb exec-out screencap -p > "$OUT/$1.png"
  echo "   saved $1.png"
}

ask() {
  echo
  echo "→ $2"
  read -r -p "  Enter when the screen is ready (s to skip): " answer
  [ "$answer" = "s" ] && return
  shot "$1"
}

ask 01_recipes   "My recipes tab, with a few recipes that have photos."
ask 02_ai_import "The AI import: a link pasted and the extracted recipe on review."

echo
echo "→ Open a recipe book (landscape), on any spread that has a next page."
read -r -p "  Enter to turn the page and capture it mid-air (s to skip): " answer
if [ "$answer" != "s" ]; then
  SIZE=$(adb shell wm size | tail -1 | sed 's/.*: //')
  LONG=$(echo "$SIZE" | tr 'x' '\n' | sort -n | tail -1)
  SHORT=$(echo "$SIZE" | tr 'x' '\n' | sort -n | head -1)
  Y=$((SHORT / 2))
  # Hebrew books turn the other way: the next page comes from the left.
  if [ "$LOCALE" = "he" ] || [ "$LOCALE" = "ar" ]; then
    FROM=$((LONG * 12 / 100)); TO=$((LONG * 60 / 100))
  else
    FROM=$((LONG * 88 / 100)); TO=$((LONG * 40 / 100))
  fi
  adb shell input swipe "$FROM" "$Y" "$TO" "$Y" 2500 &
  sleep 1.4
  shot 03_book_flip
  wait
fi

ask 04_meal_plan "The weekly meal plan, with meals on several days."
ask 05_grocery   "A grocery list with items and the estimated total."
ask 06_community "The community feed of shared recipes."
ask 07_premium   "The premium screen."

echo
echo "Done. Now frame them:  python3 tools/store_screenshots/compose.py $LOCALE"
