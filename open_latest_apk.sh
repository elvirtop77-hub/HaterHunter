#!/data/data/com.termux/files/usr/bin/bash

# Latest APK in shared Downloads
latest_apk=$(find ~/storage/downloads -name "*.apk" | xargs ls -t | head -n 1)

if [ -z "$latest_apk" ]; then
    echo "❌ No APK found in ~/storage/downloads"
    exit 1
fi

echo "✅ Latest APK: $(basename "$latest_apk")"

# Use content URI for newer Android versions
am start -a android.intent.action.VIEW \
    -d "content://com.android.externalstorage.documents/document/primary:Download/$(basename "$latest_apk")" \
    -t "application/vnd.android.package-archive" \
    --user 0

echo "📂 Installer opened. Tap 'Install' to proceed."
