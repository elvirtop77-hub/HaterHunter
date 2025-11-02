0#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Fully automated build + copy APK to Termux Downloads
# Works with SSH remote URLs

# Start SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "[🔄] Syncing HaterHunter repository..."
cd ~/HaterHunter || exit 1

# Make sure repo uses SSH
git remote set-url origin git@github.com:elvirtop77/HaterHunter.git

# Pull latest changes
if ! git pull origin main; then
    echo "⚠️ Git pull failed (non-interactive). Continuing..."
fi

# Install dependencies
echo "[⚙️] Installing Termux dependencies..."
pkg update -y
pkg install -y git wget unzip openjdk-17 gradle

# Clean old SDK files
echo "[🧹] Cleaning old SDK files..."
rm -rf ~/HaterHunter/build
mkdir -p ~/HaterHunter/build

# Run Gradle build (adjust if your project uses a different gradle task)
echo "[🏗️] Building APK..."
cd ~/HaterHunter || exit 1
gradle assembleRelease

# Copy latest APK to Termux Downloads
latest_apk=$(find ~/HaterHunter -name "*.apk" | xargs ls -t | head -n 1)
cp "$latest_apk" ~/storage/downloads/

echo "✅ Latest APK copied to Termux Downloads:"
echo "   $(basename "$latest_apk")"
echo "📂 Open your Files app → Termux → downloads → tap the APK to install."
