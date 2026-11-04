#!/bin/bash
# Captures the eight app screens for panorama.py from a phone over adb, into
# store_assets/raw_panorama/<locale>/. The phone's status and navigation bars
# are cut off (their heights are read from the phone), because the composer
# paints an iPhone or an Android bar of its own over every screen.
#
#   tools/store_screenshots/capture_panorama.sh he
#   tools/store_screenshots/capture_panorama.sh en      # app language English
#   tools/store_screenshots/capture_panorama.sh he 05_meal_plan   # one screen
#
# For each screen it says what to open and waits for Enter. Close any
# floating overlay (auto-clicker, chat heads) first: it would be captured.
set -euo pipefail

LOCALE="${1:-he}"
ONLY="${2:-}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/store_assets/raw_panorama/$LOCALE"
mkdir -p "$OUT"

adb get-state >/dev/null 2>&1 || { echo "No phone found. Connect it and allow USB debugging."; exit 1; }

INSETS=$(adb shell dumpsys window)
TOP=$(echo "$INSETS" | sed -n 's/.*type=statusBars frame=\[0,0\]\[[0-9]*,\([0-9]*\)\].*/\1/p' | head -1)
NAV_TOP=$(echo "$INSETS" | sed -n 's/.*type=navigationBars frame=\[0,\([0-9]*\)\].*/\1/p' | head -1)
TOP=${TOP:-110}
echo "Cutting ${TOP}px off the top and everything from y=${NAV_TOP:-bottom} down."

shot() {
  local tmp
  tmp=$(mktemp -t panorama).png
  adb exec-out screencap -p > "$tmp"
  python3 - "$tmp" "$OUT/$1.png" "$TOP" "${NAV_TOP:-0}" <<'EOF'
import sys
from PIL import Image
src, dst, top, nav = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
im = Image.open(src).convert("RGB")
im.crop((0, top, im.width, nav or im.height)).save(dst)
EOF
  rm -f "$tmp"
  echo "   saved $1.png"
}

ask() {
  [ -n "$ONLY" ] && [ "$ONLY" != "$1" ] && return
  echo
  echo "→ $2"
  read -r -p "  Enter when the screen is ready (s to skip): " answer
  [ "$answer" = "s" ] && return
  shot "$1"
}

# Same stems as panorama.json.
ask 01_recipes        "My recipes tab, scrolled so recipe cards with photos fill the screen."
ask 03_ai_import      "Add recipe → link, with a social video link pasted."
ask 02_recipe_details "One recipe with a good photo, the top of its page."
ask 04_library        "The library tab: three or more books with covers."
ask 06_meal_plan      "The meal-plan board with this week filled in."
ask 08_grocery        "The grocery list, part collected, prices showing."
ask 07_nutrition      "The nutrition dashboard (from the plan)."
ask 09_community      "Community → shared recipes, a few cards with likes."
echo
echo "Done. Now: python3 tools/store_screenshots/panorama.py $LOCALE"
