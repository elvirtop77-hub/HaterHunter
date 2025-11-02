#!/data/data/com.termux/files/usr/bin/bash
# Fully automated HaterHunter build + open APK in Files app

echo "[🚀] Starting fully automated Termux build..."

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo "[🔑] SSH agent started and key added."

# Ensure repository exists locally
REPO_DIR="$HOME/HaterHunter"
REPO_SSH="git@github.com:elvirtop77/HaterHunter.git"

if [ -d "$REPO_DIR/.git" ]; then
    echo "[🔄] Updating existing HaterHunter repository..."
    cd "$REPO_DIR"
    git remote set-url origin "$REPO_SSH"
    git fetch --all
    git reset --hard origin/main
else
    echo "[🔄] Cloning HaterHunter repository..."
    git clone "$REPO_SSH" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Install Termux dependencies
echo "[⚙️] Installing Termux dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y git wget unzip openjdk-17 nodejs python

# Clean old SDK files
echo "[🧹] Cleaning old SDK files..."
rm -rf "$REPO_DIR"/APKs/*

# Run build
echo "[🏗️] Running HaterHunter build..."
bash "$REPO_DIR/auto_build_all_final.sh"

# Copy latest APK to Termux Downloads
latest_apk=$(find "$REPO_DIR" -name "*.apk" | xargs ls -t | head -n 1)
cp "$latest_apk" ~/storage/downloads/
apk_name=$(basename "$latest_apk")
echo "✅ Latest APK copied to Termux Downloads folder: $apk_name"

# Open the APK using default file manager (Files app)
echo "[📂] Opening APK in Files app..."
am start \
-a android.intent.action.VIEW \
-d "file://$HOME/storage/downloads/$apk_name" \
-t "application/vnd.android.package-archive"

echo "⚠️ Tap the APK in the Files app to install. No 'Display over other apps' required."
