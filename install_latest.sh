#!/data/data/com.termux/files/usr/bin/bash

# Find the latest APK in HaterHunter folder
latest_apk=$(find ~/HaterHunter -name "*.apk" | xargs ls -t | head -n 1)

if [ -z "$latest_apk" ]; then
    echo "❌ No APK found in ~/HaterHunter"
    exit 1
fi

# Copy APK to Downloads
cp "$latest_apk" /sdcard/Download/

echo "✅ Latest APK copied to Downloads:"
echo "   $(basename "$latest_apk")"
echo
echo "📂 Open your Files app and tap the APK to install it manually."
echo "⚠️ Make sure 'Install unknown apps' is allowed for your Files app."
