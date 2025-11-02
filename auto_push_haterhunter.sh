#!/data/data/com.termux/files/usr/bin/bash
# auto_push_haterhunter.sh

# Step 0: Ensure GitHub CLI installed
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    pkg install gh -y
fi

# Step 1: Authenticate GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "Authenticate GitHub CLI (follow the instructions)..."
    gh auth login
fi

# Step 2: Check if repo exists
REPO="HaterHunter"
OWNER="elvirtop77"

echo "Checking if repository $OWNER/$REPO exists..."
if ! gh repo view "$OWNER/$REPO" &> /dev/null; then
    echo "Repository not found. Creating $OWNER/$REPO..."
    gh repo create "$OWNER/$REPO" --private --confirm
else
    echo "Repository exists."
fi

# Step 3: Set remote URL (SSH)
cd ~/HaterHunter || { echo "Folder ~/HaterHunter not found"; exit 1; }
git remote set-url origin "git@github.com:$OWNER/$REPO.git"

# Step 4: Push local code
git add .
git commit -m "Sync local code"
echo "Pushing to GitHub..."
git push -u origin main

echo "✅ Local code is now synced with GitHub."
