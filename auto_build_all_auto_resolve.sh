#!/bin/bash
# auto_build_all_auto_resolve.sh
# Build both debug + signed release APKs and auto-handle workflow conflicts

WORKFLOW_FILE=".github/workflows/android-build.yml"
BRANCH="main"
DEBUG_APK="app-debug.apk"
RELEASE_APK="app-release.apk"

# --- STEP 0: Checkout branch ---
git checkout $BRANCH

# --- STEP 1: Pull remote changes safely ---
echo "[⏳] Pulling remote changes..."
git fetch origin
git merge --allow-unrelated-histories origin/$BRANCH -X theirs
# Using 'theirs' strategy automatically keeps remote content in conflicts, preventing stop
if [ $? -ne 0 ]; then
    echo "[⚠️] Merge conflicts detected. Using remote versions for workflow file..."
    git checkout --theirs $WORKFLOW_FILE
    git add $WORKFLOW_FILE
    git commit -m "Resolve workflow merge conflict automatically"
fi
echo "[✔] Remote changes integrated."

# --- STEP 2: Write combined workflow ---
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

    - name: Build Debug APK
      run: ./gradlew assembleDebug

    - name: Upload Debug APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug.apk
        path: app/build/outputs/apk/debug/app-debug.apk

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

echo "[✔] Combined workflow written at $WORKFLOW_FILE"

# --- STEP 3: Commit workflow changes ---
git add $WORKFLOW_FILE
git commit -m "Update combined debug + release workflow" || echo "[ℹ️] Nothing to commit"

# --- STEP 4: Push changes ---
git push origin $BRANCH
echo "[✔] Workflow pushed"

# --- STEP 5: Trigger workflow ---
RUN_ID=$(gh workflow run android-build.yml --ref $BRANCH --json databaseId -q ".databaseId")
echo "[✔] Workflow triggered, run ID: $RUN_ID"

# --- STEP 6: Wait for workflow completion ---
echo "[⏳] Waiting for workflow..."
STATUS="in_progress"
while [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; do
    sleep 10
    STATUS=$(gh run view $RUN_ID --json status -q ".status")
    echo "[...] Current status: $STATUS"
done
echo "[✔] Workflow finished: $STATUS"

# --- STEP 7: Download APKs ---
mkdir -p artifacts
gh run download $RUN_ID --name $DEBUG_APK -D artifacts/
gh run download $RUN_ID --name $RELEASE_APK -D artifacts/
echo "[✔] APKs downloaded to artifacts/"

echo "[🎉] Automation complete with auto conflict resolution!"
