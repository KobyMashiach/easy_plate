#!/bin/bash
# 📱 Flutter Run & Build Helpers for Sharvit Project
# Organized by Android, iOS, and Tools
# Supports both interactive menu and direct commands (androidRun, iosBuildIpa, etc.)

# Every build reads its ad units, RevenueCat keys and proxy URL from this
# file; a build without it ships blank ad units and no store SDK.
DEFINES="--dart-define-from-file=dart_defines/dev.json"

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
  echo "Upload Dart symbols ($platform) to Crashlytics"
  firebase crashlytics:symbols:upload --app="$app_id" "$SYMBOLS_DIR/$platform" ||
    echo "⚠️  Symbol upload failed; retry: firebase crashlytics:symbols:upload --app=$app_id $SYMBOLS_DIR/$platform"
}

# === ANDROID FUNCTIONS (01–09) ===
function androidRun() {
  echo "Run  Android"
  flutter run --release $DEFINES
}

# Debug build with the dart defines. (While the RevenueCat Test Store key was
# in use this was the only kind it ran in; the store keys run anywhere.)
function androidRunDebug() {
  echo "Run (Debug) Android"
  flutter run $DEFINES
}

function androidBuildApk() {
  echo "Build Android APK"
  flutter build apk --release $DEFINES --split-debug-info=$SYMBOLS_DIR/android &&
    uploadDartSymbols android
}

function androidBuildAab() {
  echo "Build Android App Bundle"
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
  flutter run --release $DEFINES
}

function iosRunDebug() {
  echo "Run (Debug) iOS"
  flutter run $DEFINES
}

function iosBuildIpa() {
  echo "Build IPA iOS"
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

# === INTERACTIVE MENU ===
function menu() {
  echo ""
  echo "🚀 Sharvit Flutter Helper Menu"
  echo "======================================"
  echo "📱 ANDROID"
  echo "--------------------------------------"
  echo "01. Run"
  echo "04. Run (Debug, for Test Store purchases)"
  echo "02. Build APK"
  echo "03. Build App Bundle"
  echo "09. Android Clean"
  echo ""
  echo "🍎 iOS"
  echo "--------------------------------------"
  echo "11. Run"
  echo "14. Run (Debug, for Test Store purchases)"
  echo "12. Build IPA"
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
  echo "🌐 WEBSITE"
  echo "--------------------------------------"
  echo "41. Build website (CSS, 5 languages, sitemap, og images)"
  echo "42. Build + deploy website (firebase hosting)"
  echo ""
  echo "📜 LOGS"
  echo "--------------------------------------"
  echo "31. Android LOGS"
  echo "32. IOS LOGS"
  echo "======================================"
  read -p "Enter your choice (01–42): " choice

  case $choice in
    1|01) androidRun ;;
    2|02) androidBuildApk ;;
    3|03) androidBuildAab ;;
    4|04) androidRunDebug ;;
    9|09) androidClean ;;

    11) iosRun ;;
    14) iosRunDebug ;;
    12) iosBuildIpa ;;
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

    *) echo "❌ Invalid option. Please select between 01–42." ;;
  esac
}

# === ENTRY POINT ===
if [ "$#" -gt 0 ]; then
  "$@"
else
  menu
fi
