#!/data/data/com.termux/files/usr/bin/bash

# Find the latest APK in your HaterHunter folder
latest_apk=$(find ~/HaterHunter -name "*.apk" | xargs ls -t | head -n 1)

# Copy it to Termux Downloads folder
cp "$latest_apk" ~/storage/downloads/

# Output instructions
echo "✅ Latest APK copied to Termux Downloads folder:"
echo "   $(basename "$latest_apk")"

echo
echo "📂 To install:"
echo "1. Open your Files app (or any file manager)."
echo "2. Navigate to Termux > storage > downloads"
echo "3. Tap $(basename "$latest_apk")"
echo "4. Allow 'Install unknown apps' if prompted, then install normally."
