#!/data/data/com.termux/files/usr/bin/bash
# auto_build_and_install_handsfree.sh

set -e

echo "[🚀] Starting fully automated Termux build (hands-free)..."

# Start SSH agent if needed
eval "$(ssh-agent -s)" >/dev/null
ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1 || true

# Sync repository (non-interactive)
cd ~/HaterHunter
echo "[🔄] Syncing repository..."
GIT_TERMINAL_PROMPT=0 git pull origin main || echo "⚠️ Warning: git pull failed (non-interactive)."

# Install Termux dependencies silently
echo "[⚙️] Installing Termux dependencies..."
pkg update -y >/dev/null
pkg install -y git wget unzip openjdk-21 >/dev/null

# Clean old SDK/build files
echo "[🧹] Cleaning old SDK files..."
rm -rf ~/HaterHunter/APKs/*

# Run HaterHunter build
echo "[🏗️] Running HaterHunter build..."
bash ~/HaterHunter/auto_build_all_final.sh >/dev/null 2>&1
echo "✅ Build completed!"

# Find latest APK
latest_apk=$(find ~/HaterHunter -name "*.apk" | xargs ls -t | head -n 1)

if [[ -f "$latest_apk" ]]; then
    # Copy to Termux Downloads
    cp "$latest_apk" ~/storage/downloads/
    apk_path="$HOME/storage/downloads/$(basename "$latest_apk")"

    echo "[📂] Latest APK copied to Termux Downloads:"
    echo "   $apk_path"

    # Launch installer
    am start -a android.intent.action.VIEW \
             -d "file://$apk_path" \
             -t "application/vnd.android.package-archive" \
             --user 0 >/dev/null 2>&1 || echo "⚠️ Installer could not be opened automatically."

    echo "✅ Installer opened for $(basename "$latest_apk")."
else
    echo "❌ No APK found in ~/HaterHunter."
fi
