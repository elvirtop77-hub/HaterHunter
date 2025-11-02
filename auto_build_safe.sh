#!/data/data/com.termux/files/usr/bin/bash

echo "[🚀] Starting HaterHunter build..."

# Navigate to repo
cd ~/HaterHunter || exit

echo "[🔄] Syncing repository..."
git pull || echo "⚠️ Git pull failed (non-interactive)."

echo "[⚙️] Installing Termux dependencies..."
pkg update -y
pkg upgrade -y
pkg install -y git wget unzip openjdk-17 gradle

echo "[🧹] Cleaning old SDK files..."
rm -rf build
rm -rf APKs/*

echo "[🏗️] Building APK..."
./gradlew assembleRelease || { echo "❌ Build failed!"; exit 1; }

# Copy APK to Termux storage
latest_apk=$(find . -name "*.apk" | xargs ls -t | head -n 1)
if [ -z "$latest_apk" ]; then
    echo "❌ No APK found!"
    exit 1
fi

cp "$latest_apk" ~/storage/downloads/
echo "✅ APK copied to Termux Downloads: $(basename "$latest_apk")"
echo "Open your Files app → Termux → downloads → tap the APK to install."
