#!/bin/bash
# 📱 Flutter Run & Build Helpers for Sharvit Project
# Organized by Android, iOS, and Tools
# Supports both interactive menu and direct commands (androidRun, iosBuildIpa, etc.)

# Every build reads its ad units, RevenueCat keys and proxy URL from this
# file; a build without it ships blank ad units and no store SDK.
# ADMOB_TEST_ADS=false serves the real units in debug runs too (AdsConfig
# would otherwise switch debug to Google's sample units). Register your own
# phones under AdMob → Settings → Test devices so they never click a live ad.
DEFINES="--dart-define-from-file=dart_defines/dev.json --dart-define=ADMOB_TEST_ADS=false"

# Stops a run or build whose dev.json is missing one of the four real ad
# units, or still holds Google's sample ones: AdsConfig silently falls back
# to the sample unit for a blank id, and that build would earn nothing.
function checkAdUnits() {
  local key value missing=0
  for key in ADMOB_NATIVE_AD_UNIT_ANDROID ADMOB_REWARDED_AD_UNIT_ANDROID \
             ADMOB_NATIVE_AD_UNIT_IOS ADMOB_REWARDED_AD_UNIT_IOS; do
    value=$(sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" dart_defines/dev.json 2>/dev/null | head -n 1)
    if [ -z "$value" ] || [[ "$value" == *3940256099942544* ]]; then
      echo "❌ $key in dart_defines/dev.json is empty or a Google test unit."
      missing=1
    fi
  done
  return $missing
}

# Store builds keep the Dart debug info out of the binary (smaller download)
# and write it per platform under build/symbols/. Without uploading those
# files Crashlytics shows Dart stack frames as raw addresses. No --obfuscate:
# class names stay readable in logs and reflection-free code paths.
SYMBOLS_DIR="build/symbols"

# Sends one platform's Dart symbols to Crashlytics. The app id is read from
# the Firebase config files in the repo. Needs `firebase login`; a failed
# upload only warns, the build itself is kept. Manual equivalent:
#   firebase crashlytics:symbols:upload --app=<GOOGLE_APP_ID> build/symbols/<platform>
function uploadDartSymbols() {
  local platform=$1 app_id
  if [ "$platform" = "android" ]; then
    app_id=$(sed -n 's/.*"mobilesdk_app_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' android/app/google-services.json | head -n 1)
  else
    app_id=$(/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null)
  fi
  if [ -z "$app_id" ] || ! command -v firebase >/dev/null; then
    echo "⚠️  Dart symbols not uploaded (no firebase CLI or app id). Run by hand:"
    echo "   firebase crashlytics:symbols:upload --app=<GOOGLE_APP_ID> $SYMBOLS_DIR/$platform"
    return 0
  fi
  if [ "$platform" = "ios" ]; then
    # iOS: Flutter's split-debug-info ELF has no BuildID, so the firebase CLI
    # (dump_syms) cannot process it. Crashlytics symbolicates iOS from the
    # archive's dSYMs instead; App.framework.dSYM carries the Dart frames.
    local dsyms="build/ios/archive/Runner.xcarchive/dSYMs"
    local tool="ios/Pods/FirebaseCrashlytics/upload-symbols"
    echo "Upload dSYMs (ios) to Crashlytics"
    "$tool" -gsp ios/Runner/GoogleService-Info.plist -p ios "$dsyms" ||
      echo "⚠️  dSYM upload failed; retry: $tool -gsp ios/Runner/GoogleService-Info.plist -p ios $dsyms"
    return 0
  fi
  echo "Upload Dart symbols ($platform) to Crashlytics"
  firebase crashlytics:symbols:upload --app="$app_id" "$SYMBOLS_DIR/$platform" ||
    echo "⚠️  Symbol upload failed; retry: firebase crashlytics:symbols:upload --app=$app_id $SYMBOLS_DIR/$platform"
}

# === ANDROID FUNCTIONS (01–09) ===
function androidRun() {
  echo "Run  Android"
  checkAdUnits || return 1
  flutter run --release $DEFINES
}

# Debug build with the dart defines. (While the RevenueCat Test Store key was
# in use this was the only kind it ran in; the store keys run anywhere.)
function androidRunDebug() {
  echo "Run (Debug) Android"
  checkAdUnits || return 1
  flutter run $DEFINES
}

function androidBuildApk() {
  echo "Build Android APK"
  checkAdUnits || return 1
  flutter build apk --release $DEFINES --split-debug-info=$SYMBOLS_DIR/android &&
    uploadDartSymbols android
}

function androidBuildAab() {
  echo "Build Android App Bundle"
  checkAdUnits || return 1
  flutter build appbundle --release $DEFINES --split-debug-info=$SYMBOLS_DIR/android &&
    uploadDartSymbols android
}


function androidClean() {
  echo "Android Clean"
  flutter clean && flutter pub get
}

# Wipes every Firestore collection of the active Firebase project. There is
# no undo, so the project id (from .firebaserc, else "easy-plate") is shown
# and must be typed back exactly before anything is sent; the CLI's own y/N
# prompt still follows.
function deleteAllFirebaseData() {
  local project
  project=$(sed -n 's/.*"default"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .firebaserc 2>/dev/null | head -n 1)
  project=${project:-easy-plate}
  echo "Delete all Firestore data in Firebase project: $project"
  echo "This removes every collection and document and cannot be undone."
  read -r -p "Type the project id ($project) to confirm: " typed
  if [ "$typed" != "$project" ]; then
    echo "❌ '$typed' does not match '$project'. Nothing deleted."
    return 1
  fi
  firebase firestore:delete --all-collections --project "$project"
}

function androidLogs() {
  echo "Android Logs"
  adb logcat -s flutter
}

# === IOS FUNCTIONS (11–19) ===
function iosRun() {
  echo "Run iOS"
  checkAdUnits || return 1
  flutter run --release $DEFINES
}

function iosRunDebug() {
  echo "Run (Debug) iOS"
  checkAdUnits || return 1
  flutter run $DEFINES
}

function iosBuildIpa() {
  echo "Build IPA iOS"
  checkAdUnits || return 1
  flutter build ipa --release $DEFINES --split-debug-info=$SYMBOLS_DIR/ios &&
    uploadDartSymbols ios
}

function openBuilderIos() {
  echo "Open iOS Runner in Xcode"
  open build/ios/archive/Runner.xcarchive/
}

function iosLogs() {
  echo "iOS Logs"
  idevicesyslog | grep "Runner" | grep "<Notice>: flutter:"
}

function cleanAndBuildIos() { echo "Clean & Build iOS"
  flutter clean && flutter pub get && cd ios && \
  rm -rf Pods Podfile.lock && \
  pod repo update && pod install && cd ..
}

# === TOOLS FUNCTIONS (21–29) ===
function runSlang() {
  echo "Run Slang"
  dart run slang
}

function buildRunner() {
  echo "Build Runner"
  dart run build_runner build --delete-conflicting-outputs
  runSlang
}

function cleanAll() {
  echo "Clean All"
  flutter clean && flutter pub get
  echo "✅ Flutter project cleaned and dependencies restored."
}

function versionInfo() {
  echo "Flutter Version Info"
  flutter --version
}

function doctorCheck() {
  echo "Flutter Doctor"
  flutter doctor
}

function clearGradleCache() {
  echo "Clear Gradle Cache (full)"
  # Only Gradle's own daemons: a blanket pkill of java/dart took down every
  # IDE, analysis server and unrelated JVM on the machine.
  (cd android && ./gradlew --stop 2>/dev/null)
  flutter clean
  rm -rf android/.gradle
  rm -rf android/build
  rm -rf build
  rm -rf .dart_tool
  rm -rf ~/.gradle/caches
  rm -rf ~/.gradle/daemon
  rm -rf ~/.gradle/native
  rm -rf ~/.gradle/wrapper
  flutter pub get
  echo "✅ Gradle cache fully cleared. Next build will re-download Gradle and dependencies."
}

function storeScreenshots() {
  echo "Render the App Store review screenshots into store_assets/app_store"
  flutter test test/store_assets --dart-define=STORE_SCREENSHOTS=true
}

function createLauncherIcons() {
  echo "Create Launcher Icons"
  dart run flutter_launcher_icons
}

# === WEBSITE (landing/) ===
# Rebuilds everything the site derives from index.html: the compiled Tailwind
# CSS, the five language pages (/, /he/, /ar/, /fr/, /ru/) with their SEO head
# and translated text, sitemap.xml, robots.txt and the og/<lang>.png share
# images. Edit copy only inside I18N in landing/index.html, then run this.
function buildWebsite() {
  echo "Build web app (webapp/ → landing/app, served at /app)"
  (cd webapp && ([ -d node_modules ] || npm install --no-audit --no-fund) && npm run build) || return 1
  echo "Build website (CSS + 5 language pages + sitemap + og images)"
  (cd landing && [ -d node_modules ] || npm install --no-audit --no-fund) &&   (cd landing && npm run build)
}

# Build, then publish to Firebase Hosting (only hosting: functions, rules and
# Remote Config are untouched). Refreshes the live site at easyplate.app.
function deployWebsite() {
  buildWebsite || { echo "❌ Website build failed, nothing deployed."; return 1; }
  echo "Deploy website to Firebase Hosting"
  firebase deploy --only hosting
}

# === STORE BUILDS ===
# Both store builds in one go: the Android App Bundle (03), then the iOS
# IPA (12), then the archive opens in Xcode (17) for the upload. Stops at
# the first build that fails.
function buildForStores() {
  echo "Build for stores (Android AAB + iOS IPA)"
  androidBuildAab && iosBuildIpa && openBuilderIos
}

# === AUTONOMOUS QA LOOP ===
# Opens Claude Code in this terminal (a normal, visible session) with a
# parallel test → fix → retest loop: three agents for performance,
# UI/functional bugs and security. Asks how many minutes to run (180 = 3
# hours); the session is killed at that deadline whatever it is doing.
# Hourly reports and a Hebrew final summary go to docs/review/qa-loop/.
# The duration can also be passed directly: ./run.sh qaLoop 60
function qaLoop() {
  local minutes=$1
  if [ -z "$minutes" ]; then
    read -r -p "How many minutes should the QA loop run? [180]: " minutes
    minutes=${minutes:-180}
  fi
  if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [ "$minutes" -eq 0 ]; then
    echo "❌ '$minutes' is not a number of minutes."
    return 1
  fi
  local stamp deadline
  stamp=$(date +%Y%m%d-%H%M%S)
  deadline=$(date -v+"${minutes}"M "+%Y-%m-%d %H:%M")
  mkdir -p docs/review/qa-loop

  local prompt
  prompt=$(cat <<EOF
# Autonomous Multi-Agent Parallel QA & Remediation Loop

Started at $(date "+%Y-%m-%d %H:%M"). Hard deadline: $deadline (${minutes} minutes).
Check the clock with \`date\` between cycles and stop starting new work when the deadline is near.

## Objective
Execute a continuous, multi-threaded testing and remediation loop until the deadline. Deploy multiple autonomous worker agents running in parallel to simultaneously test, audit, and fix different layers of the application to maximize throughput and code coverage.

## Agent Team Structure & Division of Labor

### 1. Performance & Load Agent
* Focus: Speed, API latency, database query efficiency, memory leaks, and concurrency bottlenecks.
* Action: Continuously run load tests, stress tests, and profiling. Identify slow queries or resource spikes and immediately optimize the code.

### 2. UI/UX & Functional Bug Hunter Agent
* Focus: Client-side errors, console exceptions, broken layouts, responsive design flaws, edge-case user flows, and state management issues.
* Action: Systematically test user interactions, form submissions, and navigation paths. Immediately patch frontend and component logic upon failure.

### 3. Security & Reliability Agent
* Focus: Input validation, authentication/authorization gaps, unhandled exceptions, and API error-handling robustness.
* Action: Run security checks and failure-injection testing, then immediately harden the codebase against vulnerabilities.

## Core Loop Protocol (For Every Agent)
1. Test: Run domain-specific diagnostic tests.
2. Fix: Write clean, production-ready code to resolve any discovered issues without temporary patches.
3. Verify: Re-run tests to confirm the fix works and creates no regressions.
4. Loop: Restart the cycle until the deadline.

## This repo
* Flutter app (lib/, test/): \`flutter analyze\`, \`flutter test\`.
* Cloud Functions (functions/): \`npm test\` inside functions/.
* Web app (webapp/) and site (landing/): \`npm run build\` in each.
* Firestore rules: firestore.rules.
* Follow CLAUDE.md and the project memory (AppDialog, feature flags, i18n in all five languages).

## Guard rails (unattended run)
* No git commit, push, reset or checkout; leave every change in the working tree for review.
* No firebase deploy, no Remote Config publish, no writes to production data, no store uploads.
* Agents work on separate files/modules to avoid conflicts.

## Synchronization & Logging
* At the end of each hour, write a consolidated progress report to docs/review/qa-loop/$stamp-hour-<n>.md summarizing fixes applied across all parallel streams.
* At the end, write docs/review/qa-loop/$stamp-final.md with all fixes, tests run, and open items — in Hebrew.
EOF
)

  echo "QA loop: ${minutes} minutes, hard stop at $deadline"
  # Hard stop: at the deadline, kill the Claude session started below (the
  # only other child of this shell).
  ( sleep $((minutes * 60)); echo; echo "⏰ $minutes minutes are up, stopping Claude."
    pkill -TERM -P $$ ) &
  local watchdog=$!
  claude "$prompt" --permission-mode auto
  kill "$watchdog" 2>/dev/null
  echo "QA loop finished at $(date "+%H:%M"). Reports: docs/review/qa-loop/"
}

# === INTERACTIVE MENU ===
function menu() {
  echo ""
  echo "🚀 Sharvit Flutter Helper Menu"
  echo "======================================"
  echo "📱 ANDROID"
  echo "--------------------------------------"
  echo "01. Run"
  echo "02. Build APK"
  echo "03. Build App Bundle"
  echo "04. Run (Debug, real ads)"
  echo "09. Android Clean"
  echo ""
  echo "🍎 iOS"
  echo "--------------------------------------"
  echo "11. Run"
  echo "12. Build IPA"
  echo "14. Run (Debug, real ads)"
  echo "17. Open iOS Runner in Xcode"
  echo "19. Clean & Build iOS"
  echo ""
  echo "🧰 TOOLS"
  echo "--------------------------------------"
  echo "21. Run Slang"
  echo "22. Build Runner"
  echo "23. Clean All"
  echo "24. Flutter Version Info"
  echo "25. Flutter Doctor"
  echo "26. Clear Gradle Cache"
  echo "27. Create Launcher Icons"
  echo "28. Store Screenshots (paywall review image)"
  echo "29. Delete all Firebase data"
  echo ""
  echo "📜 LOGS"
  echo "--------------------------------------"
  echo "31. Android LOGS"
  echo "32. IOS LOGS"
  echo ""
  echo "🌐 WEBSITE"
  echo "--------------------------------------"
  echo "41. Build website (CSS, 5 languages, sitemap, og images)"
  echo "42. Build + deploy website (firebase hosting)"
  echo ""
  echo "🤖 BUILDS & QA"
  echo "--------------------------------------"
  echo "51. Autonomous QA loop (Claude, asks for minutes)"
  echo "59. Build for stores (03 → 12 → 17)"
  echo "======================================"
  read -p "Enter your choice (01–59): " choice

  case $choice in
    1|01) androidRun ;;
    2|02) androidBuildApk ;;
    3|03) androidBuildAab ;;
    4|04) androidRunDebug ;;
    9|09) androidClean ;;

    11) iosRun ;;
    12) iosBuildIpa ;;
    14) iosRunDebug ;;
    17) openBuilderIos ;;
    19) cleanAndBuildIos ;;

    21) runSlang ;;
    22) buildRunner ;;
    23) cleanAll ;;
    24) versionInfo ;;
    25) doctorCheck ;;
    26) clearGradleCache ;;
    27) createLauncherIcons ;;
    28) storeScreenshots ;;
    29) deleteAllFirebaseData ;;

    31) androidLogs ;;
    32) iosLogs ;;

    41) buildWebsite ;;
    42) deployWebsite ;;

    51) qaLoop ;;
    59) buildForStores ;;

    *) echo "❌ Invalid option. Please select between 01–51." ;;
  esac
}

# === ENTRY POINT ===
if [ "$#" -gt 0 ]; then
  "$@"
else
  menu
fi
