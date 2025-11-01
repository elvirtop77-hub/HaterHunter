#!/bin/bash
set -e

echo "[*] Building HaterHunter APK..."
./gradlew assembleDebug || { echo "❌ Gradle build failed"; exit 1; }

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at $APK_PATH"
    exit 1
fi

echo "✅ Build successful. Opening APK for installation..."
termux-open "$APK_PATH"

echo "All done. Tap 'Install' in the Android installer."
