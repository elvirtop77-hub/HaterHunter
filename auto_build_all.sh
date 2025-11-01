#!/bin/bash
# auto_build_all.sh - Build both debug and signed release APKs automatically

WORKFLOW_FILE=".github/workflows/build-all-apks.yml"
BRANCH="main"
DEBUG_APK="app-debug.apk"
RELEASE_APK="app-release.apk"

# --- STEP 0: Checkout branch and pull remote changes ---
git checkout $BRANCH
echo "[⏳] Pulling remote changes..."
git pull origin $BRANCH --rebase
if [ $? -ne 0 ]; then
    echo "[⚠️] Pull failed. Resolve conflicts manually."
    exit 1
fi
echo "[✔] Remote changes integrated."

# --- STEP 1: Create workflow ---
mkdir -p .github/workflows
cat > $WORKFLOW_FILE << 'EOF'
name: Build Debug & Release APKs

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup JDK
      uses: gradle/actions/setup-gradle@v5
      with:
        java-version: 17

    # --- Debug APK ---
    - name: Build Debug APK
      run: ./gradlew assembleDebug

    - name: Upload Debug APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug.apk
        path: app/build/outputs/apk/debug/app-debug.apk

    # --- Release APK ---
    - name: Setup keystore
      run: |
        mkdir -p $HOME/.keystore
        cp app/keystore.jks $HOME/.keystore/keystore.jks

    - name: Build Signed Release APK
      env:
        KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
        KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
        KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
      run: |
        ./gradlew assembleRelease \
          -Pandroid.injected.signing.store.file=$HOME/.keystore/keystore.jks \
          -Pandroid.injected.signing.store.password=$KEYSTORE_PASSWORD \
          -Pandroid.injected.signing.key.alias=$KEY_ALIAS \
          -Pandroid.injected.signing.key.password=$KEY_PASSWORD

    - name: Upload Release APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release.apk
        path: app/build/outputs/apk/release/app-release.apk
EOF

echo "[✔] Combined workflow created at $WORKFLOW_FILE"

# --- STEP 2: Commit workflow ---
git add $WORKFLOW_FILE
git commit -m "Add/Update workflow for debug + signed release APKs" || echo "[ℹ️] Nothing to commit"

# --- STEP 3: Push changes ---
git push origin $BRANCH
echo "[✔] Workflow pushed"

# --- STEP 4: Trigger workflow ---
RUN_ID=$(gh workflow run build-all-apks.yml --ref $BRANCH --json databaseId -q ".databaseId")
echo "[✔] Workflow triggered, run ID: $RUN_ID"

# --- STEP 5: Wait for workflow to complete ---
echo "[⏳] Waiting for workflow..."
STATUS="in_progress"
while [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; do
    sleep 10
    STATUS=$(gh run view $RUN_ID --json status -q ".status")
    echo "[...] Current status: $STATUS"
done
echo "[✔] Workflow finished: $STATUS"

# --- STEP 6: Download both APKs ---
mkdir -p artifacts
gh run download $RUN_ID --name $DEBUG_APK -D artifacts/
gh run download $RUN_ID --name $RELEASE_APK -D artifacts/
echo "[✔] APKs downloaded to artifacts/"

echo "[🎉] Debug + Release APK automation complete!"
