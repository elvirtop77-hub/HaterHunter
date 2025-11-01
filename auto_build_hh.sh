#!/data/data/com.termux/files/usr/bin/bash
# auto_build_hh.sh - Termux fully automated HaterHunter build

# ⚠️ Set your keystore info here (for release APK signing)
KEYSTORE_PATH=~/HaterHunter/keystore.jks
KEYSTORE_ALIAS=mykey
KEYSTORE_PASSWORD=your_keystore_password
KEY_PASSWORD=your_key_password

# ⚠️ Set SD card path to copy APKs
SDCARD_PATH=/storage/emulated/0/HaterHunter_APKs

echo "=== Updating Termux packages ==="
pkg update -y && pkg upgrade -y

echo "=== Installing Java & Gradle ==="
pkg install -y openjdk-17 gradle git

echo "=== Navigating to HaterHunter project ==="
cd ~/HaterHunter || { echo "Project folder not found!"; exit 1; }

echo "=== Re-generating Gradle wrapper ==="
gradle wrapper || { echo "Gradle wrapper generation failed!"; exit 1; }

echo "=== Making gradlew executable ==="
chmod +x gradlew

echo "=== Cleaning previous builds ==="
./gradlew clean

echo "=== Building debug APK ==="
./gradlew assembleDebug || { echo "Debug build failed!"; exit 1; }

DEBUG_APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$DEBUG_APK" ]; then
    echo "=== Debug APK built successfully ==="
else
    echo "=== Debug APK not found! Build may have failed ==="
fi

echo "=== Building release APK ==="
if [ -f "$KEYSTORE_PATH" ]; then
    ./gradlew assembleRelease -Pandroid.injected.signing.store.file="$KEYSTORE_PATH" \
                              -Pandroid.injected.signing.store.password="$KEYSTORE_PASSWORD" \
                              -Pandroid.injected.signing.key.alias="$KEYSTORE_ALIAS" \
                              -Pandroid.injected.signing.key.password="$KEY_PASSWORD" || { echo "Release build failed!"; exit 1; }
else
    echo "⚠️ Keystore not found. Building unsigned release APK."
    ./gradlew assembleRelease || { echo "Release build failed!"; exit 1; }
fi

RELEASE_APK="app/build/outputs/apk/release/app-release.apk"
if [ -f "$RELEASE_APK" ]; then
    echo "=== Release APK built successfully ==="
else
    echo "=== Release APK not found! ==="
fi

# Create SD card folder if missing
mkdir -p "$SDCARD_PATH"

# Copy APKs to SD card
[ -f "$DEBUG_APK" ] && cp "$DEBUG_APK" "$SDCARD_PATH/"
[ -f "$RELEASE_APK" ] && cp "$RELEASE_APK" "$SDCARD_PATH/"

echo "=== APKs copied to $SDCARD_PATH ==="
echo "Debug APK: $SDCARD_PATH/$(basename "$DEBUG_APK")"
echo "Release APK: $SDCARD_PATH/$(basename "$RELEASE_APK")"
echo "=== Build and copy process finished! ==="
