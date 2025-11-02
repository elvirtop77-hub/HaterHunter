#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[🔑] Starting SSH agent..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "[🔄] Testing SSH access to GitHub..."
# Treat "successfully authenticated" as a success
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH authenticated"
else
    echo "❌ SSH authentication failed. Check your GitHub SSH key."
    exit 1
fi

# Navigate to project
cd ~/HaterHunter

# Ensure remote URL is SSH
git remote set-url origin git@github.com:elvirtop77/HaterHunter.git

# Try to sync repository
echo "[🔄] Syncing repository..."
if ! git pull --ff-only; then
    echo "⚠️ Git pull failed (non-interactive). Continuing..."
fi

# Install Termux dependencies
echo "[⚙️] Installing Termux dependencies..."
pkg update -y
pkg upgrade -y
pkg install -y git wget unzip openjdk-17 gradle

# Clean old SDK files
echo "[🧹] Cleaning old SDK files..."
rm -rf ~/HaterHunter/build
mkdir -p ~/HaterHunter/build

# Build APK
echo "[🏗️] Building APK..."
gradle assembleRelease || {
    echo "❌ Build failed. Check Gradle logs for errors."
    exit 1
}

# Copy APK to Termux Downloads
latest_apk=$(find ~/HaterHunter -name "*.apk" | xargs ls -t | head -n 1)
cp "$latest_apk" ~/storage/downloads/
echo "✅ Latest APK copied to Termux Downloads: $(basename "$latest_apk")"
echo "📂 Open your Files app → Termux → downloads → tap the APK to install."
