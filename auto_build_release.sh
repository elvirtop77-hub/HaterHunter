#!/bin/bash
# auto_build_release.sh - Fully automate signed release APK build

WORKFLOW_FILE=".github/workflows/build-release-apk.yml"
BRANCH="main"
APK_NAME="app-release.apk"

# --- STEP 1: Create workflow ---
mkdir -p .github/workflows
cat > $WORKFLOW_FILE << 'EOF'
name: Build & Sign APK

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

    - name: Setup keystore
      run: |
        mkdir -p $HOME/.keystore
        cp app/keystore.jks $HOME/.keystore/keystore.jks

    - name: Build release APK
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

    - name: Upload signed APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release.apk
        path: app/build/outputs/apk/release/app-release.apk
EOF

echo "[✔] Signed workflow created at $WORKFLOW_FILE"

# --- STEP 2: Commit & push workflow ---
git add $WORKFLOW_FILE
git commit -m "Add/Update signed release APK workflow"
git push origin $BRANCH
echo "[✔] Workflow pushed"

# --- STEP 3: Trigger workflow ---
RUN_ID=$(gh workflow run build-release-apk.yml --ref $BRANCH --json databaseId -q ".databaseId")
echo "[✔] Workflow triggered, run ID: $RUN_ID"

# --- STEP 4: Wait for workflow to complete ---
echo "[⏳] Waiting for workflow..."
STATUS="in_progress"
while [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; do
    sleep 10
    STATUS=$(gh run view $RUN_ID --json status -q ".status")
    echo "[...] Current status: $STATUS"
done
echo "[✔] Workflow finished: $STATUS"

# --- STEP 5: Download signed APK ---
mkdir -p artifacts
gh run download $RUN_ID --name $APK_NAME -D artifacts/
echo "[✔] APK downloaded to artifacts/$APK_NAME"
echo "[🎉] Signed release APK automation complete!"
