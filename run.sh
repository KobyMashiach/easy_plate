#!/bin/bash
# 📱 Flutter Run & Build Helpers for Sharvit Project
# Organized by Android, iOS, and Tools
# Supports both interactive menu and direct commands (androidRun, iosBuildIpa, etc.)

# === ANDROID FUNCTIONS (01–09) ===
function androidRun() {
  echo "Run  Android"
  flutter run --release
}

function androidBuildApk() {
  echo "Build (Dev) Android"
  flutter build apk  --release
}

function androidBuildAab() {
  echo "Build (Test) Android"
  flutter build appbundle --release
}


function androidClean() {
  echo "Android Clean"
  flutter clean && flutter pub get
}

function androidLogs() {
  echo "Android Logs"
  adb logcat -s flutter
}

# === IOS FUNCTIONS (11–19) ===
function iosRun() {
  echo "Run iOS"
  flutter run --release
}

function iosBuildIpa() {
  echo "Build IPA iOS"
  flutter build ipa --release
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
  (cd android && ./gradlew --stop 2>/dev/null)
  pkill -9 -f gradle 2>/dev/null
  pkill -9 -f java 2>/dev/null
  pkill -9 -f dart 2>/dev/null
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

function createLauncherIcons() {
  echo "Create Launcher Icons"
  dart run flutter_launcher_icons
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
  echo "09. Android Clean"
  echo ""
  echo "🍎 iOS"
  echo "--------------------------------------"
  echo "11. Run"
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
  echo ""
  echo "📜 LOGS"
  echo "--------------------------------------"
  echo "31. Android LOGS"
  echo "32. IOS LOGS"
  echo "======================================"
  read -p "Enter your choice (01–32): " choice

  case $choice in
    1|01) androidRun ;;
    2|02) androidBuildApk ;;
    3|03) androidBuildAab ;;
    9|09) androidClean ;;

    11) iosRun ;;
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

    31) androidLogs ;;
    32) iosLogs ;;

    *) echo "❌ Invalid option. Please select between 01–32." ;;
  esac
}

# === ENTRY POINT ===
if [ "$#" -gt 0 ]; then
  "$@"
else
  menu
fi
